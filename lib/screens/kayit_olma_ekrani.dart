import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/ana_navigation_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/giris_yapma_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/gizlilik_politikasi_ekrani.dart';

class KayitEkrani extends StatefulWidget {
  const KayitEkrani({super.key});

  @override
  State<KayitEkrani> createState() => _KayitEkraniState();
}

class _KayitEkraniState extends State<KayitEkrani> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  String seciliGrup = '';
  bool _loading = false;
  bool _privacyAccepted = false;
  bool _showPin = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _kayitBaslat() async {
    FocusScope.of(context).unfocus();
    final username = _usernameController.text.trim().toLowerCase();
    final pin = _pinController.text.trim();

    if (username.isEmpty) {
      _showMessage('Önce kendine bir kahraman adı seç! 🦸', isError: true);
      return;
    }
    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(username)) {
      _showMessage('Kullanıcı adı 3-20 karakter olmalı.', isError: true);
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      _showMessage('PIN tam olarak 6 rakamdan oluşmalı 🔐', isError: true);
      return;
    }
    if (seciliGrup.isEmpty) {
      _showMessage('Yaş grubunu seçmeyi unutma 🎂', isError: true);
      return;
    }
    if (!_privacyAccepted) {
      _showMessage('Gizlilik Politikasını kabul etmelisin 📋', isError: true);
      return;
    }
    if (seciliGrup == '6-12') {
      await _showParentalGate();
      return;
    }
    await _register();
  }

  Future<void> _showParentalGate() async {
    final number1 = Random().nextInt(10) + 10;
    final number2 = Random().nextInt(10) + 5;
    final correctAnswer = number1 + number2;
    final answerController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text('Yetişkin Doğrulaması', style: TextStyle(fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('6-12 yaş grubu için bir büyüğünden yardım iste.', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 20),
              Text('$number1 + $number2 = ?', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF6366F1))),
              const SizedBox(height: 16),
              TextField(
                controller: answerController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Cevap',
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('İptal')),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, answerController.text.trim() == correctAnswer.toString()),
              child: const Text('Onayla'),
            ),
          ],
        );
      },
    );
    if (result == true) await _register();
  }

  Future<void> _register() async {
    if (_loading) return;
    setState(() => _loading = true);
    final username = _usernameController.text.trim().toLowerCase();
    final pin = _pinController.text.trim();
    final email = '$username@zorbalik.app';

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pin);
      final user = credential.user;
      if (user == null) throw Exception();

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      batch.set(firestore.collection('users').doc(user.uid), {
        'kullaniciAdi': username,
        'yasGrubu': seciliGrup,
        'avatarUrl': 'assets/image/boy.png',
        'isOnline': true,
        'sonGorulme': FieldValue.serverTimestamp(),
      });
      batch.set(firestore.collection('usersProgress').doc(user.uid), {
        'kullaniciAdi': username,
        'sonGuncelleme': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      await user.updateDisplayName(username);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AnaNavigation()), (route) => false);
    } catch (e) {
      _showMessage('Bir sorun oluştu, lütfen tekrar dene.', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardOpen = media.viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(top: -100, right: -100, child: _decorCircle(300, const Color(0xFFEEF2FF))),
            Column(
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
                        _buildLoginLink(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
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
              "Yeni Kahraman Kaydı",
              textAlign: TextAlign.center,
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
          decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.rocket_launch_rounded, size: 40, color: Color(0xFF6366F1)),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 16),
        const Text("Maceraya Hazır Mısın?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        const SizedBox(height: 8),
        const Text("Kendi kahramanını oluştur ve iyilik yolculuğuna başla!", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        children: [
          _buildInput("Kullanıcı Adın", Icons.face_rounded, _usernameController, false),
          const SizedBox(height: 20),
          _buildInput("6 Haneli PIN", Icons.lock_rounded, _pinController, true),
          const SizedBox(height: 24),
          _buildAgeSelector(),
          const SizedBox(height: 24),
          _buildPrivacyToggle(),
          const SizedBox(height: 30),
          _buildRegisterButton(),
        ],
      ),
    );
  }

  Widget _buildInput(String label, IconData icon, TextEditingController controller, bool isPin) {
    return TextField(
      controller: controller,
      obscureText: isPin && !_showPin,
      keyboardType: isPin ? TextInputType.number : TextInputType.text,
      maxLength: isPin ? 6 : 20,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        counterText: "",
        suffixIcon: isPin ? IconButton(icon: Icon(_showPin ? Icons.visibility_off : Icons.visibility, size: 18), onPressed: () => setState(() => _showPin = !_showPin)) : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
      ),
    );
  }

  Widget _buildAgeSelector() {
    return Row(
      children: [
        _ageButton('6-12', '6-12 Yaş', Icons.child_care_rounded, const Color(0xFF10B981)),
        const SizedBox(width: 12),
        _ageButton('13-18', '13-18 Yaş', Icons.person_rounded, const Color(0xFF6366F1)),
      ],
    );
  }

  Widget _ageButton(String val, String label, IconData icon, Color color) {
    bool isSel = seciliGrup == val;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => seciliGrup = val),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSel ? color : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSel ? color : const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSel ? Colors.white : color, size: 24),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: isSel ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyToggle() {
    return InkWell(
      onTap: () => setState(() => _privacyAccepted = !_privacyAccepted),
      child: Row(
        children: [
          Checkbox(value: _privacyAccepted, onChanged: (v) => setState(() => _privacyAccepted = v!), activeColor: const Color(0xFF6366F1)),
          const Expanded(child: Text("Gizlilik Politikasını okudum ve kabul ediyorum.", style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _loading ? null : _kayitBaslat,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("KAYIT OL VE BAŞLA 🚀", style: TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _buildLoginLink() {
    return TextButton(
      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GirisEkrani())),
      child: const Text("Zaten bir hesabın var mı? Giriş Yap", style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
    );
  }

  Widget _decorCircle(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }
}
