class MoodEntry {
  const MoodEntry({
    required this.id,
    required this.timestamp,
    required this.moodLevel,
    this.tag,
    this.note,
  });

  final String id;
  final DateTime timestamp;
  final int moodLevel;
  final String? tag;
  final String? note;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'moodLevel': moodLevel,
      'tag': tag,
      'note': note,
    };
  }

  factory MoodEntry.fromMap(Map<dynamic, dynamic> map) {
    return MoodEntry(
      id: map['id'] as String? ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      moodLevel: (map['moodLevel'] as num?)?.toInt() ?? 3,
      tag: map['tag'] as String?,
      note: map['note'] as String?,
    );
  }
}

const List<String> kMoodEmojis = ['😣', '😞', '😐', '🙂', '😀'];

String emojiForMood(int level) {
  final index =
      (level - 1).clamp(0, kMoodEmojis.length - 1).toInt();
  return kMoodEmojis[index];
}
