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
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Bildirim kanalını tanımlıyoruz (Android 8.0+ için şart)
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'Kahraman Bildirimleri', // title
    description: 'Önemli görev ve başarı bildirimleri.',
    importance: Importance.max, // En yüksek öncelik (Anlık görünmesi için)
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize() async {
    // 1. İzin iste (iOS ve Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Kullanıcı bildirim izni verdi. ✅');
    }

    // 2. Yerel bildirimleri ayarla
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("Bildirime tıklandı: ${details.payload}");
      },
    );

    // 3. Android için kanalı oluştur
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Token Yönetimi
    _saveTokenToFirestore();
    
    // Token yenilendiğinde otomatik güncelle
    _fcm.onTokenRefresh.listen((newToken) {
      _updateTokenInFirestore(newToken);
    });

    // 5. Uygulama Ön Plandayken gelen mesajları dinle
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
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

    // 6. Arka planda bildirime tıklandığında açılma durumunu kontrol et
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Arka planda bildirime tıklandı: ${message.data}');
    });

    // 7. Uygulama kapalıyken (Terminated) bildirimle açıldıysa yakala
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('Uygulama bildirimle başlatıldı: ${initialMessage.data}');
    }
  }

  // Firestore'a Token kaydetme (Gecikmeli ve Güvenli)
  Future<void> _saveTokenToFirestore() async {
    try {
      // Servislerin ısınması için kısa bir bekleme (SERVICE_NOT_AVAILABLE hatasını önler)
      await Future.delayed(const Duration(seconds: 3));
      
      String? token = await _fcm.getToken();
      if (token != null) {
        await _updateTokenInFirestore(token);
      }
    } catch (e) {
      debugPrint("FCM ilk token alma hatası: $e");
    }
  }

  // Token güncelleme mantığı (Merkezi)
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
        debugPrint("FCM Token başarıyla mühürlendi. 🛡️");
      }
    } catch (e) {
      debugPrint("Token Firestore'a kaydedilemedi: $e");
    }
  }

  // Manuel bildirim tetikleme (Örn: Bir görev bittiğinde)
  Future<void> showLocalNotification(String title, String body) async {
    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
