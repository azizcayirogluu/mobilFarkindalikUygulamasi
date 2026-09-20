import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Kahraman Dostum uygulaması için bildirim (FCM & Yerel) servisi.
/// flutter_local_notifications 22.3.1 API'sine tam uyumludur.
class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  bool _initialized = false;

  // Bildirim kanalı (Android 8.0+)
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Kahraman Bildirimleri',
    description: 'Önemli görev ve başarı bildirimleri.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize() async {
    if (_initialized) {
      await _saveTokenToFirestore();
      return;
    }
    _initialized = true;

    // 1. İzin iste
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) debugPrint('Bildirim izni verildi. ✅');
    }

    // 2. Yerel bildirimleri ayarla
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // flutter_local_notifications 22.3.1: initialize({required settings, ...})
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (kDebugMode) debugPrint("Bildirime tıklandı: ${details.payload}");
      },
    );

    // 3. Android için kanalı oluştur
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Token Yönetimi
    await _saveTokenToFirestore();
    
    _tokenRefreshSubscription = _fcm.onTokenRefresh.listen((newToken) {
      _updateTokenInFirestore(newToken);
    });

    // 5. Ön Plan Mesajları
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) {
        // show metodu artık named parametreler kullanıyor.
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id, // Positional: channelId
              channel.name, // Positional: channelName
              channelDescription: channel.description,
              icon: android.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'ticker',
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });

    // 6. Arka Plan Mesaj Tıklama
    _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) debugPrint('Arka plandaki bildirime tıklandı: ${message.data}');
    });

    // 7. Initial Message
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) debugPrint('Uygulama bildirimle başlatıldı.');
    }
  }

  Future<void> _saveTokenToFirestore() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      String? token = await _fcm.getToken();
      if (token != null) {
        await _updateTokenInFirestore(token);
      }
    } catch (e) {
      if (kDebugMode) debugPrint("FCM ilk token alma hatası: $e");
    }
  }

  Future<void> _updateTokenInFirestore(String token) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
              'fcmToken': token,
              'lastTokenUpdate': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        if (kDebugMode) debugPrint("FCM token güncellendi.");
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Token Firestore'a kaydedilemedi: $e");
    }
  }

  /// Manuel yerel bildirim gösterimi.
  Future<void> showLocalNotification(String title, String body) async {
    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id, // Positional
          channel.name, // Positional
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
    await _messageOpenedSubscription?.cancel();
    _initialized = false;
  }
}
