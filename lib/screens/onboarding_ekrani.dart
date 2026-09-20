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
      title: 'Yapay Zeka Dostun! 🤖✨',
      desc: 'Siber Asistan arkadaşın 7/24 seninle! Takıldığın her an ona danışabilir, siber dünyada güvenle sohbet edebilirsin.',
      image: 'assets/image/robot.png',
      icon: Icons.smart_toy_rounded,
      accent: Color(0xFF6366F1), // Modern Indigo
      lightAccent: Color(0xFFEEF2FF),
      badge: 'SİBER ASİSTAN',
    ),
    OnboardingData(
      title: 'Tuzakları Boz, Çöz! 🔍🛡️',
      desc: 'Gizemli senaryoları bir dedektif gibi incele, doğru kararlar ver ve siber zorbalık tuzaklarını zekanla alt et!',
      image: 'assets/image/team.png',
      icon: Icons.psychology_alt_rounded,
      accent: Color(0xFF10B981), // Modern Emerald
      lightAccent: Color(0xFFECFDF5),
      badge: 'KAHRAMAN DEDEKTİF',
    ),
    OnboardingData(
      title: 'Rozetleri Topla! 🏆🏅',
      desc: 'Eğlenceli görevleri tamamla, efsanevi siber rozetleri kazan ve akademinin en güçlü koruyucusu ol!',
      image: 'assets/image/rozet.png',
      icon: Icons.emoji_events_rounded,
      accent: Color(0xFFF59E0B), // Modern Amber
      lightAccent: Color(0xFFFEF3C7),
      badge: 'SÜPER AKADEMİ',
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
                  const Color(0xFFF8FAFC),
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
            child: _circle(240, page.accent.withOpacity(0.04))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: -20, end: 20, duration: 4.seconds),
          ),
          Positioned(
            bottom: -80, left: -60,
            child: _circle(260, page.accent.withOpacity(0.03))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveX(begin: -15, end: 15, duration: 5.seconds),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.shield_rounded, color: Color(0xFF6366F1), size: 24),
          const SizedBox(width: 8),
          const Text(
            'KAHRAMAN GÜNLÜĞÜ',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: Color(0xFF1E293B),
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _finishOnboarding,
            child: const Text(
              'Geç ✨',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBadge(data),
                const SizedBox(height: 35),
                _buildHeroImage(data),
                const SizedBox(height: 45),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ).animate(key: ValueKey(data.title)).fadeIn().slideY(begin: 0.1, curve: Curves.easeOutBack),
                const SizedBox(height: 14),
                Text(
                  data.desc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF475569),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate(key: ValueKey(data.desc)).fadeIn(delay: 150.ms),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(OnboardingData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: data.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: data.accent.withOpacity(0.15), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 16, color: data.accent),
          const SizedBox(width: 8),
          Text(
            data.badge,
            style: TextStyle(
              color: data.accent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    ).animate().scale(curve: Curves.easeOutBack);
  }

  Widget _buildHeroImage(OnboardingData data) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: data.accent.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
        border: Border.all(color: Colors.white, width: 6),
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Image.asset(
            data.image,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(data.icon, size: 80, color: data.accent),
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -8, end: 8, duration: 2.seconds, curve: Curves.easeInOut);
  }

  Widget _buildBottomControls(OnboardingData page) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 10, 30, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) => AnimatedContainer(
              duration: 300.ms,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: i == _currentPage ? 26 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == _currentPage ? page.accent : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: page.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                _currentPage == _pages.length - 1 ? 'BAŞLAYALIM! 🚀' : 'DEVAM ET',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
              ),
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
