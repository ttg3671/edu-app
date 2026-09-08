import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important push notifications.',
    importance: Importance.max,
    playSound: true,
  );

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Request Notification Permissions (iOS & Android 13+)
      await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // 2. Set iOS foreground presentation options
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Initialize Local Notifications for Android heads-up display
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleNotificationClick(response.payload);
        },
      );

      // 4. Create Notification Channel for Android
      if (Platform.isAndroid) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);
      }

      // 5. Subscribe to "all" topic matching backend logic: topic: "all"
      await subscribeToAll();

      // 6. Handle Background Messages
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 7. Handle Foreground Messages (Display Heads-Up banner)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showForegroundNotification(message);
      });

      // 8. Handle Notification Opened from Background State
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleMessageNavigation(message);
      });

      // 9. Handle Notification Opened from Terminated State
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageNavigation(initialMessage);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Subscribes this device to the "all" topic
  Future<void> subscribeToAll() async {
    try {
      await _messaging.subscribeToTopic('all');
    } catch (e) {
      debugPrint('Error subscribing to topic "all": $e');
    }
  }

  /// Unsubscribe from "all" topic if needed
  Future<void> unsubscribeFromAll() async {
    try {
      await _messaging.unsubscribeFromTopic('all');
    } catch (e) {
      debugPrint('Error unsubscribing from topic "all": $e');
    }
  }

  /// Display a local notification banner when app is open in foreground
  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title ?? "Edu Garcia Movimiento 💪",
      body: notification.body ?? "",
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: '@mipmap/launcher_icon',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleNotificationClick(String? payload) {
    if (payload != null && payload.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(payload);
        debugPrint('Notification payload clicked: $data');
      } catch (_) {}
    }
  }

  void _handleMessageNavigation(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
  }
}
