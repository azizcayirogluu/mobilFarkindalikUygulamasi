import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();

  factory StorageService() => _instance;

  StorageService._internal();

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
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

  // --- MIGRATION (Eski verileri temizle) ---
  Future<void> _migrateIfNecessary() async {
    // Örnek: Eskiden şifresiz tutulan bir veri varsa onu al, secure'a taşı ve eskiyi sil.
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
    return _prefs.getInt('chat_limit') ?? 10; // Tekrar 10'a çıkardım
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
}
