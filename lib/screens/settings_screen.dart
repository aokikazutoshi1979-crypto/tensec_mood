import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/mood_entry.dart';
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
  bool _exporting = false;

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
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          child: ListTile(
            title: const Text('CSVエクスポート'),
            subtitle: const Text('記録をCSVで共有します。'),
            trailing: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share),
            onTap: _exporting ? null : _exportCsv,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          child: ListTile(
            title: const Text('サブスクのご案内'),
            subtitle: const Text('有料版の内容を確認できます。'),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.onOpenPaywall,
          ),
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

  Future<void> _exportCsv() async {
    setState(() {
      _exporting = true;
    });
    try {
      final entries = widget.repository.entries.value;
      if (entries.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('エクスポートするデータがありません')),
          );
        }
        return;
      }

      final csv = _buildCsv(entries);
      final bytes = utf8.encode(csv);
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: 'text/csv',
            name: 'tensec_mood.csv',
          ),
        ],
        text: 'TenSec Moodの記録',
      );
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }

  String _buildCsv(List<MoodEntry> entries) {
    final buffer = StringBuffer();
    buffer.writeln('timestamp,moodLevel,tag,note');
    for (final entry in entries) {
      buffer.writeln(
        [
          _csvValue(entry.timestamp.toIso8601String()),
          entry.moodLevel.toString(),
          _csvValue(entry.tag),
          _csvValue(entry.note),
        ].join(','),
      );
    }
    return buffer.toString();
  }

  String _csvValue(String? value) {
    final sanitized = (value ?? '').replaceAll('"', '""');
    return '"$sanitized"';
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
