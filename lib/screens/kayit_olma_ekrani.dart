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

  // ============================================================
  // KAYIT BAŞLAT
  // ============================================================

  Future<void> _kayitBaslat() async {
    FocusScope.of(context).unfocus();

    final username = _usernameController.text.trim().toLowerCase();
    final pin = _pinController.text.trim();

    if (username.isEmpty) {
      _showMessage('Önce kendine bir kahraman adı seç! 🦸', isError: true);
      return;
    }

    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(username)) {
      _showMessage(
        'Kullanıcı adı 3-20 karakter olmalı.\nHarf, rakam ve _ kullanabilirsin.',
        isError: true,
      );
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

  // ============================================================
  // YETİŞKİN DOĞRULAMASI
  // ============================================================

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
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Row(
            children: [
              const Icon(Icons.shield_rounded, color: AppColors.anaMavi, size: 28),
              const SizedBox(width: 10),
              Text('Yetişkin Doğrulaması', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade900)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '6-12 yaş grubu için bir ebeveyn veya öğretmenden yardım iste.',
                style: TextStyle(color: Color(0xFF686C7D), fontSize: 14, height: 1.45),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(color: const Color(0xFFF0EFFF), borderRadius: BorderRadius.circular(18)),
                child: Text(
                  '$number1 + $number2 = ?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.anaMavi, fontSize: 29, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: answerController,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Cevabı yaz',
                  filled: true,
                  fillColor: const Color(0xFFF6F7FB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('İptal')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.anaMavi),
              onPressed: () {
                final correct = answerController.text.trim() == correctAnswer.toString();
                Navigator.pop(dialogContext, correct);
              },
              child: const Text('Onayla'),
            ),
          ],
        );
      },
    );

    answerController.dispose();
    if (!mounted) return;

    if (result == true) {
      await _register();
    } else if (result == false) {
      _showMessage('Yetişkin doğrulaması başarısız oldu ❌', isError: true);
    }
  }

  // ============================================================
  // FIREBASE
  // ============================================================

  Future<void> _register() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();

    final username = _usernameController.text.trim().toLowerCase();
    final pin = _pinController.text.trim();
    final email = '$username@zorbalik.app';

    setState(() => _loading = true);

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pin);
      final user = credential.user;
      if (user == null) throw Exception('Firebase kullanıcı oluşturamadı.');

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      batch.set(
        firestore.collection('users').doc(user.uid),
        {
          'kullaniciAdi': username,
          'yasGrubu': seciliGrup,
          'avatarUrl': 'assets/image/boy.png',
          'isOnline': true,
          'emailAlias': email,
          'sonGorulme': FieldValue.serverTimestamp(),
          'consentMethod': seciliGrup == '6-12' ? 'adult_action_gate' : 'not_required',
        },
        SetOptions(merge: true),
      );

      batch.set(
        firestore.collection('usersProgress').doc(user.uid),
        {
          'kullaniciAdi': username,
          'sonGuncelleme': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      await user.updateDisplayName(username);

      if (!mounted) return;
      _showMessage('Hoş geldin $username! 🚀', isError: false);
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AnaNavigation()), (route) => false);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use': message = 'Bu kahraman adı zaten kullanılıyor 🚀'; break;
        case 'network-request-failed': message = 'İnternet bağlantını kontrol et 🌐'; break;
        case 'too-many-requests': message = 'Çok fazla deneme yapıldı.\nBiraz sonra tekrar dene 🛡️'; break;
        case 'weak-password': message = 'PIN kodun yeterince güvenli değil 🔐'; break;
        default: message = 'Kayıt sırasında bir sorun oluştu.\nLütfen tekrar dene.';
      }
      _showMessage(message, isError: true);
    } catch (e) {
      _showMessage('Beklenmeyen bir hata oluştu.\nLütfen tekrar dene 💪', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontWeight: FontWeight.w700)),
          backgroundColor: isError ? const Color(0xFFE85D75) : const Color(0xFF00A896),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardOpen = media.viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final isShort = availableHeight < 600;

            return Stack(
              children: [
                // 1. DİNAMİK RENKLİ ARKA PLAN
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE0F7FA), Color(0xFFF3E5F5), Color(0xFFFFF9C4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                
                // 2. HAREKETLİ DEKORATİF OBJELER
                if (!keyboardOpen && !isShort) ...[
                  Positioned(
                    top: -60,
                    right: -40,
                    child: _decorCircle(220, AppColors.anaMavi.withOpacity(.15))
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(begin: -25, end: 25, duration: 4.seconds)
                        .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
                  ),
                  Positioned(
                    bottom: -80,
                    left: -60,
                    child: _decorCircle(250, AppColors.eglencePembesi.withOpacity(.1))
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveX(begin: -20, end: 20, duration: 5.seconds),
                  ),
                  
                  // UÇUŞAN KAHRAMAN İKONLARI
                  _floatingHeroItem(Icons.auto_awesome_rounded, AppColors.oyunSarisi, top: 100, left: 30),
                  _floatingHeroItem(Icons.shield_rounded, AppColors.anaMavi, top: 250, right: 30),
                  _floatingHeroItem(Icons.favorite_rounded, AppColors.eglencePembesi, bottom: 200, left: 60),
                ],

                // 3. İÇERİK
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildHeader(compact: keyboardOpen || isShort),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (!keyboardOpen && !isShort) _buildHeroSection(keyboardOpen),
                            Flexible(child: _buildFormCard(keyboardOpen || isShort)),
                            _buildLoginButton(compact: keyboardOpen || isShort),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _floatingHeroItem(IconData icon, Color color, {double? top, double? bottom, double? left, double? right}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
        child: Icon(icon, color: color.withOpacity(0.6), size: 30),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .moveY(begin: -10, end: 10, duration: (2 + Random().nextInt(3)).seconds)
       .fadeIn(duration: 800.ms),
    );
  }

  Widget _buildHeroSection(bool keyboardOpen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Colors.white, AppColors.anaMavi.withOpacity(0.1)]),
                boxShadow: [BoxShadow(color: AppColors.anaMavi.withOpacity(0.2), blurRadius: 30)],
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 4.seconds),
            Image.asset(
              'assets/image/elEleKarsilama2.png',
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.handshake_rounded, color: AppColors.anaMavi, size: 60),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'KAHRAMAN KAYDI 🚀',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.yaziRengi, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1.2),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
      ],
    );
  }

  Widget _buildHeader({required bool compact}) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(backgroundColor: Colors.white, shadowColor: Colors.black12, elevation: 6),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.yaziRengi, size: 18),
        ),
        const Spacer(),
        if (!compact) _statusBadge('Yeni Üyelik', Icons.auto_awesome_rounded, AppColors.oyunSarisi),
      ],
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _statusBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(25), 
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)],
        border: Border.all(color: color.withOpacity(0.3))
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: AppColors.yaziRengi, fontSize: 12, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildFormCard(bool compact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: compact ? 12 : 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98),
        borderRadius: BorderRadius.circular(compact ? 35 : 45),
        boxShadow: [
          BoxShadow(color: AppColors.anaMavi.withOpacity(.1), blurRadius: 40, offset: const Offset(0, 15)),
        ],
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildInput(label: 'Kahraman Adın', hint: 'Örn: ali_kahraman', icon: Icons.face_rounded, controller: _usernameController, color: AppColors.anaMavi, compact: compact),
          SizedBox(height: compact ? 8 : 16),
          _buildInput(label: 'Gizli PIN (6 Rakam)', hint: '••••••', icon: Icons.lock_rounded, controller: _pinController, pin: true, color: AppColors.yumusakMor, compact: compact),
          SizedBox(height: compact ? 12 : 24),
          _buildAgeSelector(compact: compact),
          SizedBox(height: compact ? 8 : 20),
          _buildPrivacy(compact: compact),
          SizedBox(height: compact ? 12 : 24),
          _buildRegisterButton(compact: compact),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.98, 0.98), curve: Curves.fastOutSlowIn);
  }

  Widget _buildInput({required String label, required String hint, required IconData icon, required TextEditingController controller, required Color color, bool pin = false, required bool compact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 6),
          child: Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
        ),
        SizedBox(
          height: compact ? 45 : 55,
          child: TextField(
            controller: controller,
            obscureText: pin && !_showPin,
            keyboardType: pin ? TextInputType.number : TextInputType.text,
            maxLength: pin ? 6 : 20,
            style: TextStyle(color: AppColors.yaziRengi, fontSize: compact ? 14 : 16, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(icon, color: color, size: compact ? 18 : 22),
              suffixIcon: pin
                  ? IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _showPin = !_showPin),
                icon: Icon(_showPin ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: color.withOpacity(0.4), size: 18),
              )
                  : null,
              filled: true,
              fillColor: color.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: color, width: 2)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgeSelector({required bool compact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) const Padding(
          padding: EdgeInsets.only(left: 10, bottom: 8),
          child: Text('YAŞ GRUBUNU SEÇ 🎂', style: TextStyle(color: AppColors.yaziRengi, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ),
        Row(
          children: [
            _buildAgeCard(group: '6-12', title: '6 - 12 Yaş', icon: Icons.child_care_rounded, color: const Color(0xFF00A896), compact: compact),
            const SizedBox(width: 10),
            _buildAgeCard(group: '13-18', title: '13 - 18 Yaş', icon: Icons.person_rounded, color: const Color(0xFF6C63FF), compact: compact),
          ],
        ),
      ],
    );
  }

  Widget _buildAgeCard({required String group, required String title, required IconData icon, required Color color, required bool compact}) {
    final selected = seciliGrup == group;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => seciliGrup = group),
        child: AnimatedContainer(
          duration: 300.ms,
          padding: EdgeInsets.symmetric(vertical: compact ? 10 : 16),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: selected ? color : Colors.grey.shade200, width: 2),
            boxShadow: [
              if (selected) BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? Colors.white : color, size: compact ? 22 : 30),
              SizedBox(height: compact ? 2 : 6),
              Text(title, style: TextStyle(color: selected ? Colors.white : AppColors.yaziRengi, fontSize: compact ? 11 : 13, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacy({required bool compact}) {
    return GestureDetector(
      onTap: () => setState(() => _privacyAccepted = !_privacyAccepted),
      child: Container(
        padding: EdgeInsets.all(compact ? 8 : 12),
        decoration: BoxDecoration(color: AppColors.anaMavi.withOpacity(0.03), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.anaMavi.withOpacity(0.05))),
        child: Row(
          children: [
            Container(
              width: compact ? 20 : 24, height: compact ? 20 : 24,
              decoration: BoxDecoration(
                color: _privacyAccepted ? AppColors.basariYesili : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _privacyAccepted ? AppColors.basariYesili : Colors.grey.shade300, width: 2),
              ),
              child: _privacyAccepted ? Icon(Icons.check_rounded, color: Colors.white, size: compact ? 12 : 16) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GizlilikPolitikasiEkrani())),
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(color: Colors.blueGrey, fontSize: compact ? 8.5 : 10, fontWeight: FontWeight.w700, height: 1.4),
                    children: [
                      if (seciliGrup == '6-12') const TextSpan(text: 'Ebeveynimin gözetiminde '),
                      const TextSpan(text: 'Gizlilik Politikasını', style: TextStyle(color: AppColors.anaMavi, fontWeight: FontWeight.w900, decoration: TextDecoration.underline)),
                      const TextSpan(text: ' okudum ve kabul ediyorum.'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton({required bool compact}) {
    return Container(
      width: double.infinity,
      height: compact ? 50 : 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]),
        boxShadow: [
          BoxShadow(color: AppColors.anaMavi.withOpacity(.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: ElevatedButton(
        onPressed: _loading ? null : _kayitBaslat,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, elevation: 0),
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
            : Text('MACERAYA BAŞLA! 🚀', style: TextStyle(color: Colors.white, fontSize: compact ? 14 : 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(delay: 3.seconds, duration: 2.seconds);
  }

  Widget _buildLoginButton({required bool compact}) {
    return TextButton(
      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GirisEkrani())),
      child: Text.rich(
        TextSpan(
          style: TextStyle(color: Colors.blueGrey, fontSize: compact ? 12 : 14, fontWeight: FontWeight.w700),
          children: const [
            TextSpan(text: 'Zaten bir kahraman mısın? '),
            TextSpan(text: 'Giriş Yap', style: TextStyle(color: AppColors.anaMavi, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _decorCircle(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }
}
