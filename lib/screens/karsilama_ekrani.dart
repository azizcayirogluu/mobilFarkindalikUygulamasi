import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/giris_yapma_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/kayit_olma_ekrani.dart';

class _C {
  static const ink = Color(0xFF1B2A4A);
  static const soft = Color(0xFF6B7A99);
  static const skyTop = Color(0xFFDDF0FF);
  static const skyMid = Color(0xFFF2F9FF);
  static const sun = Color(0xFFFFC445);
  static const mint = Color(0xFF2FD6A0);
  static const coral = Color(0xFFFF7A8A);
}

class KarsilamaEkrani extends StatefulWidget {
  const KarsilamaEkrani({super.key});

  @override
  State<KarsilamaEkrani> createState() => _KarsilamaEkraniState();
}

class _KarsilamaEkraniState extends State<KarsilamaEkrani>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbit;

  @override
  void initState() {
    super.initState();
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _orbit.dispose();
    super.dispose();
  }

  void _goToRegister() {
    HapticFeedback.mediumImpact();
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const KayitEkrani()));
  }

  void _goToLogin() {
    HapticFeedback.lightImpact();
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const GirisEkrani()));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isShort = size.height < 700;
    final heroSize = math.min(size.width * 0.82, isShort ? 270.0 : 330.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_C.skyTop, _C.skyMid, Colors.white],
            stops: [0, 0.45, 1],
          ),
        ),
        child: Stack(
          children: [
            ..._buildSparkles(size),
            SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, c) => SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints:
                              BoxConstraints(minHeight: c.maxHeight),
                              child: Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 28),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 12),
                                    _brandPill(),
                                    SizedBox(height: isShort ? 8 : 20),
                                    _hero(heroSize),
                                    SizedBox(height: isShort ? 8 : 20),
                                    _title(),
                                    const SizedBox(height: 22),
                                    _steps(),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _actions(bottomInset),
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

  // ---------- Arka plan ----------

  List<Widget> _buildSparkles(Size size) {
    Widget spark(double l, double t, double s, Color c, int ms) {
      return Positioned(
        left: l,
        top: t,
        child: Icon(Icons.auto_awesome_rounded, size: s, color: c)
            .animate(onPlay: (a) => a.repeat(reverse: true))
            .fade(begin: 0.25, end: 0.9, duration: ms.ms)
            .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.15, 1.15),
            duration: ms.ms),
      );
    }

    return [
      spark(size.width * 0.08, size.height * 0.1, 18, _C.sun, 1800),
      spark(size.width * 0.86, size.height * 0.16, 14, _C.coral, 2300),
      spark(size.width * 0.14, size.height * 0.38, 12, _C.mint, 2000),
      spark(size.width * 0.88, size.height * 0.42, 20, _C.sun, 2600),
    ];
  }

  // ---------- Üst marka ----------

  Widget _brandPill() {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.anaMavi.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: Image.asset(
              'assets/image/app_icon.png',
              width: 34,
              height: 34,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 34,
                height: 34,
                color: AppColors.anaMavi.withValues(alpha: 0.12),
                child: Icon(
                  Icons.shield_rounded,
                  size: 20,
                  color: AppColors.anaMavi,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Kahraman Dostum',
            style: TextStyle(
              color: _C.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: -0.3, curve: Curves.easeOut);
  }

  // ---------- Kahraman + yörüngedeki rozetler ----------

  Widget _hero(double s) {
    final mascot = s * 0.5;
    final radius = s / 2 - 26;

    final items = <_OrbitItem>[
      _OrbitItem(Icons.shield_rounded, AppColors.anaMavi),
      _OrbitItem(Icons.star_rounded, _C.sun),
      _OrbitItem(Icons.favorite_rounded, _C.coral),
      _OrbitItem(Icons.emoji_events_rounded, _C.mint),
    ];

    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Yörünge halkası
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.anaMavi.withValues(alpha: 0.14),
                width: 2,
              ),
            ),
          ),
          // Yumuşak ışık
          Container(
            width: mascot * 1.55,
            height: mascot * 1.55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white,
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          // Kahraman
          Container(
            width: mascot,
            height: mascot,
            padding: EdgeInsets.all(mascot * 0.08),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.anaMavi.withValues(alpha: 0.28),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/image/app_icon.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  Icons.face_rounded,
                  size: mascot * 0.55,
                  color: AppColors.anaMavi,
                ),
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -6, end: 6, duration: 2.2.seconds, curve: Curves.easeInOut),
          // Yörüngede dönen rozetler
          AnimatedBuilder(
            animation: _orbit,
            builder: (context, _) {
              final t = _orbit.value * 2 * math.pi;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  for (int i = 0; i < items.length; i++)
                    Positioned(
                      left: s / 2 +
                          radius * math.cos(t + i * 2 * math.pi / items.length) -
                          22,
                      top: s / 2 +
                          radius * math.sin(t + i * 2 * math.pi / items.length) -
                          22,
                      child: _OrbitBadge(item: items[i]),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 500.ms).scale(
      begin: const Offset(0.85, 0.85),
      curve: Curves.easeOutBack,
      duration: 600.ms,
    );
  }

  // ---------- Başlık ----------

  Widget _title() {
    return Column(
      children: [
        const Text(
          'Süper gücünü keşfetmeye hazır mısın?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _C.ink,
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Zorbalığa karşı güçlü olmayı\noyun oynayarak öğren.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _C.soft,
            fontSize: 16,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 350.ms, duration: 500.ms);
  }

  // ---------- Öğren → Güçlen → Kazan ----------

  Widget _steps() {
    Widget step(IconData icon, String label, Color color) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: _C.ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    Widget link() => Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            4,
                (_) => Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: AppColors.anaMavi.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );

    return Row(
      children: [
        step(Icons.lightbulb_rounded, 'Öğren', AppColors.anaMavi),
        link(),
        step(Icons.shield_rounded, 'Güçlen', _C.mint),
        link(),
        step(Icons.emoji_events_rounded, 'Kazan', _C.sun),
      ],
    ).animate().fadeIn(delay: 500.ms, duration: 500.ms);
  }

  // ---------- Alt butonlar ----------

  Widget _actions(double bottomInset) {
    return Padding(
      padding: EdgeInsets.fromLTRB(28, 8, 28, bottomInset > 0 ? bottomInset + 8 : 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 62,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(31),
                gradient: LinearGradient(
                  colors: [
                    AppColors.anaMavi,
                    Color.lerp(AppColors.anaMavi, const Color(0xFF7C5CFF), 0.55)!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.anaMavi.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(31),
                  onTap: _goToRegister,
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Maceraya Başla',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.rocket_launch_rounded,
                            color: Colors.white, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.025, 1.025),
            duration: 1.6.seconds,
            curve: Curves.easeInOut,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _goToLogin,
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              foregroundColor: _C.soft,
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: _C.soft,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  const TextSpan(text: 'Hesabın var mı? '),
                  TextSpan(
                    text: 'Giriş yap',
                    style: TextStyle(
                      color: AppColors.anaMavi,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 650.ms, duration: 500.ms).slideY(begin: 0.15);
  }
}

class _OrbitItem {
  final IconData icon;
  final Color color;
  const _OrbitItem(this.icon, this.color);
}

class _OrbitBadge extends StatelessWidget {
  final _OrbitItem item;
  const _OrbitBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(item.icon, color: item.color, size: 24),
    );
  }
}