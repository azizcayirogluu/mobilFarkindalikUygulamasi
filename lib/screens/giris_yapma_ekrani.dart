import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
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

  Future<void> _girisYap() async {
    // Çift dokunma / eşzamanlı ikinci istek koruması.
    if (_isLoading) return;

    FocusScope.of(context).unfocus();
    final kullaniciAdi = _usernameController.text.trim().toLowerCase().replaceAll(' ', '');
    final pin = _pinController.text.trim();

    if (kullaniciAdi.isEmpty || pin.isEmpty) {
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
      final String deterministicEmail = '$kullaniciAdi@zorbalik.app';

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
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'sonGorulme': FieldValue.serverTimestamp(),
          'isOnline': true,
        }).timeout(const Duration(seconds: 8));
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
      _mesajGoster("Tekrar hoş geldin $kullaniciAdi! 🚀");
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
    final media = MediaQuery.of(context);
    final keyboardOpen = media.viewInsets.bottom > 0;

    // Alt sistem navigasyon barı (gesture vs 3-buton) için dinamik boşluk
    final bottomPadding = media.padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          final isShort = availableHeight < 600;

          return Stack(
            children: [
              // 1. DİNAMİK RENKLİ ARKA PLAN
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE0F7FA), Color(0xFFF3E5F5), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

              // 2. HAREKETLİ DEKORATİF OBJELER
              if (!keyboardOpen && !isShort) ...[
                Positioned(
                  top: -40,
                  right: -40,
                  child: _decorCircle(200, AppColors.anaMavi.withOpacity(.1))
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(begin: -15, end: 15, duration: 4.seconds),
                ),
                Positioned(
                  bottom: -60,
                  left: -50,
                  child: _decorCircle(220, AppColors.eglencePembesi.withOpacity(.08))
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveX(begin: -10, end: 10, duration: 5.seconds),
                ),
              ],

              // 3. İÇERİK
              // SafeArea bottom: false yapıldı ki ekranın altına tam oturan renkli bir his olsun,
              // ancak scrollable content'in altına inset eklendi ki içerik altında kalmasın.
              SafeArea(
                bottom: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600), // Tablet/iPad uyumluluğu
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 15),
                          _buildHeader(),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              // Sistemin alt çubuğuyla çakışmayı önleyen dinamik alt padding
                              padding: EdgeInsets.only(bottom: bottomPadding + 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (!keyboardOpen && !isShort) ...[
                                    const SizedBox(height: 10),
                                    _buildHeroSection(),
                                    const SizedBox(height: 25),
                                  ],
                                  _buildFormCard(keyboardOpen || isShort),
                                  const SizedBox(height: 20),
                                  _buildRegisterLink(keyboardOpen || isShort),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(backgroundColor: Colors.white, shadowColor: Colors.black12, elevation: 2),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.yaziRengi, size: 18),
        ),
        const Expanded(
          child: Text(
            "Giriş Yap",
            textAlign: TextAlign.center,
            maxLines: 1, // Büyük fontlarda header taşmasını engeller
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.yaziRengi, fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
        const SizedBox(width: 48), // İkon simetrisi için
      ],
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        Image.asset(
            "assets/image/team.png",
            height: 120,
            errorBuilder: (_, __, ___) => const Icon(Icons.group_rounded, size: 80, color: AppColors.anaMavi)
        ),
        const SizedBox(height: 15),
        const Text(
          "Tekrardan Merhaba! 👋",
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.yaziRengi, letterSpacing: -1),
        ),
        const SizedBox(height: 6),
        const Text(
          "Kaldığın yerden iyilik dolu bir dünya kurmaya hazır mısın?",
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.w500),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildFormCard(bool compact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: compact ? 16 : 32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98),
        borderRadius: BorderRadius.circular(45),
        boxShadow: [BoxShadow(color: AppColors.anaMavi.withOpacity(.1), blurRadius: 40, offset: const Offset(0, 15))],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInputField("Kullanıcı Adın", Icons.face_rounded, _usernameController, compact),
          SizedBox(height: compact ? 12 : 20),
          _buildInputField("Şifren veya PIN Kodun", Icons.lock_rounded, _pinController, compact, isPin: true),
          SizedBox(height: compact ? 20 : 32),
          _buildLoginButton(compact),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildInputField(String label, IconData icon, TextEditingController controller, bool compact, {bool isPin = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 8),
          child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.anaMavi, fontSize: 10, letterSpacing: 1.1)
          ),
        ),
        TextField(
          controller: controller,
          obscureText: isPin && !_showPin,
          keyboardType: TextInputType.text,
          maxLength: null,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: compact ? 14 : 16),
          decoration: InputDecoration(
            counterText: "",
            hintText: "$label...",
            prefixIcon: Icon(icon, color: AppColors.anaMavi, size: 20),
            suffixIcon: isPin ? IconButton(onPressed: () => setState(() => _showPin = !_showPin), icon: Icon(_showPin ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: Colors.grey.shade400)) : null,
            filled: true,
            fillColor: AppColors.anaMavi.withOpacity(0.04),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: AppColors.anaMavi, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(bool compact) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 55),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: AppColors.anaGradient,
        boxShadow: [BoxShadow(color: AppColors.anaMavi.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _girisYap,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, elevation: 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
              : const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "MACERAYA BAŞLA! 🚀",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink(bool compact) {
    return TextButton(
      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const KayitEkrani())),
      child: Text.rich(
        TextSpan(
          style: TextStyle(color: Colors.blueGrey, fontSize: compact ? 12 : 14, fontWeight: FontWeight.w700),
          children: const [
            TextSpan(text: 'Henüz kahraman değil misin? '),
            TextSpan(text: 'Kayıt Ol ✨', style: TextStyle(color: AppColors.anaMavi, fontWeight: FontWeight.w900)),
          ],
        ),
        textAlign: TextAlign.center, // Büyük fontlarda birden çok satıra düşerse ortalı dursun
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