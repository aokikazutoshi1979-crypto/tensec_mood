import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/weekly_review_screen.dart';
import 'services/app_lock_service.dart';
import 'services/app_settings.dart';
import 'services/mood_repository.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Hiveは軽量で導入が簡単、コード生成なしでMVPに適しているため採用。
  await Hive.initFlutter();

  final box = await Hive.openBox<Map>('mood_entries');
  final settingsBox = await Hive.openBox('app_settings');
  final repository = MoodRepository(box);
  await repository.loadEntries();

  final settings = AppSettings(settingsBox);
  final lockService = AppLockService();

  await NotificationService.initialize();
  if (settings.notificationEnabled) {
    await NotificationService.scheduleDailyReminder(
      hour: settings.notificationHour,
      minute: settings.notificationMinute,
    );
  }

  runApp(TensecMoodApp(
    repository: repository,
    settings: settings,
    lockService: lockService,
  ));
}

class TensecMoodApp extends StatelessWidget {
  const TensecMoodApp({
    super.key,
    required this.repository,
    required this.settings,
    required this.lockService,
  });

  final MoodRepository repository;
  final AppSettings settings;
  final AppLockService lockService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TenSec Mood',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: AppShell(
        repository: repository,
        settings: settings,
        lockService: lockService,
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.repository,
    required this.settings,
    required this.lockService,
  });

  final MoodRepository repository;
  final AppSettings settings;
  final AppLockService lockService;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isLocked = false;
  bool _authInProgress = false;
  bool _needsLock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.settings.lockEnabled.addListener(_handleLockChange);
    _needsLock = widget.settings.lockEnabled.value;
    _evaluateInitialLock();
    NotificationService.onNotificationTap = _navigateToHome;
    _checkNotificationLaunch();
  }

  void _navigateToHome() {
    if (mounted) {
      setState(() => _currentIndex = 0);
    }
  }

  Future<void> _checkNotificationLaunch() async {
    final launched = await NotificationService.didLaunchFromNotification();
    if (launched && mounted) {
      setState(() => _currentIndex = 0);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.settings.lockEnabled.removeListener(_handleLockChange);
    NotificationService.onNotificationTap = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (widget.settings.lockEnabled.value && _needsLock) {
          _lockAndAuthenticate();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        if (widget.settings.lockEnabled.value && !_authInProgress) {
          _needsLock = true;
        }
        break;
    }
  }

  void _handleLockChange() {
    if (!mounted) {
      return;
    }
    if (widget.settings.lockEnabled.value) {
      _needsLock = true;
      _lockAndAuthenticate();
    } else {
      setState(() {
        _isLocked = false;
      });
      _needsLock = false;
    }
  }

  Future<void> _evaluateInitialLock() async {
    if (widget.settings.lockEnabled.value) {
      _needsLock = true;
      await _lockAndAuthenticate();
    }
  }

  Future<void> _lockAndAuthenticate() async {
    if (_authInProgress) {
      return;
    }
    _authInProgress = true;
    if (mounted) {
      setState(() {
        _isLocked = true;
      });
    }

    final supported = await widget.lockService.isSupported();
    if (!supported) {
      await widget.settings.setLockEnabled(false);
      if (mounted) {
        setState(() {
          _isLocked = false;
        });
      }
      _authInProgress = false;
      return;
    }

    final success = await widget.lockService.authenticate();
    if (mounted && success) {
      setState(() {
        _isLocked = false;
      });
      _needsLock = false;
    }
    _authInProgress = false;
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(repository: widget.repository),
      HistoryScreen(repository: widget.repository),
      WeeklyReviewScreen(
        repository: widget.repository,
        onSwitchToCheckin: () => setState(() => _currentIndex = 0),
      ),
      SettingsScreen(
        repository: widget.repository,
        settings: widget.settings,
        lockService: widget.lockService,
        onOpenPaywall: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PaywallScreen()),
          );
        },
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: _isLocked
            ? _LockScreen(onUnlock: _lockAndAuthenticate)
            : IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
      ),
      bottomNavigationBar: _isLocked
          ? null
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.edit_note), label: 'チェックイン'),
                NavigationDestination(icon: Icon(Icons.history), label: '履歴'),
                NavigationDestination(icon: Icon(Icons.bar_chart), label: '週次'),
                NavigationDestination(icon: Icon(Icons.settings), label: '設定'),
              ],
            ),
    );
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 48),
            const SizedBox(height: 16),
            Text(
              'ロック中',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('認証してアプリを開きます。'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onUnlock,
              child: const Text('認証する'),
            ),
          ],
        ),
      ),
    );
  }
}
