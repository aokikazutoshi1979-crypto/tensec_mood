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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _noteController = TextEditingController();
  final Uuid _uuid = const Uuid();

  int _selectedMood = 3;
  String? _selectedTag;

  OverlayEntry? _overlayEntry;
  AnimationController? _feedbackController;
  bool _dismissing = false;

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
    _feedbackController?.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  Future<void> _showPrivacyDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('プライバシーについて'),
          content: const Text(
            'TenSec Mood に記録したデータは、'
            'すべてあなたのスマートフォンの中にのみ保存されます。\n\n'
            'クラウドへの送信、外部サーバーへの通信は'
            '一切行っておりません。\n'
            'インターネットに接続していなくても使用できます。',
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

  String _getFeedbackEmoji(int level) {
    const emojis = {1: '😣', 2: '😞', 3: '😐', 4: '🙂', 5: '😀'};
    return emojis[level] ?? '😐';
  }

  String _getFeedbackMessage(int level) {
    const messages = {
      1: '今日は大変だったね。\n記録してくれてありがとう。',
      2: 'しんどい中、記録できた。\nそれだけで十分。',
      3: '記録しました。\n続けると気づきが生まれます。',
      4: 'いい感じですね。\n記録しました。',
      5: '今日は調子がいいんですね。\n記録しました！',
    };
    return messages[level] ?? '記録しました。';
  }

  void _showMoodFeedback(int level) {
    // 前回のフィードバックが残っていれば即座に除去
    _overlayEntry?.remove();
    _overlayEntry = null;
    _feedbackController?.dispose();
    _dismissing = false;

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    final animation = CurvedAnimation(
      parent: _feedbackController!,
      curve: Curves.easeIn,
    );

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: GestureDetector(
          onTap: _dismissFeedback,
          behavior: HitTestBehavior.translucent,
          child: Center(
            child: FadeTransition(
              opacity: animation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getFeedbackEmoji(level),
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getFeedbackMessage(level),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _feedbackController!.forward();

    // フェードイン(200ms) + 表示(1400ms) 後にフェードアウト開始 → 合計 1800ms
    Future.delayed(const Duration(milliseconds: 1600), _dismissFeedback);
  }

  void _dismissFeedback() {
    if (_dismissing || _feedbackController == null || _overlayEntry == null) {
      return;
    }
    _dismissing = true;
    _feedbackController!.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _feedbackController?.dispose();
      _feedbackController = null;
      _dismissing = false;
    });
  }

  Future<void> _saveEntry() async {
    final level = _selectedMood;
    final note = _noteController.text.trim();
    final entry = MoodEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      moodLevel: level,
      tag: _selectedTag,
      note: note.isEmpty ? null : note,
    );
    await widget.repository.addEntry(entry);
    if (!mounted) return;

    // フィードバック表示と同時に状態リセット
    _showMoodFeedback(level);
    setState(() {
      _selectedMood = 3;
      _selectedTag = null;
    });
    _noteController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '今日はどうだった？',
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
                      'きっかけタグ（任意）',
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
                    hintText: '例）友達と話して楽しかった',
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
                GestureDetector(
                  onTap: () => _showPrivacyDialog(context),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 12,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'データはこの端末にだけ保存されます 🔒',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
