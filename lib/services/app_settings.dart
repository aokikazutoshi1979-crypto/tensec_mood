import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppSettings {
  AppSettings(this._box)
      : lockEnabled = ValueNotifier<bool>(
          _box.get('lockEnabled', defaultValue: false) as bool,
        );

  final Box _box;
  final ValueNotifier<bool> lockEnabled;

  Future<void> setLockEnabled(bool value) async {
    await _box.put('lockEnabled', value);
    lockEnabled.value = value;
  }
}
