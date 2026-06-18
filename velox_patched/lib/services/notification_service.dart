import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Request Android 13+ notification permission via permission_handler
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
          '[FCM] Foreground: ${message.notification?.title} — ${message.notification?.body}');
    });

    // Handle notification tap while app in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Opened from background: ${message.data}');
    });

    // Check if app was launched from a terminated notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      debugPrint('[FCM] Launched from terminated: ${initial.data}');
    }
  }

  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('FCM token error: $e');
      return null;
    }
  }
}
