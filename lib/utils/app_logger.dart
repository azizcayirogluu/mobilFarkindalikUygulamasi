import 'package:flutter/foundation.dart';

class AppLogger {
  // Sadece debug modda log yazar, release modda sessiz kalır.
  static void log(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('[LOG] $message');
      if (error != null) debugPrint('[ERROR] $error');
      if (stackTrace != null) debugPrint('[STACK] $stackTrace');
    }
  }

  // Kritik hataları loglamak için (Release modda bile gerekirse - örn: Crashlytics entegrasyonu için)
  static void error(String message, Object e, [StackTrace? s]) {
    if (kDebugMode) {
      debugPrint('❌ KRİTİK HATA: $message - $e');
    }
    // Burada Firebase Crashlytics gibi araçlara gönderim yapılabilir:
    // FirebaseCrashlytics.instance.recordError(e, s, reason: message);
  }
}
