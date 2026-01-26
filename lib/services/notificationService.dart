import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:powershare/services/session.dart';
import 'package:powershare/services/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ต้องเป็น top-level function สำหรับ background isolate
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {
    // ignore: avoid_catches_without_on_clauses
  }
  if (kDebugMode) {
    print(
      '[FCM] background message: ${message.messageId} data=${message.data}',
    );
  }
}

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    // Firebase ถูก initialize ใน main.dart แล้ว
    // แต่ถ้ามีกรณี init ถูกเรียกก่อน ให้กันไว้
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp();
      } catch (e) {
        if (kDebugMode) print('[FCM] Firebase.initializeApp failed: $e');
        rethrow;
      }
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Local notifications (ใช้แสดงตอนแอปเปิดอยู่)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(initSettings);

    await _ensurePermissions();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(message);
    });

    _initialized = true;
  }

  static Future<void> syncTopics({required bool isAdmin}) async {
    try {
      // ให้ทุกคนอยู่ topic users เผื่ออนาคต
      await FirebaseMessaging.instance.subscribeToTopic('users');

      if (isAdmin) {
        await FirebaseMessaging.instance.subscribeToTopic('admins');
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic('admins');
      }

      if (kDebugMode) {
        print('[FCM] syncTopics done. isAdmin=$isAdmin');
      }
    } catch (e) {
      if (kDebugMode) print('[FCM] syncTopics error: $e');
    }
  }

  static Future<String?> getToken() async {
    try {
      return FirebaseMessaging.instance.getToken();
    } catch (e) {
      if (kDebugMode) print('[FCM] getToken error: $e');
      return null;
    }
  }

  static Future<String?> getFcmToken() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    return await messaging.getToken();
  }

  static Future<void> _ensurePermissions() async {
    try {
      // iOS/macOS permission
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Android 13+ local notification permission prompt
      if (Platform.isAndroid) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      }

      if (Platform.isIOS || Platform.isMacOS) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e) {
      if (kDebugMode) print('[FCM] ensurePermissions error: $e');
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final title = notification?.title ?? 'แจ้งเตือน';
      final body = notification?.body ?? '';

      const androidDetails = AndroidNotificationDetails(
        'payments',
        'Payment Notifications',
        channelDescription: 'แจ้งเตือนเมื่อมีผู้ใช้ชำระเงิน',
        importance: Importance.max,
        priority: Priority.high,
      );

      const details = NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );

      if (kDebugMode) {
        print('[FCM] foreground notification shown: $title');
      }
    } catch (e) {
      if (kDebugMode) print('[FCM] showForegroundNotification error: $e');
    }
  }

  static Future<void> saveFcmToken(String token) async {
    // ใช้ Session.instance.user (จาก loginPage) เป็น user info
    final user = Session.instance.user;
    if (kDebugMode) print('[FCM] saveFcmToken: user = $user');
    if (user == null) {
      if (kDebugMode) print('[FCM] saveFcmToken: user == null');
      return;
    }

    final platform = Platform.isAndroid
        ? 'android'
        : Platform.isIOS
        ? 'ios'
        : Platform.operatingSystem;
    if (kDebugMode) print('[FCM] saveFcmToken: platform = $platform');

    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/user_devices');
    final headers = ApiConfig.headers;
    if (kDebugMode) print('[FCM] saveFcmToken: headers = $headers');
    final body = jsonEncode({
      'user_id': user['id'],
      'fcm_token': token,
      'platform': platform,
    });
    if (kDebugMode) print('[FCM] saveFcmToken: body = $body');
    try {
      final resp = await http.post(url, headers: headers, body: body);
      if (kDebugMode)
        print('[FCM] saveFcmToken: response = ${resp.statusCode} ${resp.body}');
      if (resp.statusCode == 201 || resp.statusCode == 204) {
        if (kDebugMode) print('[FCM] saveFcmToken: insert success');
      } else {
        if (kDebugMode)
          print(
            '[FCM] saveFcmToken: insert failed: ${resp.statusCode} ${resp.body}',
          );
      }
    } catch (e) {
      if (kDebugMode) print('[FCM] saveFcmToken: insert error $e');
    }
  }
}
