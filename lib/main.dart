import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'firebase_options.dart';
import 'package:zorbalik_uygulamasi/screens/karsilama_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/ana_navigation_ekrani.dart';
import 'dart:async';

void main() async {
  // Widget bağlayıcılarını hazırlar, .env dosyasını yükler ve Firebase'i mevcut platforma göre başlatır.
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// WidgetsBindingObserver: Uygulamanın arka plana atılması veya tekrar açılması gibi durumları izlemek için eklenmiştir.
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Timer? _statusTimer; // Kullanıcının aktifliğini periyodik olarak güncelleyen zamanlayıcı.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Uygulama yaşam döngüsü gözlemcisini kaydeder.
    _startStatusHeartbeat(); // Uygulama açıldığında çevrimiçi takibini başlatır.
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _setUserStatus(false); // Uygulama tamamen kapatılırken kullanıcıyı çevrimdışı yapar.
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Kullanıcının bağlantısının hala aktif olduğunu doğrulamak için her 1 dakikada bir Firestore'u günceller.
  void _startStatusHeartbeat() {
    _setUserStatus(true);
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _setUserStatus(true);
    });
  }

  // Uygulama ön plana geldiğinde (resumed) çevrimiçi, arka plana gittiğinde çevrimdışı yapar.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startStatusHeartbeat();
    } else {
      _statusTimer?.cancel();
      _setUserStatus(false);
    }
  }

  // Firestore üzerindeki 'isOnline' ve 'sonGorulme' alanlarını atomik olarak günceller.
  Future<void> _setUserStatus(bool isOnline) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'isOnline': isOnline,
          'sonGorulme': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint("Durum güncellenemedi: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Siber Kahraman',
      theme: AppTheme.lightTheme, // Merkezi tema dosyasından gelen tasarım ayarları.

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
                    _statusTimer?.cancel();
                    await _setUserStatus(false);
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