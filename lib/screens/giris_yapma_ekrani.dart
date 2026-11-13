import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zorbalik_uygulamasi/screens/kayit_olma_ekrani.dart';
import 'package:zorbalik_uygulamasi/services/storage_service.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  bool _showPin = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkRateLimit() async {
    final lockoutMs = StorageService().getLockoutUntil();
    if (lockoutMs > DateTime.now().millisecondsSinceEpoch) {
      final int remainingSeconds = ((lockoutMs - DateTime.now().millisecondsSinceEpoch) / 1000).round();
      final int min = remainingSeconds ~/ 60;
      final int sec = remainingSeconds % 60;
      throw _GirisHatasi("Çok fazla hatalı deneme! Lütfen $min dakika $sec saniye bekle. ⏳");
    }
  }

  Future<void> _recordFailedAttempt() async {
    int attempts = StorageService().getFailedAttempts() + 1;
    if (attempts >= 3) {
      await StorageService().setLockoutUntil(DateTime.now().millisecondsSinceEpoch + 300000);
      await StorageService().setFailedAttempts(0);
      _mesajGoster("Güvenliğin için hesabın 5 dakikalığına kilitlendi! 🚨", isError: true);
    } else {
      await StorageService().setFailedAttempts(attempts);
      _mesajGoster("Yanlış PIN! Kalan deneme hakkı: ${3 - attempts} 🔐", isError: true);
    }
  }

  void _log(String message) {
    // PIN, e-posta, token vb. hassas veri asla loglanmaz.
    if (kDebugMode) debugPrint('[GIRIS] $message');
  }

  String _toCanonicalEmail(String rawUsername) {
    String text = rawUsername.trim().toLowerCase();
    text = text
        .replaceAll('i̇', 'i')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'\s+'), '');
    return '$text@zorbalik.app';
  }

  Future<void> _girisYap() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();
    final rawUsername = _usernameController.text.trim();
    final pin = _pinController.text.trim();

    if (rawUsername.isEmpty || pin.isEmpty) {
      _mesajGoster("Kullanıcı adını ve şifreni/PIN kodunu yazmayı unutma! 😊", isError: true);
      return;
    }

    if (pin.length < 6) {
      _mesajGoster("Şifren veya PIN kodun en az 6 karakter olmalıdır. 🔐", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    _log('LOGIN START');

    try {
      await _checkRateLimit();
      final String deterministicEmail = _toCanonicalEmail(rawUsername);

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: deterministicEmail, password: pin)
          .timeout(const Duration(seconds: 30));
      _log('AUTH SUCCESS');

      // Auth oturumunun gerçekten oluştuğunu doğrula; yoksa hiçbir şey yapma.
      final User? user = userCredential.user ?? FirebaseAuth.instance.currentUser;
      if (user == null || FirebaseAuth.instance.currentUser == null) {
        _log('CURRENT USER: null');
        throw _GirisHatasi("Giriş tamamlanamadı. Lütfen tekrar dene. 💪");
      }
      _log('CURRENT USER: set');

      // Bu iki adım "son görülme" / güvenlik sayacı temizliğidir; Auth oturumu
      // zaten açık. Başarısız olsa bile girişi bozmaz, kullanıcı takılı kalmaz
      // ve oturum kapatılmaz. (Firestore update sunucu onayını beklediği için
      // zaman aşımı konuldu.)
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'sonGorulme': FieldValue.serverTimestamp(),
          'isOnline': true,
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 8));
        _log('FIRESTORE UPDATE SUCCESS');
      } catch (e) {
        _log('FIRESTORE UPDATE FAILED (giriş devam ediyor): ${e.runtimeType}');
      }

      try {
        await StorageService().clearLoginSecurityData();
      } catch (e) {
        _log('CLEAR LOGIN SECURITY DATA FAILED: ${e.runtimeType}');
      }

      if (!mounted) return;
      _mesajGoster("Tekrar hoş geldin $rawUsername! 🚀");
      // Ekran kararı AuthGate'indir (authStateChanges -> UserDataGate -> ...).
      // GirisEkrani, AuthGate'in üstüne push edilmiş bir route olduğu için
      // AuthGate onu kendisi kapatamaz; burada yalnızca bu ekranı stack'ten çıkarıyoruz.
      Navigator.of(context).popUntil((route) => route.isFirst);
      _log('LOGIN FLOW COMPLETE');
    } on FirebaseAuthException catch (e) {
      _log('AUTH ERROR: ${e.code}');
      if (e.code == 'wrong-password' || e.code == 'invalid-credential' || e.code == 'user-not-found') {
        try {
          await _recordFailedAttempt();
        } catch (_) {
          _mesajGoster("Kullanıcı adın veya PIN kodun yanlış. 🔐", isError: true);
        }
      } else if (e.code == 'network-request-failed') {
        _mesajGoster("İnternet bağlantını kontrol edip tekrar dene. 📶", isError: true);
      } else if (e.code == 'too-many-requests') {
        _mesajGoster("Çok fazla deneme yapıldı. Biraz bekleyip tekrar dene. ⏳", isError: true);
      } else if (e.code == 'user-disabled') {
        _mesajGoster("Bu hesap şu an kullanılamıyor. 🚫", isError: true);
      } else {
        _mesajGoster("Giriş sırasında bir sorun oluştu. Lütfen tekrar dene. 💪", isError: true);
      }
    } on TimeoutException {
      _log('TIMEOUT');
      _mesajGoster("Bağlantı çok yavaş. İnternetini kontrol edip tekrar dene. 📶", isError: true);
    } on _GirisHatasi catch (e) {
      _mesajGoster(e.mesaj, isError: true);
    } catch (e) {
      _log('UNEXPECTED ERROR: ${e.runtimeType}');
      _mesajGoster("Giriş sırasında bir sorun oluştu. Lütfen tekrar dene. 💪", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mesajGoster(String mesaj, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? const Color(0xFFE85D75) : const Color(0xFF00A896),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(top: -100, right: -100, child: _decorCircle(300, const Color(0xFFEEF2FF))),
            Positioned(bottom: -120, left: -120, child: _decorCircle(280, const Color(0xFFE0F2FE).withValues(alpha: 0.7))),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            if (!keyboardOpen) ...[
                              const SizedBox(height: 20),
                              _buildHeroSection(),
                              const SizedBox(height: 30),
                            ],
                            _buildFormCard(),
                            const SizedBox(height: 20),
                            _buildRegisterLink(),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF475569)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Expanded(
            child: Text(
              "Kahraman Girişi",
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B)),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Image.asset(
            "assets/image/app_icon_two.png",
            height: 120,
            errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.shield_rounded, size: 80, color: Color(0xFF6366F1)),
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 16),
        const Text(
          "Tekrar Hoş Geldin!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        const Text(
          "Kaldığın yerden kahramanlık yolculuğuna devam et!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        children: [
          _buildInput("Kullanıcı Adın", Icons.face_rounded, _usernameController, isPin: false),
          const SizedBox(height: 20),
          _buildInput("Şifren veya PIN Kodun", Icons.lock_rounded, _pinController, isPin: true),
          const SizedBox(height: 30),
          _buildLoginButton(),
        ],
      ),
    );
  }

  Widget _buildInput(String label, IconData icon, TextEditingController controller, {required bool isPin}) {
    return TextField(
      controller: controller,
      obscureText: isPin && !_showPin,
      keyboardType: TextInputType.text,
      textInputAction: isPin ? TextInputAction.done : TextInputAction.next,
      onSubmitted: isPin ? (_) => _girisYap() : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: isPin
            ? IconButton(
          icon: Icon(_showPin ? Icons.visibility_off : Icons.visibility, size: 18),
          onPressed: () => setState(() => _showPin = !_showPin),
        )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _girisYap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text("GİRİŞ YAP 🚀", style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return TextButton(
      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const KayitEkrani())),
      child: const Text(
        "Henüz kahraman değil misin? Kayıt Ol",
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _decorCircle(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }
}

/// Kullanıcıya olduğu gibi gösterilmesi güvenli, bu ekranın kendi hata mesajı.
class _GirisHatasi implements Exception {
  _GirisHatasi(this.mesaj);
  final String mesaj;
}