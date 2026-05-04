import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  // Singleton pattern: Uygulamada tek bir NotificationService nesnesi olmasını garanti eder.
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Bildirim kanalını tanımlıyoruz (Android için şart)
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'Yüksek Öncelikli Bildirimler', // title
    description: 'Bu kanal önemli uygulama bildirimleri için kullanılır.',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    // 1. İzin iste (iOS ve Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Kullanıcı bildirim izni verdi.');
    }

    // 2. Yerel bildirimleri ayarla
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // Yeni sürümde named parameter (settings) kullanılıyor
    await _localNotifications.initialize(settings: initializationSettings);

    // 3. Android için kanalı oluştur
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // 4. Token'ı al ve Firestore'a kaydet
    _saveTokenToFirestore();

    // 5. Uygulama Ön Plandayken gelen mesajları dinle
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) {
        // Yeni sürümde named parameters (id, title, body, notificationDetails) kullanılıyor
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: android.smallIcon,
            ),
          ),
        );
      }
    });

    // 6. Uygulama kapalıyken bildirime tıklandığında açılma durumunu kontrol et
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Bildirime tıklandı: ${message.data}');
    });
  }

  Future<void> _saveTokenToFirestore() async {
    String? token = await _fcm.getToken();
    User? user = FirebaseAuth.instance.currentUser;

    if (token != null && user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'fcmToken': token, 'lastTokenUpdate': FieldValue.serverTimestamp()},
      );
      debugPrint("FCM Token kaydedildi: $token");
    }
  }
}
