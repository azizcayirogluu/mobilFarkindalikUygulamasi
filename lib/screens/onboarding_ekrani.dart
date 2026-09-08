import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/karsilama_ekrani.dart';
import 'package:zorbalik_uygulamasi/services/storage_service.dart';

class OnboardingEkrani extends StatefulWidget {
  const OnboardingEkrani({super.key});

  @override
  State<OnboardingEkrani> createState() => _OnboardingEkraniState();
}

class _OnboardingEkraniState extends State<OnboardingEkrani>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _floatingController;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Maceran Başlıyor! 🚀',
      desc: 'Merhaba Kahraman! Ben senin dijital yol arkadaşınım. Birlikte zorbalığı tanıyacak ve daha güçlü olmayı öğreneceğiz.',
      image: 'assets/image/robot.png',
      icon: Icons.smart_toy_rounded,
      accent: Color(0xFF6C63FF),
      lightAccent: Color(0xFFEDEBFF),
      badge: 'DİJİTAL DOST',
    ),
    OnboardingData(
      title: 'Yalnız Değilsin! 🛡️',
      desc: 'Canını sıkan bir şey olduğunda bunu tek başına taşımak zorunda değilsin. Güvendiğin birinden destek almak güçtür.',
      image: 'assets/image/güclü-cocuklar2.jpg',
      icon: Icons.shield_rounded,
      accent: Color(0xFF00A896),
      lightAccent: Color(0xFFE1F8F4),
      badge: 'GÜVENLİ ALAN',
    ),
    OnboardingData(
      title: 'Keşfet, Kazan, Büyü! 🏆',
      desc: 'Görevleri tamamla ve rozetlerini toplamaya başla. Her küçük adım seni daha güçlü bir kahraman yapar!',
      image: 'assets/image/rozet.png',
      icon: Icons.emoji_events_rounded,
      accent: Color(0xFFFF8A3D),
      lightAccent: Color(0xFFFFF0E5),
      badge: 'YENİ MACERA',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    HapticFeedback.heavyImpact();
    await StorageService().setFirstRunComplete();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const KarsilamaEkrani(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: 600.ms, curve: Curves.easeOutCubic);
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      body: Stack(
        children: [
          // 1. DİNAMİK ARKA PLAN (DİĞER EKRANLARLA UYUMLU)
          AnimatedContainer(
            duration: 500.ms,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFE0F7FA),
                  page.lightAccent,
                  Colors.white,
                ],
              ),
            ),
          ),

          // 2. HAREKETLİ DEKORASYONLAR
          _buildDecorations(page),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, i) => _buildPage(_pages[i]),
                  ),
                ),
                _buildBottomControls(page),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorations(OnboardingData page) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -100, right: -60,
            child: _circle(240, page.accent.withOpacity(0.08))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: -20, end: 20, duration: 4.seconds),
          ),
          Positioned(
            bottom: -80, left: -60,
            child: _circle(260, page.accent.withOpacity(0.06))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveX(begin: -15, end: 15, duration: 5.seconds),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(Icons.shield_rounded, color: AppColors.anaMavi, size: 24),
          const SizedBox(width: 8),
          const Text('KAHRAMAN DOSTUM', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
          const Spacer(),
          TextButton(
            onPressed: _finishOnboarding,
            child: const Text('Geç', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildBadge(data),
          const SizedBox(height: 30),
          _buildHeroImage(data),
          const SizedBox(height: 40),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.yaziRengi, letterSpacing: -1),
          ).animate(key: ValueKey(data.title)).fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 15),
          Text(
            data.desc,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.blueGrey, height: 1.5, fontWeight: FontWeight.w500),
          ).animate(key: ValueKey(data.desc)).fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildBadge(OnboardingData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: data.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: data.accent.withOpacity(0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 16, color: data.accent),
          const SizedBox(width: 8),
          Text(data.badge, style: TextStyle(color: data.accent, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    ).animate().scale();
  }

  Widget _buildHeroImage(OnboardingData data) {
    return Container(
      width: 260, height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [BoxShadow(color: data.accent.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 10))],
      ),
      child: ClipOval(child: Image.asset(data.image, fit: BoxFit.cover)),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -10, end: 10, duration: 2.seconds);
  }

  Widget _buildBottomControls(OnboardingData page) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) => AnimatedContainer(
              duration: 300.ms,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == _currentPage ? 24 : 8, height: 8,
              decoration: BoxDecoration(color: i == _currentPage ? page.accent : Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
            )),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity, height: 60,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(backgroundColor: page.accent, foregroundColor: Colors.white, elevation: 8, shadowColor: page.accent.withOpacity(0.4)),
              child: Text(_currentPage == _pages.length - 1 ? 'BAŞLAYALIM! 🚀' : 'DEVAM ET', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

class OnboardingData {
  final String title, desc, image, badge;
  final IconData icon;
  final Color accent, lightAccent;
  OnboardingData({required this.title, required this.desc, required this.image, required this.icon, required this.accent, required this.lightAccent, required this.badge});
}
