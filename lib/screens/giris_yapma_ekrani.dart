import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/ana_navigation_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/kayit_olma_ekrani.dart';
import 'package:zorbalik_uygulamasi/services/storage_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;

  Future<void> _checkRateLimit() async {
    final lockoutMs = StorageService().getLockoutUntil();
    if (lockoutMs > DateTime.now().millisecondsSinceEpoch) {
      final int remainingSeconds = ((lockoutMs - DateTime.now().millisecondsSinceEpoch) / 1000).round();
      final int min = remainingSeconds ~/ 60;
      final int sec = remainingSeconds % 60;
      throw Exception("Çok fazla hatalı deneme! Lütfen $min dakika $sec saniye bekle. ⏳");
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

  Future<void> _resetFailedAttempts() async {
    await StorageService().clearLoginSecurityData();
  }

  void _girisYap() async {
    final kullaniciAdi = _usernameController.text.trim().toLowerCase();
    final pin = _pinController.text.trim();

    if (kullaniciAdi.isEmpty || pin.isEmpty) {
      _mesajGoster(
        "Lütfen kullanıcı adını ve PIN kodunu yaz canım! 😊",
        isError: true,
      );
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      _mesajGoster(
        "PIN kodu 6 rakamdan oluşmalı. Örneğin 123456.",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _checkRateLimit();

      final String deterministicEmail = '$kullaniciAdi@zorbalik.app';

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: deterministicEmail, password: pin);

      try {
        await userCredential.user?.updateDisplayName(kullaniciAdi);
      } catch (e) {
        debugPrint("Profil adı güncellenirken hata: $e");
      }

      await _resetFailedAttempts();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AnaNavigation()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String mesaj = "Giriş yapılamadı kahraman! ✨";
      switch (e.code) {
        case 'user-not-found':
          mesaj = "Böyle bir kullanıcı henüz kayıtlarda yok! Önce kayıt olmalısın. 😊";
          break;
        case 'wrong-password':
        case 'invalid-credential':
          await _recordFailedAttempt();
          return;
        case 'network-request-failed':
          mesaj = "İnternet sinyalin biraz zayıf gibi, bağlantını kontrol eder misin? 🌐";
          break;
        case 'too-many-requests':
          mesaj = "Çok fazla deneme yaptın! Güvenlik için biraz bekle. 🛡️";
          break;
        default:
          mesaj = "Küçük bir aksilik oldu ama biz kahramanız, pes etmeyiz! Tekrar dene. 💪";
      }
      _mesajGoster(mesaj, isError: true);
    } catch (e) {
      debugPrint("Giriş hatası: $e");
      final errorMessage = e.toString().contains("Exception:")
          ? e.toString().replaceAll("Exception: ", "")
          : (e is FirebaseAuthException
          ? _firebaseAuthErrorMessage(e)
          : "Beklenmedik bir hata oluştu. Lütfen tekrar dene.");
      _mesajGoster(errorMessage, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _firebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "Böyle bir kullanıcı henüz kayıtlarda yok! Önce kayıt olmalısın. 😊";
      case 'wrong-password':
      case 'invalid-credential':
        return "Girdiğin PIN kodu yanlış! Lütfen tekrar dene. 🔐";
      case 'network-request-failed':
        return "İnternet sinyalin biraz zayıf gibi, bağlantını kontrol eder misin? 🌐";
      case 'too-many-requests':
        return "Çok fazla deneme yaptın! Güvenlik için biraz bekle. 🛡️";
      case 'user-disabled':
        return "Hesabın devre dışı bırakılmış. Destek ile iletişime geç.";
      default:
        return "Küçük bir aksilik oldu ama biz kahramanız, pes etmeyiz! Tekrar dene. 💪";
    }
  }

  void _mesajGoster(String mesaj, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mesaj,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        elevation: 10,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const Color backgroundSubtle = Color(0xFFF0F9FF);

    return Scaffold(
      backgroundColor: backgroundSubtle,
      body: Stack(
        children: [
          // Arka plan sevimli baloncuk süslemeleri
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.anaMavi.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -30,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: Colors.orange.withOpacity(0.04),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Geri Dönüş Butonu
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF334155)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Hero(
                      tag: 'welcome_image',
                      child: Image.asset(
                        "assets/team.png",
                        height: 140,
                        errorBuilder: (c, e, s) => Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.group_rounded, size: 80, color: AppColors.anaMavi),
                        ),
                      ),
                    ).animate().scale(delay: 100.ms, duration: 500.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 15),

                    Text(
                      "Tekrardan Merhaba! 👋",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.8,
                        fontFamily: 'CarterOne',
                        shadows: [
                          Shadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, 2), blurRadius: 2),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Kaldığın yerden iyilik ve nezaket dolu bir dünya kurmaya hazır mısın?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 35),

                    _buildGirisKarti(),
                    const SizedBox(height: 25),

                    // Kayıt Olma Linki
                    _buildRegisterLink().animate().fadeIn(delay: 400.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGirisKarti() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(38),
        boxShadow: [
          BoxShadow(
            color: AppColors.anaMavi.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInputField(
            "Kullanıcı Adın",
            Icons.person_pin_rounded,
            _usernameController,
          ),
          const SizedBox(height: 20),
          _buildInputField(
            "6 Haneli Gizli PIN",
            Icons.lock_open_rounded,
            _pinController,
            isPin: true,
          ),
          const SizedBox(height: 28),
          _isLoading
              ? const SizedBox(
              height: 55,
              child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.anaMavi)))
          )
              : _buildLoginButton(),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, curve: Curves.easeOutBack);
  }

  Widget _buildInputField(
      String hint,
      IconData icon,
      TextEditingController controller, {
        bool isPin = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 8),
            Icon(icon, size: 16, color: AppColors.anaMavi.withOpacity(0.7)),
            const SizedBox(width: 6),
            Text(
              hint,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF475569),
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPin,
          keyboardType: isPin ? TextInputType.number : TextInputType.text,
          maxLength: isPin ? 6 : null,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            counterText: "",
            hintText: "$hint girin...",
            hintStyle: TextStyle(color: Colors.blueGrey.shade200, fontSize: 14, fontWeight: FontWeight.w500),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide(color: Colors.blueGrey.shade50, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(
                color: AppColors.anaMavi,
                width: 2.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [AppColors.anaMavi, const Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.anaMavi.withOpacity(0.35),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _girisYap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "MACERAYA BAŞLA",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blueGrey.shade50)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Yeni misin?",
            style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 13),
          ),
          TextButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const KayitEkrani()),
            ),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: const Text(
              "Hemen Hesap Oluştur ✨",
              style: TextStyle(
                color: AppColors.anaMavi,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}