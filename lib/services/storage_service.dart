import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kahraman Dostum uygulaması için veri saklama servisi.
/// Hassas verileri (token vb.) Secure Storage'da,
/// Diğer ayarları SharedPreferences'da tutar.
class StorageService {
  static final StorageService _instance = StorageService._internal();

  factory StorageService() => _instance;

  StorageService._internal();

  /// flutter_secure_storage 11.2.0 API'si ile uyumlu yapılandırma.
  /// encryptedSharedPreferences kaldırılmıştır.
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _migrateIfNecessary();
  }

  // --- HASSAS VERİLER (Secure Storage) ---

  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  // --- HASSAS OLMAYAN VERİLER (SharedPreferences) ---

  Future<void> setFirstRunComplete() async {
    await _prefs.setBool('is_first_run', false);
  }

  bool isFirstRun() {
    return _prefs.getBool('is_first_run') ?? true;
  }

  // --- MIGRATION ---

  Future<void> _migrateIfNecessary() async {
    if (_prefs.containsKey('temp_user_data')) {
      final oldData = _prefs.getString('temp_user_data');
      if (oldData != null) {
        await _secureStorage.write(key: 'user_data', value: oldData);
        await _prefs.remove('temp_user_data');
      }
    }
  }

  // --- GÜVENLİK (Rate Limiting vb.) ---

  Future<void> setLockoutUntil(int timestamp) async {
    await _prefs.setInt('lockout_until', timestamp);
  }

  int getLockoutUntil() {
    return _prefs.getInt('lockout_until') ?? 0;
  }

  Future<void> setFailedAttempts(int attempts) async {
    await _prefs.setInt('failed_attempts', attempts);
  }

  int getFailedAttempts() {
    return _prefs.getInt('failed_attempts') ?? 0;
  }

  Future<void> clearLoginSecurityData() async {
    await _prefs.remove('failed_attempts');
    await _prefs.remove('lockout_until');
  }

  // --- MESAJ HAKKI / ENERJİ SİSTEMİ ---

  int getRemainingMessages() {
    return _prefs.getInt('chat_limit') ?? 10;
  }

  Future<void> useMessage() async {
    int current = getRemainingMessages();
    if (current > 0) {
      await _prefs.setInt('chat_limit', current - 1);
    }
  }

  Future<void> addRewardedMessages(int count) async {
    int current = getRemainingMessages();
    await _prefs.setInt('chat_limit', current + count);
  }

  Future<void> clearUserData() async {
    await _secureStorage.delete(key: 'auth_token');
    await _prefs.remove('chat_limit');
    await clearLoginSecurityData();
  }

  // Standart API desteği için ek metodlar
  Future<void> delete(String key) async => await _secureStorage.delete(key: key);
  Future<void> deleteAll() async => await _secureStorage.deleteAll();
  Future<bool> containsKey(String key) async => await _secureStorage.containsKey(key: key);
}
