import 'package:flutter/material.dart';
import '../models/mood_entry.dart';
import '../services/mood_repository.dart';

class WeeklyReviewScreen extends StatelessWidget {
  const WeeklyReviewScreen({super.key, required this.repository});

  final MoodRepository repository;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<MoodEntry>>(
      valueListenable: repository.entries,
      builder: (context, entries, _) {
        final now = DateTime.now();
        final cutoff = now.subtract(const Duration(days: 7));
        final recent = entries
            .where((entry) => !entry.timestamp.isBefore(cutoff))
            .toList();

        final moodCounts = List<int>.filled(5, 0);
        var totalMood = 0;
        final tagCounts = <String, int>{};

        for (final entry in recent) {
          final index = (entry.moodLevel - 1).clamp(0, 4).toInt();
          moodCounts[index]++;
          totalMood += entry.moodLevel;
          if (entry.tag != null && entry.tag!.isNotEmpty) {
            tagCounts.update(entry.tag!, (value) => value + 1,
                ifAbsent: () => 1);
          }
        }

        final count = recent.length;
        final average = count == 0 ? 0.0 : totalMood / count;
        final maxCount = moodCounts.fold<int>(0, (a, b) => a > b ? a : b);
        final topTags = tagCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '直近7日間のふり返り',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: '気分平均',
              child: Text(
                count == 0 ? '記録なし' : average.toStringAsFixed(1),
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'よく出たタグ',
              child: count == 0 || topTags.isEmpty
                  ? const Text('記録なし')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: topTags.take(3).map((entry) {
                        return Text('${entry.key} (${entry.value}回)');
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: '気分分布',
              child: Column(
                children: List.generate(5, (index) {
                  final level = index + 1;
                  final value = moodCounts[index];
                  final ratio = maxCount == 0 ? 0.0 : value / maxCount;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(emojiForMood(level)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: ratio,
                                child: Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(width: 24, child: Text(value.toString())),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'やさしい一言',
              child: Text(_buildMessage(count, average)),
            ),
          ],
        );
      },
    );
  }

  String _buildMessage(int count, double average) {
    if (count < 3) {
      return '顔を押すだけでも十分。気が向いた時にね。';
    }
    if (average < 2.5) {
      return 'しんどい中でも記録できたのがえらい。';
    }
    if (average < 3.5) {
      return '今週は波がありそう。無理せずいこう。';
    }
    return '今週は比較的落ち着いた日が多め。';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
