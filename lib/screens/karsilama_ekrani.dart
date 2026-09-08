import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _goToRegister() {
    HapticFeedback.mediumImpact();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const KayitEkrani(),
      ),
    );
  }

  void _goToLogin() {
    HapticFeedback.lightImpact();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GirisEkrani(),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _buildBackground(size),

          SafeArea(
            child: Column(
              children: [
                // ==================================================
                // ÜST / ORTA ALAN
                // ==================================================
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return _buildMainArea(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                      );
                    },
                  ),
                ),

                // ==================================================
                // ALT BUTON PANELİ
                // ==================================================
                _buildBottomActions(
                  width: size.width,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN AREA
  // ============================================================

  Widget _buildMainArea({
    required double width,
    required double height,
  }) {
    /*
      Buradaki amaç:

      Ekran büyürse içerik ortada kalır.
      Ekran küçülürse içerik küçülür.
      Hiçbir zaman scroll gerekmez.
    */

    final bool verySmall = height < 430;
    final bool small = height < 520;
    final bool medium = height < 650;

    final double heroSize = verySmall
        ? 105
        : small
        ? 125
        : medium
        ? 150
        : 190;

    final double topSpacing = verySmall
        ? 4
        : small
        ? 8
        : 14;

    final double sectionSpacing = verySmall
        ? 5
        : small
        ? 8
        : 13;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width < 360 ? 14 : 20,
        vertical: topSpacing,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTopBrand(
            compact: verySmall,
          ),

          SizedBox(height: sectionSpacing),

          _buildHero(
            size: heroSize,
            verySmall: verySmall,
          ),

          SizedBox(
            height: verySmall
                ? 5
                : small
                ? 8
                : 12,
          ),

          _buildWelcomeText(
            verySmall: verySmall,
            small: small,
          ),

          SizedBox(
            height: verySmall
                ? 6
                : small
                ? 9
                : 13,
          ),

          _buildFeatureCards(
            verySmall: verySmall,
            small: small,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BACKGROUND
  // ============================================================

  Widget _buildBackground(Size size) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -size.width * 0.35,
            right: -size.width * 0.25,
            child: _GlowCircle(
              size: size.width * 0.9,
              color: const Color(
                0xFF6C63FF,
              ).withOpacity(0.10),
            ),
          ),

          Positioned(
            top: size.height * 0.30,
            left: -size.width * 0.38,
            child: _GlowCircle(
              size: size.width * 0.78,
              color: const Color(
                0xFF00A896,
              ).withOpacity(0.07),
            ),
          ),

          Positioned(
            bottom: -size.width * 0.30,
            right: -size.width * 0.22,
            child: _GlowCircle(
              size: size.width * 0.78,
              color: const Color(
                0xFFFF8A3D,
              ).withOpacity(0.07),
            ),
          ),

          Positioned(
            top: size.height * 0.16,
            left: 22,
            child: _DecorIcon(
              icon: Icons.star_rounded,
              color: const Color(
                0xFF6C63FF,
              ).withOpacity(0.18),
              size: 19,
              animationController: _animationController,
            ),
          ),

          Positioned(
            top: size.height * 0.25,
            right: 25,
            child: _DecorIcon(
              icon: Icons.auto_awesome_rounded,
              color: const Color(
                0xFFFF8A3D,
              ).withOpacity(0.20),
              size: 18,
              animationController: _animationController,
              reverse: true,
            ),
          ),

          Positioned(
            bottom: size.height * 0.25,
            left: 30,
            child: _DecorIcon(
              icon: Icons.circle,
              color: const Color(
                0xFF00A896,
              ).withOpacity(0.12),
              size: 11,
              animationController: _animationController,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOP BRAND
  // ============================================================

  Widget _buildTopBrand({
    required bool compact,
  }) {
    final double iconSize = compact ? 30 : 36;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(
                0xFF6C63FF,
              ).withOpacity(0.10),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF6C63FF,
                ).withOpacity(0.10),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            Icons.shield_rounded,
            color: const Color(0xFF6C63FF),
            size: compact ? 16 : 20,
          ),
        ),

        SizedBox(
          width: compact ? 7 : 9,
        ),

        Text(
          'Kahraman Dostum',
          style: TextStyle(
            color: const Color(0xFF252943),
            fontSize: compact ? 14 : 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero({
    required double size,
    required bool verySmall,
  }) {
    final double outerSize = size + 34;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final double value = math.sin(
          _animationController.value *
              math.pi *
              2,
        );

        return Transform.translate(
          offset: Offset(
            0,
            value * (verySmall ? 2.5 : 5),
          ),
          child: child,
        );
      },
      child: SizedBox(
        width: outerSize + 10,
        height: outerSize + 10,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Container(
              width: outerSize,
              height: outerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF6C63FF,
                ).withOpacity(0.055),
              ),
            ),

            // Main circle
            Container(
              width: size,
              height: size,
              padding: EdgeInsets.all(
                verySmall ? 7 : 11,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Color(0xFFEDEBFF),
                  ],
                ),
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF6C63FF,
                    ).withOpacity(0.15),
                    blurRadius: verySmall ? 15 : 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/image/app_icon_two.png',
                  fit: BoxFit.contain,
                  errorBuilder: (
                      context,
                      error,
                      stackTrace,
                      ) {
                    return Icon(
                      Icons.smart_toy_rounded,
                      size: size * 0.42,
                      color: const Color(
                        0xFF6C63FF,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Turuncu yıldız
            Positioned(
              top: 0,
              right: 0,
              child: _HeroBadge(
                icon: Icons.auto_awesome_rounded,
                color: const Color(
                  0xFFFF8A3D,
                ),
                small: verySmall,
              ),
            ),

            // Turkuaz kalkan
            Positioned(
              bottom: 3,
              left: 0,
              child: _HeroBadge(
                icon: Icons.shield_rounded,
                color: const Color(
                  0xFF00A896,
                ),
                small: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WELCOME TEXT
  // ============================================================

  Widget _buildWelcomeText({
    required bool verySmall,
    required bool small,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Hazır mısın, Kahraman? 🚀',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(
              0xFF242944,
            ),
            fontSize: verySmall
                ? 20
                : small
                ? 22
                : 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
            height: 1.05,
          ),
        ),

        SizedBox(
          height: verySmall
              ? 4
              : small
              ? 6
              : 9,
        ),

        Text(
          'Daha bilinçli, daha cesur ve daha güçlü\n'
              'olacağın yolculuk burada başlıyor.',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(
              0xFF74798C,
            ),
            fontSize: verySmall
                ? 10
                : small
                ? 11
                : 14,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FEATURE CARDS
  // ============================================================

  Widget _buildFeatureCards({
    required bool verySmall,
    required bool small,
  }) {
    return Row(
      children: [
        Expanded(
          child: _FeatureCard(
            icon: Icons.psychology_alt_rounded,
            title: 'Öğren',
            subtitle: 'Keşfet',
            color: const Color(
              0xFF6C63FF,
            ),
            verySmall: verySmall,
            small: small,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _FeatureCard(
            icon: Icons.shield_rounded,
            title: 'Güçlen',
            subtitle: 'Korun',
            color: const Color(
              0xFF00A896,
            ),
            verySmall: verySmall,
            small: small,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _FeatureCard(
            icon: Icons.emoji_events_rounded,
            title: 'Kazan',
            subtitle: 'Rozetle',
            color: const Color(
              0xFFFF8A3D,
            ),
            verySmall: verySmall,
            small: small,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BOTTOM ACTIONS
  // ============================================================

  Widget _buildBottomActions({
    required double width,
  }) {
    /*
      BU KISIM COLUMN'UN ALTINDA.

      Dolayısıyla ekranın yüksekliği artsa bile
      butonlar yukarı gitmez.

      SafeArea ile telefonun navigation bar / home indicator
      alanına da girmez.
    */

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        width < 360 ? 14 : 18,
        10,
        width < 360 ? 14 : 18,
        8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        border: Border.all(
          color: Colors.white,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 26,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 34,
              height: 4,
              margin: const EdgeInsets.only(
                bottom: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFD9DBE5,
                ),
                borderRadius:
                BorderRadius.circular(20),
              ),
            ),

            // Başlık
            Row(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF6C63FF),
                  size: 17,
                ),
                SizedBox(width: 6),
                Text(
                  'Hadi başlayalım!',
                  style: TextStyle(
                    color: Color(0xFF30344D),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 9),

            // ANA BUTON
            _PrimaryButton(
              onTap: _goToRegister,
            ),

            const SizedBox(height: 7),

            // GİRİŞ
            _LoginButton(
              onTap: _goToLogin,
            ),

            const SizedBox(height: 5),

            // Güvenlik yazısı
            const Text(
              'Güvenli • Çocuk dostu • Gizliliğin korunur',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF9A9EAE),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// FEATURE CARD
// ================================================================

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool verySmall;
  final bool small;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.verySmall,
    required this.small,
  });

  @override
  Widget build(BuildContext context) {
    final double cardVertical = verySmall
        ? 5
        : small
        ? 7
        : 10;

    final double iconSize = verySmall
        ? 27
        : small
        ? 31
        : 40;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: cardVertical,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(
          verySmall ? 13 : 18,
        ),
        border: Border.all(
          color: Colors.white,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: verySmall
                  ? 14
                  : small
                  ? 16
                  : 21,
            ),
          ),

          SizedBox(
            height: verySmall
                ? 2
                : small
                ? 4
                : 6,
          ),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(
                0xFF30344D,
              ),
              fontSize: verySmall
                  ? 9
                  : small
                  ? 10
                  : 12,
              fontWeight: FontWeight.w900,
            ),
          ),

          if (!verySmall) ...[
            const SizedBox(height: 1),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(
                  0xFF969AAA,
                ),
                fontSize: small ? 8.5 : 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ================================================================
// PRIMARY BUTTON
// ================================================================

class _PrimaryButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF6C63FF),
              Color(0xFF8178FF),
            ],
          ),
          borderRadius:
          BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF6C63FF,
              ).withOpacity(0.24),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor:
            Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor:
            Colors.transparent,
            elevation: 0,
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(18),
            ),
          ),
          child: const Row(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Icon(
                Icons.rocket_launch_rounded,
                size: 21,
              ),
              SizedBox(width: 9),
              Text(
                'Maceraya Başla',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// LOGIN BUTTON
// ================================================================

class _LoginButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LoginButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 47,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor:
          const Color(0xFF6C63FF),
          side: BorderSide(
            color: const Color(
              0xFF6C63FF,
            ).withOpacity(0.18),
            width: 1.3,
          ),
          backgroundColor:
          const Color(0xFFFAF9FF),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              Icons.login_rounded,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Zaten kahraman mısın?',
              style: TextStyle(
                color: Color(0xFF85899A),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4),
            Text(
              'Giriş Yap',
              style: TextStyle(
                color: Color(0xFF6C63FF),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// HERO BADGE
// ================================================================

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool small;

  const _HeroBadge({
    required this.icon,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final double size =
    small ? 30 : 38;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.12),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.14),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: color,
        size: small ? 15 : 18,
      ),
    );
  }
}

// ================================================================
// DECOR ICON
// ================================================================

class _DecorIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final AnimationController animationController;
  final bool reverse;

  const _DecorIcon({
    required this.icon,
    required this.color,
    required this.size,
    required this.animationController,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final double value = math.sin(
          animationController.value *
              math.pi *
              2,
        );

        return Transform.translate(
          offset: Offset(
            0,
            (reverse ? -1 : 1) *
                value *
                5,
          ),
          child: Transform.rotate(
            angle: value * 0.05,
            child: child,
          ),
        );
      },
      child: Icon(
        icon,
        color: color,
        size: size,
      ),
    );
  }
}

// ================================================================
// GLOW CIRCLE
// ================================================================

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}