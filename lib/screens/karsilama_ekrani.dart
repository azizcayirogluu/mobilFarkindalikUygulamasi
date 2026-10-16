import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          _buildBackground(size),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
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
                                    SizedBox(height: isShort ? 24 : 40),
                                    _buildHeroSection(size, isShort),
                                    SizedBox(height: isShort ? 24 : 40),
                                    _buildWelcomeText(isShort),
                                    const SizedBox(height: 24),
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
                    _buildBottomActions(size.width, bottomInset),
                  ],
                ),
              ),
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
          top: -size.width * 0.25,
          right: -size.width * 0.2,
          child: _GlowCircle(
            size: size.width * 0.85,
            color: const Color(0xFF6366F1).withValues(alpha: 0.12),
          ),
        ),
        Positioned(
          bottom: size.height * 0.15,
          left: -size.width * 0.3,
          child: _GlowCircle(
            size: size.width * 0.75,
            color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBrand() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: const Color(0xFFEEF2FF), width: 2),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/image/app_icon.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.shield_rounded,
                color: Color(0xFF6366F1),
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Flexible(
          child: Text(
            'Kahraman Dostum',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2);
  }

  Widget _buildHeroSection(Size size, bool isShort) {
    final double imageSize = isShort ? 140 : 180;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Dış Işıltı Halkası
        Container(
          width: imageSize + 60,
          height: imageSize + 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF6366F1).withValues(alpha: 0.15),
                const Color(0xFF818CF8).withValues(alpha: 0.03),
                Colors.transparent,
              ],
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds),

        // Logo Dairesi
        Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                blurRadius: 36,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(color: Colors.white, width: 8),
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset(
                'assets/image/app_icon.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.face_rounded,
                  size: 70,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: -8, end: 8, duration: 2.seconds),

        // Üst Sağ Rozet
        Positioned(
          top: -6,
          right: -6,
          child: const _HeroBadge(
            icon: Icons.star_rounded,
            color: Color(0xFFF59E0B),
            label: "Süper Güç",
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 4, end: -4, duration: 1.5.seconds),
        ),

        // Alt Sol Rozet
        Positioned(
          bottom: 0,
          left: -10,
          child: const _HeroBadge(
            icon: Icons.verified_user_rounded,
            color: Color(0xFF10B981),
            label: "Güvenli Rehber",
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -4, end: 4, duration: 2.seconds),
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
            color: Color(0xFF0F172A),
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Daha bilinçli, cesur ve güçlü olacağın\nsihirli macera seni bekliyor!',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 15,
            height: 1.5,
            fontWeight: FontWeight.w600,
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
    ).animate().fadeIn(delay: 350.ms).scale(begin: const Offset(0.92, 0.92));
  }

  Widget _buildFeatureItem(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.18), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(double width, double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset > 0 ? bottomInset + 12 : 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 24,
            offset: Offset(0, -8),
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
                backgroundColor: AppColors.anaMavi,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                elevation: 6,
                shadowColor: AppColors.anaMavi.withValues(alpha: 0.35),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Maceraya Başla! 🚀',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
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
                foregroundColor: AppColors.anaMavi,
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Zaten Kayıtlıyım',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
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
  final String label;

  const _HeroBadge({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF0F172A),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
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
