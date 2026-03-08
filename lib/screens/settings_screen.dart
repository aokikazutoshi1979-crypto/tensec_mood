import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';
import '../services/app_settings.dart';
import '../services/mood_repository.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.repository,
    required this.settings,
    required this.lockService,
    required this.onOpenPaywall,
  });

  final MoodRepository repository;
  final AppSettings settings;
  final AppLockService lockService;
  final VoidCallback onOpenPaywall;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _notificationEnabled;
  late int _notificationHour;
  late int _notificationMinute;

  @override
  void initState() {
    super.initState();
    _notificationEnabled = widget.settings.notificationEnabled;
    _notificationHour = widget.settings.notificationHour;
    _notificationMinute = widget.settings.notificationMinute;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '設定',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),

        // ── セキュリティ ──
        _sectionHeader('セキュリティ'),
        Card(
          elevation: 0,
          child: ValueListenableBuilder<bool>(
            valueListenable: widget.settings.lockEnabled,
            builder: (context, enabled, _) {
              return SwitchListTile(
                title: const Text('パスコード / Face ID ロック'),
                subtitle: const Text('アプリ起動時と復帰時にロックします。'),
                value: enabled,
                onChanged: (value) => _toggleLock(value),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // ── プライバシー ──
        _sectionHeader('プライバシー'),
        Card(
          elevation: 0,
          child: ListTile(
            title: const Text('データの保存場所'),
            subtitle: const Text('すべてのデータはこの端末にのみ保存されます'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDataLocationDialog(context),
          ),
        ),
        const SizedBox(height: 16),

        // ── 通知 ──
        _sectionHeader('通知'),
        Card(
          elevation: 0,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('リマインダー通知'),
                subtitle: const Text('毎日、記録のお知らせを送ります。'),
                value: _notificationEnabled,
                onChanged: _toggleNotification,
              ),
              if (_notificationEnabled) ...[
                const Divider(height: 1),
                ListTile(
                  title: const Text('通知時刻'),
                  subtitle: Text(
                    _formatTime(_notificationHour, _notificationMinute),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickTime,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── サポート ──
        _sectionHeader('サポート'),
        Card(
          elevation: 0,
          child: Column(
            children: [
              ListTile(
                title: const Text('プレミアム（構想）'),
                subtitle: const Text('現在は無料。将来の有料プラン案内のダミーです。'),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onOpenPaywall,
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('データをすべて削除'),
                subtitle: const Text('履歴が全て消えます。'),
                trailing: const Icon(Icons.delete_outline),
                onTap: () => _confirmClear(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── このアプリについて ──
        _sectionHeader('このアプリについて'),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'このアプリは医療行為を目的としたものではありません。'
              '体調や気分の不調が続く場合は、専門家へ相談してください。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Future<void> _showDataLocationDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('データの保存場所'),
          content: const Text(
            'すべての気分記録データは、'
            'あなたのスマートフォンの'
            '内部ストレージにのみ保存されます。\n\n'
            '・クラウドへの送信: なし\n'
            '・外部サーバーへの通信: なし\n'
            '・ネット接続なしで使用可能: ✓\n\n'
            'データの削除は「データをすべて削除」から行えます。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(int hour, int minute) {
    final period = hour < 12 ? '午前' : '午後';
    final h = hour == 0 ? 12 : hour > 12 ? hour - 12 : hour;
    final m = minute.toString().padLeft(2, '0');
    return '$period $h:$m';
  }

  Future<void> _toggleNotification(bool value) async {
    if (value) {
      final granted = await NotificationService.requestPermission();
      if (!granted) return;
      await widget.settings.setNotification(
        enabled: true,
        hour: _notificationHour,
        minute: _notificationMinute,
      );
      await NotificationService.scheduleDailyReminder(
        hour: _notificationHour,
        minute: _notificationMinute,
      );
    } else {
      await widget.settings.setNotification(enabled: false);
      await NotificationService.cancelReminder();
    }
    if (mounted) {
      setState(() => _notificationEnabled = value);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _notificationHour, minute: _notificationMinute),
    );
    if (picked == null || !mounted) return;
    await widget.settings.setNotification(
      enabled: true,
      hour: picked.hour,
      minute: picked.minute,
    );
    await NotificationService.scheduleDailyReminder(
      hour: picked.hour,
      minute: picked.minute,
    );
    setState(() {
      _notificationHour = picked.hour;
      _notificationMinute = picked.minute;
    });
  }

  Future<void> _toggleLock(bool value) async {
    if (!value) {
      await widget.settings.setLockEnabled(false);
      return;
    }

    final supported = await widget.lockService.isSupported();
    if (!supported) {
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('ロックを使えません'),
            content: const Text('この端末では生体認証またはパスコードが利用できません。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    await widget.settings.setLockEnabled(true);
  }

  Future<void> _confirmClear(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('データを削除しますか？'),
          content: const Text('この操作は元に戻せません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
    if (result == true) {
      await widget.repository.clearAll();
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('データを削除しました')),
      );
    }
  }
}
