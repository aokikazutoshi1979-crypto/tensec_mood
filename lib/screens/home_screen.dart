import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/mood_entry.dart';
import '../services/mood_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});

  final MoodRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _noteController = TextEditingController();
  final Uuid _uuid = const Uuid();

  int _selectedMood = 3;
  String? _selectedTag;

  static const List<String> _tags = [
    '仕事',
    '人間関係',
    '体調',
    'お金',
    '将来',
    '睡眠',
    '家族',
    'その他',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    final note = _noteController.text.trim();
    final entry = MoodEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      moodLevel: _selectedMood,
      tag: _selectedTag,
      note: note.isEmpty ? null : note,
    );
    await widget.repository.addEntry(entry);
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedTag = null;
      _noteController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('記録を保存しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '10秒で気分を記録',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今の気分を選ぶ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(kMoodEmojis.length, (index) {
                    final level = index + 1;
                    final selected = _selectedMood == level;
                    return InkResponse(
                      onTap: () {
                        setState(() {
                          _selectedMood = level;
                        });
                      },
                      radius: 24,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? colorScheme.primaryContainer
                              : colorScheme.surface,
                        ),
                        child: Text(
                          kMoodEmojis[index],
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '原因タグ (任意)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedTag = null;
                        });
                      },
                      child: const Text('スキップ'),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((tag) {
                    final selected = _selectedTag == tag;
                    return ChoiceChip(
                      label: Text(tag),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _selectedTag = selected ? null : tag;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text(
                  'ひとことメモ (任意)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLength: 80,
                  maxLines: 1,
                  decoration: const InputDecoration(
                    hintText: '例）少し疲れた',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saveEntry,
                    child: const Text('保存する'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '気が向いた時だけでOKです。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
