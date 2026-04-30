import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'firebase_options.dart';
import 'package:zorbalik_uygulamasi/screens/karsilama_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/ana_navigation_ekrani.dart';
import 'package:zorbalik_uygulamasi/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';

// Arka planda gelen bildirimleri işlemek için gereken top-level fonksiyon
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Arka planda mesaj alındı: ${message.messageId}");
}

void main() async {
  // Widget bağlayıcılarını hazırlar, .env dosyasını yükler ve Firebase'i mevcut platforma göre başlatır.
  WidgetsFlutterBinding.ensureInitialized();

  // Resim önbellek kapasitesini artırarak performansı iyileştirir (100 MB)
  PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024;

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Arka plan bildirim dinleyicisini kaydet
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
    _updateLastSeen();
  }

  // Uygulama açıldığında sadece bir kere sonGorulme güncellenir. Bu, veritabanı kotasını devasa oranda korur.
  Future<void> _updateLastSeen() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'sonGorulme': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Son görülme güncellenemedi: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Siber Kahraman',
      theme: AppTheme
          .lightTheme, // Merkezi tema dosyasından gelen tasarım ayarları.
      // Kullanıcının giriş yapıp yapmadığını anlık olarak dinler.
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Eğer giriş yapmış bir kullanıcı varsa:
          if (authSnapshot.hasData && authSnapshot.data != null) {
            final String uid = authSnapshot.data!.uid;

            // Auth'da var olan kullanıcının Firestore'da dökümanı olup olmadığını kontrol eder.
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, firestoreSnapshot) {
                if (firestoreSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // Kullanıcı Auth'da var ama Firestore dökümanı silinmişse oturumu kapatır.
                if (!firestoreSnapshot.hasData ||
                    !firestoreSnapshot.data!.exists) {
                  Future.microtask(() async {
                    await FirebaseAuth.instance.signOut();
                  });
                  return const HomePages();
                }

                return const AnaNavigation();
              },
            );
          }
          return const HomePages();
        },
      ),
    );
  }
}
