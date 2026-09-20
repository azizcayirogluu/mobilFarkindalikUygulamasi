import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zorbalik_uygulamasi/screens/giris_yapma_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/kayit_olma_ekrani.dart';

class KarsilamaEkrani extends StatefulWidget {
  const KarsilamaEkrani({super.key});

  @override
  State<KarsilamaEkrani> createState() => _KarsilamaEkraniState();
}

class _KarsilamaEkraniState extends State<KarsilamaEkrani>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _goToRegister() {
    HapticFeedback.mediumImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => const KayitEkrani()));
  }

  void _goToLogin() {
    HapticFeedback.lightImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => const GirisEkrani()));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bool isShort = size.height < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          _buildBackground(size),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 20),
                                _buildTopBrand(),
                                SizedBox(height: isShort ? 30 : 50),
                                _buildHeroSection(size, isShort),
                                SizedBox(height: isShort ? 30 : 50),
                                _buildWelcomeText(isShort),
                                const SizedBox(height: 30),
                                _buildFeatureCards(isShort),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _buildBottomActions(size.width),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Size size) {
    return Stack(
      children: [
        Positioned(
          top: -size.width * 0.2,
          right: -size.width * 0.2,
          child: _GlowCircle(size: size.width * 0.8, color: const Color(0xFFE0F2FE)),
        ),
        Positioned(
          bottom: size.height * 0.2,
          left: -size.width * 0.3,
          child: _GlowCircle(size: size.width * 0.7, color: const Color(0xFFF0F9FF)),
        ),
      ],
    );
  }

  Widget _buildTopBrand() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        const Flexible(
          child: Text(
            'Kahraman Günlüğü',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2);
  }

  Widget _buildHeroSection(Size size, bool isShort) {
    double imageSize = isShort ? 140 : 180;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: imageSize + 60,
          height: imageSize + 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF6366F1).withOpacity(0.05),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds),
        
        Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.white, width: 8),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/image/app_icon_two.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.face_rounded, size: 60, color: Color(0xFF6366F1)),
            ),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -8, end: 8, duration: 2.seconds),

        Positioned(
          top: 0,
          right: 0,
          child: _HeroBadge(icon: Icons.star_rounded, color: const Color(0xFFF59E0B))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 5, end: -5, duration: 1.5.seconds),
        ),
        Positioned(
          bottom: 10,
          left: 0,
          child: _HeroBadge(icon: Icons.verified_user_rounded, color: const Color(0xFF10B981))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -5, end: 5, duration: 2.seconds),
        ),
      ],
    );
  }

  Widget _buildWelcomeText(bool isShort) {
    return Column(
      children: [
        const Text(
          'Hazır mısın Kahraman? 🚀',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Daha bilinçli, cesur ve güçlü olacağın\nsihirli yolculuk burada başlıyor!',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 15,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildFeatureCards(bool isShort) {
    return Row(
      children: [
        _buildFeatureItem(Icons.lightbulb_rounded, 'Öğren', const Color(0xFF6366F1)),
        const SizedBox(width: 12),
        _buildFeatureItem(Icons.shield_rounded, 'Güçlen', const Color(0xFF10B981)),
        const SizedBox(width: 12),
        _buildFeatureItem(Icons.emoji_events_rounded, 'Kazan', const Color(0xFFF59E0B)),
      ],
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildFeatureItem(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(double width) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _goToRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: const Text(
                'Maceraya Başla! 🚀',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton(
              onPressed: _goToLogin,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text(
                'Zaten Kayıtlıyım',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.2);
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _HeroBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
