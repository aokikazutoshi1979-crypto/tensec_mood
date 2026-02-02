import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/weekly_review_screen.dart';
import 'services/mood_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Hiveは軽量で導入が簡単、コード生成なしでMVPに適しているため採用。
  await Hive.initFlutter();

  final box = await Hive.openBox<Map>('mood_entries');
  final repository = MoodRepository(box);
  await repository.loadEntries();

  runApp(TensecMoodApp(repository: repository));
}

class TensecMoodApp extends StatelessWidget {
  const TensecMoodApp({super.key, required this.repository});

  final MoodRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TenSec Mood',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: AppShell(repository: repository),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.repository});

  final MoodRepository repository;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(repository: widget.repository),
      HistoryScreen(repository: widget.repository),
      WeeklyReviewScreen(repository: widget.repository),
      SettingsScreen(repository: widget.repository),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.edit_note), label: 'チェックイン'),
          NavigationDestination(icon: Icon(Icons.history), label: '履歴'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: '週次'),
          NavigationDestination(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }
}
