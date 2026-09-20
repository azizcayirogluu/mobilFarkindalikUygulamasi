import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/karsilama_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/ana_navigation_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/onboarding_ekrani.dart';
import 'package:zorbalik_uygulamasi/services/storage_service.dart';
import 'package:zorbalik_uygulamasi/services/notification_service.dart';
import 'injection_container.dart' as di;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Crashlytics Yapılandırması
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    await _activateAppCheck();
    await di.init();
    await StorageService().init();

    if (!kIsWeb) {
      try {
        unawaited(MobileAds.instance.initialize().then((_) {
          MobileAds.instance.updateRequestConfiguration(
            RequestConfiguration(
              tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
              maxAdContentRating: MaxAdContentRating.g,
            ),
          );
        }));
      } catch (e, stack) {
        debugPrint("AdMob Init Error: $e");
        FirebaseCrashlytics.instance.recordError(e, stack, reason: 'AdMob Initialization Failed');
      }
    }

    _applyPostInitSettings();

    final bool isFirstRun = StorageService().isFirstRun();
    runApp(MyApp(isFirstRun: isFirstRun));
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

Future<void> _activateAppCheck() async {
  if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
    return;
  }
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode ? AndroidDebugProvider() : AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode ? AppleDebugProvider() : AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  } catch (e, stack) {
    debugPrint("App Check Activation Error: $e");
    FirebaseCrashlytics.instance.recordError(e, stack, reason: 'App Check Activation Failed');
  }
}

void _applyPostInitSettings() {
  PaintingBinding.instance.imageCache.maximumSizeBytes = 30 * 1024 * 1024;
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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
        if (snapshot.hasData && snapshot.data != null) {
          return UserDataGate(uid: snapshot.data!.uid);
        }
        return const KarsilamaEkrani();
      },
    );
  }
}

/// UserDataGate: Kullanıcı profili oluşana kadar bekleyen ve veri senkronizasyonu sağlayan katman.
class UserDataGate extends StatelessWidget {
  final String uid;
  const UserDataGate({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorView(onRetry: () => FirebaseAuth.instance.signOut());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingView(message: "Kahraman profili yükleniyor...");
        }

        final doc = snapshot.data;
        if (doc != null && doc.exists) {
          return const AppInitializer();
        }

        // Profil henüz oluşmamış (örneğin Cloud Function çalışıyor)
        return const _LoadingView(message: "Kahramanlık hazırlıkları yapılıyor...");
      },
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _onAppStarted();
  }

  void _onAppStarted() {
    final notificationService = NotificationService();
    notificationService.initialize();
    _updateUserActivity();
  }

  Future<void> _updateUserActivity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'sonGorulme': FieldValue.serverTimestamp(),
        'isOnline': true,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => const AnaNavigation();
}

class _LoadingView extends StatelessWidget {
  final String message;
  const _LoadingView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(message, style: const TextStyle(color: Colors.blueGrey)),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text("Bağlantı Sorunu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              const Text("Profiline ulaşılamadı. Lütfen internetini kontrol et.", textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onRetry, child: const Text("TEKRAR DENE")),
            ],
          ),
        ),
      ),
    );
  }
}
