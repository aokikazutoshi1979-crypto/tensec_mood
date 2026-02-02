import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/mood_entry.dart';

class MoodRepository {
  MoodRepository(this._box);

  final Box<Map> _box;
  final ValueNotifier<List<MoodEntry>> entries = ValueNotifier<List<MoodEntry>>([]);

  Future<void> loadEntries() async {
    try {
      final loaded = _box.values
          .map((map) => MoodEntry.fromMap(map))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      entries.value = loaded;
    } catch (error) {
      debugPrint('Failed to load entries: $error');
      entries.value = [];
    }
  }

  Future<void> addEntry(MoodEntry entry) async {
    try {
      await _box.put(entry.id, entry.toMap());
      await loadEntries();
    } catch (error) {
      debugPrint('Failed to add entry: $error');
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      await _box.delete(id);
      await loadEntries();
    } catch (error) {
      debugPrint('Failed to delete entry: $error');
    }
  }

  Future<void> clearAll() async {
    try {
      await _box.clear();
      await loadEntries();
    } catch (error) {
      debugPrint('Failed to clear entries: $error');
    }
  }
}
