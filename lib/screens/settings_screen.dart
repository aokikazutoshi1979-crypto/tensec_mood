import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';
import '../services/app_settings.dart';
import '../services/mood_repository.dart';

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
  bool _notificationEnabled = false;

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
          child: SwitchListTile(
            title: const Text('リマインダー通知 (準備中)'),
            subtitle: const Text('Phase1では通知は送信しません。'),
            value: _notificationEnabled,
            onChanged: (value) {
              setState(() {
                _notificationEnabled = value;
              });
            },
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('データを削除しました')),
      );
    }
  }
}
