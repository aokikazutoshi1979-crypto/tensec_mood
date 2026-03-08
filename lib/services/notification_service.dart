import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _reminderBaseId = 1;

  static const List<String> _messages = [
    '今日はどんな気分でしたか？10秒だけ教えてください。',
    '1日の終わりに、気分を記録してみましょう。',
    '今日の自分を振り返る10秒です。',
    '今日の気分、まだ記録していません。',
    'ちょっとだけ、自分の気持ちを確認してみませんか？',
    '10秒で今日をしめくくりましょう。',
    '気分の記録、今日はしましたか？',
  ];

  // 通知タップ時のコールバック（AppShellが登録する）
  static void Function()? onNotificationTap;

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    const initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) {
        onNotificationTap?.call();
      },
    );
  }

  // iOS通知許可ダイアログを表示
  static Future<bool> requestPermission() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  // アプリが通知タップで起動されたか確認
  static Future<bool> didLaunchFromNotification() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp ?? false;
  }

  // 毎日の通知を各曜日に対してスケジュール（週次リピート）
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await cancelReminder();

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reminder',
        'デイリーリマインダー',
        channelDescription: '毎日の気分記録リマインダー',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    // 曜日ごとに通知をスケジュール（weekday: 1=月〜7=日）
    // メッセージ選択: weekday % 7 でインデックスを決定
    //   月=1%7=1, 火=2, 水=3, 木=4, 金=5, 土=6, 日=7%7=0
    for (int weekday = 1; weekday <= 7; weekday++) {
      final messageIndex = weekday % 7;
      final scheduledDate = _nextWeekdayAt(weekday, hour, minute);

      await _plugin.zonedSchedule(
        _reminderBaseId + weekday - 1,
        'TenSec Mood',
        _messages[messageIndex],
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  // 通知をすべてキャンセル
  static Future<void> cancelReminder() async {
    for (int i = 0; i < 7; i++) {
      await _plugin.cancel(_reminderBaseId + i);
    }
  }

  // 指定曜日の次の発火時刻を計算
  static tz.TZDateTime _nextWeekdayAt(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 対象曜日まで日を進める
    int daysUntil = (weekday - now.weekday) % 7;
    if (daysUntil == 0 && scheduled.isBefore(now)) {
      daysUntil = 7;
    }
    return scheduled.add(Duration(days: daysUntil));
  }
}
