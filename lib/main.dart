import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/karsilama_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/ana_navigation_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/onboarding_ekrani.dart';
import 'package:zorbalik_uygulamasi/services/storage_service.dart';
import 'package:zorbalik_uygulamasi/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'injection_container.dart' as di;


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isFirstRun = true;
  bool initFailed = false;

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await _activateAppCheck();
    
    await di.init();
    await StorageService().init();

    if (!kIsWeb) {
      try {
        await MobileAds.instance.initialize();
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(
            tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
            maxAdContentRating: MaxAdContentRating.g,
          ),
        );
      } catch (e) {
        debugPrint("AdMob başlatılamadı (Mobil): $e");
      }
    }

    isFirstRun = StorageService().isFirstRun();
    _applyPostInitSettings();
  } catch (e) {
    debugPrint("Kritik başlatma hatası: $e");
    initFailed = true;
  }

  if (initFailed) {
    runApp(const _InitErrorApp());
    return;
  }

  runApp(MyApp(isFirstRun: isFirstRun));
}

Future<void> _activateAppCheck() async {
  if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
    return;
  }

  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttestWithDeviceCheckFallback,
  );
}

void _applyPostInitSettings() {
  PaintingBinding.instance.imageCache.maximumSizeBytes = 20 * 1024 * 1024;
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 100 * 1024 * 1024,
    );
  } catch (e) {
    debugPrint("Firestore ayar hatası: $e");
  }
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

class _InitErrorApp extends StatelessWidget {
  const _InitErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 80, color: Colors.redAccent),
                const SizedBox(height: 24),
                const Text("Bağlantı Sorunu! 📡", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
                const SizedBox(height: 12),
                const Text("Kahramanlık profilini hazırlayamadık.\nİnternetini kontrol edip uygulamayı\nyeniden açar mısın?", textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey, height: 1.5)),
                const SizedBox(height: 30),
                ElevatedButton(onPressed: () => main(), child: const Text("TEKRAR DENE")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final bool isFirstRun;
  const MyApp({super.key, required this.isFirstRun});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kahraman Dostum',
      theme: AppTheme.lightTheme,
      home: isFirstRun ? const OnboardingEkrani() : const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return UserDataGate(uid: snapshot.data!.uid);
        }
        return const KarsilamaEkrani();
      },
    );
  }
}

enum _UserDataStatus { loading, ready, error }

class UserDataGate extends StatefulWidget {
  final String uid;
  const UserDataGate({super.key, required this.uid});

  @override
  State<UserDataGate> createState() => _UserDataGateState();
}

class _UserDataGateState extends State<UserDataGate> {
  _UserDataStatus _status = _UserDataStatus.loading;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _checkUserProfile();
  }

  /// SEC-03: Kullanıcı verilerinin Cloud Function (onUserCreated) tarafından oluşturulmasını bekler.
  /// Client-side veri oluşturma (recovery) kaldırıldı, güvenli hale getirildi.
  Future<void> _checkUserProfile() async {
    if (!mounted) return;
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 10));

      if (doc.exists) {
        if (mounted) setState(() => _status = _UserDataStatus.ready);
      } else {
        // Cloud Function veriyi henüz oluşturmamış olabilir, 2 saniye sonra tekrar dene.
        if (_retryCount < 5) {
          _retryCount++;
          await Future.delayed(const Duration(seconds: 1));
          _checkUserProfile();
        } else {
          if (mounted) setState(() => _status = _UserDataStatus.error);
        }
      }
    } catch (e) {
      debugPrint("Profil kontrol hatası: $e");
      if (mounted) setState(() => _status = _UserDataStatus.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case _UserDataStatus.loading:
        return const Scaffold(body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Kahraman profili yükleniyor...", style: TextStyle(color: Colors.blueGrey)),
          ],
        )));

      case _UserDataStatus.error:
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  const Text("Bağlantı kurulamadı veya profil henüz hazır değil.", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _status = _UserDataStatus.loading;
                        _retryCount = 0;
                      });
                      _checkUserProfile();
                    },
                    child: const Text("YENİDEN DENE"),
                  ),
                  TextButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text("Giriş Sayfasına Dön")),
                ],
              ),
            ),
          ),
        );

      case _UserDataStatus.ready:
        return const AppInitializer();
    }
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  final NotificationService _notificationService = NotificationService();
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_started) return;
      _started = true;
      _notificationService.initialize();
      _updateLastSeen();
    });
  }

  Future<void> _updateLastSeen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'sonGorulme': FieldValue.serverTimestamp(), 'isOnline': true},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint("Son görülme güncellenemedi: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const AnaNavigation();
  }
}
