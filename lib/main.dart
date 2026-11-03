
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DeadlineHunterApp());
}

// MODEL TUGAS
class Task {
  String id;
  String title;
  String course;
  DateTime deadline;
  String priority;
  bool isDone;

  Task({
    required this.id,
    required this.title,
    required this.course,
    required this.deadline,
    required this.priority,
    this.isDone = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'course': course,
    'deadline': deadline.toIso8601String(),
    'priority': priority,
    'isDone': isDone,
  };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      course: json['course'],
      deadline: DateTime.parse(json['deadline']),
      priority: json['priority'],
      isDone: json['isDone'] ?? false,
    );
  }
}

// WARNA APLIKASI
const Color purple = Color(0xFF7655E8);
const Color darkBackground = Color(0xFFF6F4FC);

class DeadlineHunterApp extends StatelessWidget {
  const DeadlineHunterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Deadline Hunter',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: darkBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: purple,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: darkBackground,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// HALAMAN UTAMA
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> tasks = [];
  int selectedIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  // MEMUAT DATA
  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('tasks');

    if (data != null) {
      final List decoded = jsonDecode(data);
      tasks = decoded.map((e) => Task.fromJson(e)).toList();
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  // MENYIMPAN DATA
  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'tasks',
      jsonEncode(tasks.map((e) => e.toJson()).toList()),
    );
  }

  int get completedCount =>
      tasks.where((task) => task.isDone).length;

  int get points => completedCount * 10;

  double get progress {
    if (tasks.isEmpty) return 0;
    return completedCount / tasks.length;
  }

  int get remainingCount => tasks.length - completedCount;

  // KATEGORI DEADLINE
  String category(Task task) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadline = DateTime(
      task.deadline.year,
      task.deadline.month,
      task.deadline.day,
    );

    final difference = deadline.difference(today).inDays;

    if (difference < 0) return 'Terlambat';
    if (difference <= 2) return 'Mendesak';
    if (difference <= 7) return 'Mulai Dikejar';
    return 'Aman';
  }

  Color categoryColor(String value) {
    switch (value) {
      case 'Aman':
        return Colors.green;
      case 'Mulai Dikejar':
        return Colors.orange;
      case 'Mendesak':
      case 'Terlambat':
        return Colors.red;
      default:
        return purple;
    }
  }

  // TAMBAH TUGAS
  Future<void> addTask() async {
    final result = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => const AddTaskSheet(),
    );

    if (result != null) {
      setState(() => tasks.add(result));
      await saveTasks();
    }
  }

  // SELESAIKAN TUGAS
  Future<void> toggleTask(Task task) async {
    setState(() {
      task.isDone = !task.isDone;
    });

    await saveTasks();
  }

  // HAPUS TUGAS
  Future<void> deleteTask(Task task) async {
    setState(() => tasks.removeWhere((e) => e.id == task.id));
    await saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      dashboardPage(),
      missionPage(),
      achievementPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.bolt, color: purple, size: 30),
            SizedBox(width: 8),
            Text(
              'Deadline Hunter',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: purple,
              ),
            ),
          ],
        ),
      ),
      body: pages[selectedIndex],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addTask,
        backgroundColor: purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Misi'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Misi',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Pencapaian',
          ),
        ],
      ),
    );
  }

  // DASHBOARD
  Widget dashboardPage() {
    final activeTasks = tasks.where((e) => !e.isDone).toList();

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7655E8), Color(0xFF9A70F5)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SELAMAT DATANG, PEMBURU DEADLINE!',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Selesaikan misimu\nhari ini!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '$points POIN',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.white30,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toInt()}% misi terselesaikan',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            statCard('Total Misi', '${tasks.length}',
                Icons.assignment, Colors.blue),
            const SizedBox(width: 10),
            statCard('Selesai', '$completedCount',
                Icons.check_circle, Colors.green),
            const SizedBox(width: 10),
            statCard('Belum', '$remainingCount',
                Icons.hourglass_bottom, Colors.orange),
          ],
        ),

        const SizedBox(height: 25),
        const Text(
          'Misi Terdekat',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        if (activeTasks.isEmpty)
          emptyMessage('Belum ada misi. Yuk, tambahkan tugas!'),

        ...activeTasks.take(5).map((task) => taskCard(task)),
      ],
    );
  }

  Widget statCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // HALAMAN MISI
  Widget missionPage() {
    final groups = ['Mendesak', 'Mulai Dikejar', 'Aman', 'Terlambat'];

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'Daftar Misi',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Atur dan selesaikan semua tugas kuliahmu.'),
        const SizedBox(height: 20),

        ...groups.map((group) {
          final groupTasks = tasks
              .where((e) => !e.isDone && category(e) == group)
              .toList();

          if (groupTasks.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$group (${groupTasks.length})',
                style: TextStyle(
                  color: categoryColor(group),
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 10),
              ...groupTasks.map((task) => taskCard(task)),
              const SizedBox(height: 15),
            ],
          );
        }),

        const Text(
          'Tugas Selesai',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 10),

        ...tasks.where((e) => e.isDone).map((task) => taskCard(task)),
      ],
    );
  }

  // HALAMAN PENCAPAIAN
  Widget achievementPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.emoji_events, size: 95, color: Colors.amber),
        const Center(
          child: Text(
            'Pencapaian Saya',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 25),
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: purple,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              const Text(
                'TOTAL POIN',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                '$points',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Poin yang berhasil kamu kumpulkan',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        achievementCard(
          Icons.check_circle,
          'Penyelesai Misi',
          '$completedCount tugas selesai',
        ),
        achievementCard(
          Icons.stars,
          'Pemburu Poin',
          '$points poin terkumpul',
        ),
        achievementCard(
          Icons.military_tech,
          'Pejuang Akademik',
          'Terus selesaikan tugas kuliahmu!',
        ),
      ],
    );
  }

  Widget achievementCard(IconData icon, String title, String subtitle) {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: Colors.amber, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }

  // KARTU TUGAS
  Widget taskCard(Task task) {
    final group = category(task);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Checkbox(
              value: task.isDone,
              activeColor: purple,
              onChanged: (_) => toggleTask(task),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: task.isDone
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  Text(
                    task.course,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Deadline: ${task.deadline.day}/${task.deadline.month}/${task.deadline.year}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    children: [
                      Chip(
                        label: Text(group),
                        backgroundColor: categoryColor(group).withValues(alpha: 0.12),
                        labelStyle: TextStyle(
                          color: categoryColor(group),
                          fontSize: 10,
                        ),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide.none,
                      ),
                      Chip(
                        label: Text(task.priority),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => deleteTask(task),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget emptyMessage(String message) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Center(
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

// FORM TAMBAH TUGAS
class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final titleController = TextEditingController();
  final courseController = TextEditingController();

  DateTime? deadline;
  String priority = 'Sedang';

  @override
  void dispose() {
    titleController.dispose();
    courseController.dispose();
    super.dispose();
  }

  Future<void> selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (selected != null) {
      setState(() => deadline = selected);
    }
  }

  void saveTask() {
    if (titleController.text.trim().isEmpty ||
        courseController.text.trim().isEmpty ||
        deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi nama tugas, mata kuliah, dan deadline!'),
        ),
      );
      return;
    }

    final task = Task(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      course: courseController.text.trim(),
      deadline: deadline!,
      priority: priority,
    );

    Navigator.pop(context, task);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 25,
        bottom: MediaQuery.of(context).viewInsets.bottom + 25,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tambah Misi Baru',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Nama Tugas',
                hintText: 'Contoh: Membuat laporan praktikum',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.assignment),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: courseController,
              decoration: const InputDecoration(
                labelText: 'Mata Kuliah',
                hintText: 'Contoh: Pemrograman Mobile',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
            ),
            const SizedBox(height: 15),

            const Text(
              'Prioritas Tugas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: priority,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: ['Rendah', 'Sedang', 'Tinggi'].map((value) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => priority = value);
                }
              },
            ),
            const SizedBox(height: 15),

            OutlinedButton.icon(
              onPressed: selectDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                deadline == null
                    ? 'Pilih Tanggal Deadline'
                    : 'Deadline: ${deadline!.day}/${deadline!.month}/${deadline!.year}',
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: saveTask,
                icon: const Icon(Icons.save),
                label: const Text('Simpan Tugas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
