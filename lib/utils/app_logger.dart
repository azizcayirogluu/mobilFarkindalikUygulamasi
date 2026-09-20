import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class AppLogger {
  // Sadece debug modda log yazar, release modda sessiz kalır.
  static void log(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('[LOG] $message');
      if (error != null) debugPrint('[ERROR] $error');
      if (stackTrace != null) debugPrint('[STACK] $stackTrace');
    }
  }

  // Kritik hataları loglamak için hem konsola hem Crashlytics'e gönderir
  static void error(String message, Object e, [StackTrace? s]) {
    if (kDebugMode) {
      debugPrint('❌ KRİTİK HATA: $message - $e');
      if (s != null) debugPrint(s.toString());
    }
    
    // Üretim ortamında hatayı takip etmek için Crashlytics'e gönderiyoruz
    FirebaseCrashlytics.instance.recordError(
      e, 
      s, 
      reason: message,
      fatal: false, // Uygulama çökmedi ama bir işlem başarısız oldu
    );
  }
}
