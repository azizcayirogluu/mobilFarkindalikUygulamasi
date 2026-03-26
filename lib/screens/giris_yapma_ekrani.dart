import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/ana_navigation_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/kayit_olma_ekrani.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;

  void _girisYap() async {
    final kullaniciAdi = _usernameController.text.trim().toLowerCase();
    final pin = _pinController.text.trim();

    if (kullaniciAdi.isEmpty || pin.isEmpty) {
      _mesajGoster("Lütfen kullanıcı adını ve PIN kodunu yaz canım! 😊", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String fakeEmail = "$kullaniciAdi@zorbalik.app";

      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: fakeEmail,
        password: pin,
      );

      await userCredential.user!.updateDisplayName(kullaniciAdi);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AnaNavigation()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _mesajGoster("Böyle bir kahraman bulamadık! Önce kayıt olmalısın. 😊", isError: true);
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _mesajGoster("Hatalı PIN kodu! Tekrar dene. 🔐", isError: true);
      } else {
        _mesajGoster("Giriş Hatası: ${e.message}", isError: true);
      }
    } catch (e) {
      _mesajGoster("Giriş yapılamadı. İnternetini kontrol et!", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mesajGoster(String mesaj, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mesaj, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: isError ? Colors.redAccent : AppColors.accentMavi,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.zemin,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              Align(alignment: Alignment.centerLeft, child: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Navigator.pop(context))),
              const SizedBox(height: 20),
              Hero(tag: 'welcome_image', child: Image.asset("assets/boy.png", height: 120, errorBuilder: (c,e,s) => const Icon(Icons.person, size: 100))),
              const SizedBox(height: 20),
              const Text("Tekrardan Merhaba! 👋", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.yaziRengi)),
              const SizedBox(height: 40),
              _buildGirisKarti(),
              const SizedBox(height: 20),
              _buildRegisterLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGirisKarti() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(35), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)]),
      child: Column(
        children: [
          _buildInputField("Kullanıcı Adın", Icons.person_rounded, _usernameController),
          const SizedBox(height: 20),
          _buildInputField("6 Haneli PIN", Icons.lock_rounded, _pinController, isPin: true),
          const SizedBox(height: 30),
          _isLoading ? const CircularProgressIndicator() : _buildLoginButton(),
        ],
      ),
    );
  }

  Widget _buildInputField(String hint, IconData icon, TextEditingController controller, {bool isPin = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("  $hint", style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.blueGrey, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPin,
          keyboardType: isPin ? TextInputType.number : TextInputType.text,
          maxLength: isPin ? 6 : null,
          decoration: InputDecoration(
            counterText: "",
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.accentMavi),
            filled: true,
            fillColor: AppColors.zemin,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.accentMavi, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity, height: 60,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: AppColors.anaGradient),
      child: ElevatedButton(
        onPressed: _girisYap,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        child: const Text("MACERAYA BAŞLA 🚀", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Henüz hesabın yok mu?", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600)),
        TextButton(
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const KayitEkrani())),
          child: const Text("Hesap Oluştur", style: TextStyle(color: AppColors.anaMavi, fontWeight: FontWeight.w900, fontSize: 15)),
        ),
      ],
    );
  }
}
