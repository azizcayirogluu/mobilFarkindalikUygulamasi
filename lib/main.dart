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
import 'package:flutter/foundation.dart'; // kIsWeb için eklendi
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
    
    // 2. Diğer servisleri başlat
    await di.init();
    await StorageService().init();

    // 3. AdMob sadece mobil cihazlarda başlatılır (Web'de hata vermemesi için)
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

/// App Check is enabled only on the supported store targets. Web/desktop need
/// their own provider registration before enforcement can safely be enabled.
Future<void> _activateAppCheck() async {
  if (kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS)) {
    return;
  }

  await FirebaseAppCheck.instance.activate(
    androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode
        ? AppleProvider.debug
        : AppleProvider.appAttestWithDeviceCheckFallback,
  );
}

void _applyPostInitSettings() {
  // Görüntü önbelleğini optimize et
  PaintingBinding.instance.imageCache.maximumSizeBytes = 20 * 1024 * 1024;

  // Firestore ayarlarını güvenli bir şekilde uygula
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 100 * 1024 * 1024, // Sınırlandırıldı: 100MB (Cihaz dostu)
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
                const Text(
                  "Bağlantı Sorunu! 📡",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Kahramanlık profilini hazırlayamadık.\nİnternetini kontrol edip uygulamayı\nyeniden açar mısın?",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blueGrey, height: 1.5),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => main(), // Tekrar deneme butonu
                  child: const Text("TEKRAR DENE"),
                )
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
      title: 'Kahraman Dostum', // İsim güncellendi
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
        return const HomePages();
      },
    );
  }
}

enum _UserDataStatus { loading, recovering, ready, error }

class UserDataGate extends StatefulWidget {
  final String uid;
  const UserDataGate({super.key, required this.uid});

  @override
  State<UserDataGate> createState() => _UserDataGateState();
}

class _UserDataGateState extends State<UserDataGate> {
  _UserDataStatus _status = _UserDataStatus.loading;

  @override
  void initState() {
    super.initState();
    _checkUserProfile();
  }

  Future<void> _checkUserProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get(const GetOptions(source: Source.serverAndCache)) // Önce cache'e bak (Hız!)
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (doc.exists) {
        setState(() => _status = _UserDataStatus.ready);
      } else {
        await _recoverProfile(user);
      }
    } catch (e) {
      debugPrint("Profil kontrol hatası: $e");
      if (mounted) setState(() => _status = _UserDataStatus.error);
    }
  }

  Future<void> _recoverProfile(User user) async {
    if (!mounted) return;
    setState(() => _status = _UserDataStatus.recovering);

    try {
      final String email = user.email ?? "";
      final String username = email.contains('@') ? email.split('@')[0] : "Kahraman";

      final batch = FirebaseFirestore.instance.batch();
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final progressRef = FirebaseFirestore.instance.collection('usersProgress').doc(user.uid);

      batch.set(userRef, {
        'uid': user.uid,
        'kullaniciAdi': username,
        'yasGrubu': '6-12',
        'isAdmin': false,
        'isOnline': true,
        'emailAlias': email,
        'sonGorulme': FieldValue.serverTimestamp(),
        'kayitTarihi': FieldValue.serverTimestamp(),
      });

      batch.set(progressRef, {
        'uid': user.uid,
        'kullaniciAdi': username,
        'tamamlanan_bolumler': [],
        'okunan_hikayeler': [],
        'rozetler': [],
        'toplam_puan': 0,
        'sonGuncelleme': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      await user.updateDisplayName(username);

      if (mounted) setState(() => _status = _UserDataStatus.ready);
    } catch (e) {
      debugPrint("Profil kurtarma hatası: $e");
      await FirebaseAuth.instance.signOut();
      if (mounted) setState(() => _status = _UserDataStatus.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case _UserDataStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));

      case _UserDataStatus.recovering:
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 15),
                Text(
                  "Profilin kurtarılıyor, lütfen bekle...",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
              ],
            ),
          ),
        );

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
                  const Text(
                    "Bağlantı kurulamadı. Lütfen internetini kontrol et.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _status = _UserDataStatus.loading);
                      _checkUserProfile();
                    },
                    child: const Text("YENİDEN DENE"),
                  ),
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
        {'sonGorulme': FieldValue.serverTimestamp()},
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
