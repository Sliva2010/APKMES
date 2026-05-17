// Локальные уведомления NOCTIS.
// Используются для:
// - входящих сообщений (когда чат не открыт);
// - входящих звонков (full-screen intent на Android).
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const AndroidNotificationChannel _messages =
      AndroidNotificationChannel(
    'noctis_messages',
    'Сообщения',
    description: 'Уведомления о входящих сообщениях',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel _calls =
      AndroidNotificationChannel(
    'noctis_calls',
    'Звонки',
    description: 'Входящие голосовые и видео-звонки',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@drawable/app_icon');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);
    try {
      await _plugin.initialize(initSettings);
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.createNotificationChannel(_messages);
        await android.createNotificationChannel(_calls);
        await android.requestNotificationsPermission();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Notification init failed: $e');
      }
    }
  }

  static Future<void> showMessage({
    required String chatTitle,
    required String body,
    int id = 1001,
  }) async {
    if (!_initialized) await init();
    try {
      await _plugin.show(
        id,
        chatTitle,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _messages.id,
            _messages.name,
            channelDescription: _messages.description,
            importance: Importance.high,
            priority: Priority.high,
            ticker: chatTitle,
            styleInformation: BigTextStyleInformation(body),
          ),
        ),
      );
    } catch (_) {}
  }

  static Future<void> showCall({
    required String contactName,
    required bool video,
    int id = 2001,
  }) async {
    if (!_initialized) await init();
    try {
      await _plugin.show(
        id,
        contactName,
        video ? 'Входящий видео-звонок' : 'Входящий звонок',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _calls.id,
            _calls.name,
            channelDescription: _calls.description,
            importance: Importance.max,
            priority: Priority.max,
            ongoing: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.call,
          ),
        ),
      );
    } catch (_) {}
  }

  static Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
