import 'package:flutter/material.dart';
import '../services/mood_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.repository});

  final MoodRepository repository;

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
        const SizedBox(height: 12),
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
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          child: ListTile(
            title: const Text('データをすべて削除'),
            subtitle: const Text('履歴が全て消えます。'),
            trailing: const Icon(Icons.delete_outline),
            onTap: () => _confirmClear(context),
          ),
        ),
        const SizedBox(height: 12),
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
