import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
    FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
    AndroidNotificationChannel(
      'appointments_channel',
      'Записи к врачу',
      description: 'Напоминания о предстоящих приёмах',
      importance: Importance.high,
    );

  Future<void> init() async {
    // Запрос разрешений
    await _fcm.requestPermission(
      alert: true, badge: true, sound: true);

    // Инициализация локальных уведомлений
    const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(
      const InitializationSettings(android: androidSettings));

    // Создание канала уведомлений (Android 8+)
    await _local
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_channel);

    // Обработка FCM когда приложение открыто
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        _local.show(
          0,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id, _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  // Показать уведомление о созданной записи
  Future<void> showBookingConfirmation({
    required String doctorName,
    required String date,
    required String time,
  }) async {
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Запись подтверждена!',
      'Приём у $doctorName — $date в $time',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id, _channel.name,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<String?> getToken() => _fcm.getToken();
}
