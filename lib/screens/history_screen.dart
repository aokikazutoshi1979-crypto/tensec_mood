import 'package:flutter/material.dart';
import '../models/mood_entry.dart';
import '../services/mood_repository.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.repository});

  final MoodRepository repository;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<MoodEntry>>(
      valueListenable: repository.entries,
      builder: (context, entries, _) {
        if (entries.isEmpty) {
          return const Center(child: Text('まだ記録がありません。'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final line = [
              _formatDate(entry.timestamp),
              emojiForMood(entry.moodLevel),
              if (entry.tag != null && entry.tag!.isNotEmpty) entry.tag!,
              if (entry.note != null && entry.note!.isNotEmpty) entry.note!,
            ].join(' ');

            return Dismissible(
              key: ValueKey(entry.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _confirmDelete(context),
              onDismissed: (_) => repository.deleteEntry(entry.id),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                color: Colors.red.withOpacity(0.15),
                child: const Icon(Icons.delete, color: Colors.red),
              ),
              child: Card(
                elevation: 0,
                child: ListTile(
                  title: Text(
                    line,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _showDetail(context, entry),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('削除しますか？'),
          content: const Text('この記録は元に戻せません。'),
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
    return result ?? false;
  }

  void _showDetail(BuildContext context, MoodEntry entry) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '詳細',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _DetailRow(label: '日時', value: _formatFullDate(entry.timestamp)),
              _DetailRow(label: '気分', value: emojiForMood(entry.moodLevel)),
              _DetailRow(label: 'タグ', value: entry.tag ?? 'なし'),
              _DetailRow(label: 'メモ', value: entry.note ?? 'なし'),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime timestamp) {
    final local = timestamp.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$month/$day';
  }

  String _formatFullDate(DateTime timestamp) {
    final local = timestamp.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$year/$month/$day $hour:$minute';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
