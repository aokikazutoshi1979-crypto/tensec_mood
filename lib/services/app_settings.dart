import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppSettings {
  AppSettings(this._box)
      : lockEnabled = ValueNotifier<bool>(
          _box.get('lockEnabled', defaultValue: false) as bool,
        );

  final Box _box;
  final ValueNotifier<bool> lockEnabled;

  // ── ロック ──

  Future<void> setLockEnabled(bool value) async {
    await _box.put('lockEnabled', value);
    lockEnabled.value = value;
  }

  // ── 通知 ──

  static const String _notificationEnabledKey = 'notification_enabled';
  static const String _notificationHourKey = 'notification_hour';
  static const String _notificationMinuteKey = 'notification_minute';

  bool get notificationEnabled =>
      _box.get(_notificationEnabledKey, defaultValue: false) as bool;

  int get notificationHour =>
      _box.get(_notificationHourKey, defaultValue: 21) as int;

  int get notificationMinute =>
      _box.get(_notificationMinuteKey, defaultValue: 0) as int;

  Future<void> setNotification({
    required bool enabled,
    int hour = 21,
    int minute = 0,
  }) async {
    await _box.put(_notificationEnabledKey, enabled);
    await _box.put(_notificationHourKey, hour);
    await _box.put(_notificationMinuteKey, minute);
  }
}
