import 'package:flutter/material.dart';
import '../models/mood_entry.dart';
import '../services/mood_repository.dart';

class WeeklyReviewScreen extends StatelessWidget {
  const WeeklyReviewScreen({
    super.key,
    required this.repository,
    required this.onSwitchToCheckin,
  });

  final MoodRepository repository;
  final VoidCallback onSwitchToCheckin;

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

        if (recent.isEmpty) {
          return _buildEmptyState(context);
        } else if (recent.length < 3) {
          return _buildProgressState(context, recent);
        } else if (recent.length < 7) {
          return _buildEarlyInsightState(context, recent);
        } else {
          return _buildFullReview(context, recent);
        }
      },
    );
  }

  _ReviewData _computeData(List<MoodEntry> entries) {
    final moodCounts = List<int>.filled(5, 0);
    var totalMood = 0;
    final tagCounts = <String, int>{};

    for (final entry in entries) {
      final index = (entry.moodLevel - 1).clamp(0, 4).toInt();
      moodCounts[index]++;
      totalMood += entry.moodLevel;
      if (entry.tag != null && entry.tag!.isNotEmpty) {
        tagCounts.update(entry.tag!, (v) => v + 1, ifAbsent: () => 1);
      }
    }

    final count = entries.length;
    final average = totalMood / count;
    final maxCount = moodCounts.fold<int>(0, (a, b) => a > b ? a : b);
    final topTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTag = topTags.isNotEmpty ? topTags.first.key : null;

    return _ReviewData(
      moodCounts: moodCounts,
      count: count,
      average: average,
      maxCount: maxCount,
      topTags: topTags,
      topTag: topTag,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📊', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 24),
            Text(
              'まだ記録がありません。',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '気分の絵文字を1つタップするだけ。\n3回記録すると、あなたの傾向が\n見えてきます。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onSwitchToCheckin,
              child: const Text('気分を記録する →'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressState(BuildContext context, List<MoodEntry> entries) {
    final data = _computeData(entries);
    final remaining = 3 - entries.length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '直近7日間のふり返り',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'あと$remaining回で最初の気づきが見えます',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: entries.length / 3,
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${entries.length}/3'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ..._buildCommonSections(context, data),
      ],
    );
  }

  Widget _buildEarlyInsightState(
      BuildContext context, List<MoodEntry> entries) {
    final data = _computeData(entries);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '直近7日間のふり返り',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ..._buildCommonSections(context, data),
        const SizedBox(height: 12),
        _buildInsightCard(context, data),
      ],
    );
  }

  Widget _buildFullReview(BuildContext context, List<MoodEntry> entries) {
    final data = _computeData(entries);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '直近7日間のふり返り',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ..._buildCommonSections(context, data),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'やさしい一言',
          child: Text(_buildMessage(data.count, data.average, data.topTag)),
        ),
      ],
    );
  }

  List<Widget> _buildCommonSections(BuildContext context, _ReviewData data) {
    return [
      _SectionCard(
        title: 'サマリー',
        child: Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: '平均',
                value: data.average.toStringAsFixed(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                label: '記録数',
                value: '${data.count}件',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _SectionCard(
        title: 'よく出たタグ',
        child: data.topTags.isEmpty
            ? const Text('記録なし')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: data.topTags.take(3).map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('${entry.key} (${entry.value}回)'),
                  );
                }).toList(),
              ),
      ),
      const SizedBox(height: 12),
      _SectionCard(
        title: '気分分布',
        child: Column(
          children: List.generate(5, (index) {
            final level = index + 1;
            final value = data.moodCounts[index];
            final ratio =
                data.maxCount == 0 ? 0.0 : value / data.maxCount;
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
                              color: Theme.of(context).colorScheme.primary,
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
    ];
  }

  Widget _buildInsightCard(BuildContext context, _ReviewData data) {
    return _SectionCard(
      title: '💡 あなたへの最初の気づき',
      child: Text(_buildEarlyInsightMessage(data.average, data.topTag)),
    );
  }

  String _buildEarlyInsightMessage(double average, String? topTag) {
    if (topTag != null) {
      return '$topTagに関する日が多めです。';
    }
    if (average < 3.0) {
      return '最近は少し疲れが出ているかもしれません。\n記録を続けると、回復のパターンが見えてきます。';
    }
    if (average >= 4.0) {
      return '落ち着いた日が続いていますね。\nこのまま記録を続けてみましょう。';
    }
    return 'まだ記録が少ないですが、傾向が見えてきました。\n続けるともっと詳しく分析できます。';
  }

  String _buildMessage(int count, double average, String? topTag) {
    if (topTag == '睡眠') {
      return '睡眠に関するタグが多めです。睡眠が気分に影響していそうです。';
    }
    if (topTag == '仕事') {
      return '仕事のことが頭にある週だったようです。週末はゆっくりできましたか？';
    }
    if (count >= 5) {
      return '今週はしっかり記録できていますね。続けると気づきが生まれます。';
    }
    if (count == 1) {
      return '今週は1回記録できました。それだけで十分な一歩です。';
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

class _ReviewData {
  const _ReviewData({
    required this.moodCounts,
    required this.count,
    required this.average,
    required this.maxCount,
    required this.topTags,
    required this.topTag,
  });

  final List<int> moodCounts;
  final int count;
  final double average;
  final int maxCount;
  final List<MapEntry<String, int>> topTags;
  final String? topTag;
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}
