import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:zorbalik_uygulamasi/screens/giris_yapma_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/kayit_olma_ekrani.dart';

class HomePages extends StatelessWidget {
  const HomePages({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: Stack(
        children: [
          // 1. ARKA PLAN DESENLERİ (Yumuşak ve Aydınlık)
          Positioned(
            top: -size.width * 0.2,
            right: -size.width * 0.2,
            child: _CircleDecorator(size: size.width * 0.8, color: Colors.blue.withOpacity(0.1)),
          ),
          Positioned(
            bottom: size.height * 0.1,
            left: -size.width * 0.3,
            child: _CircleDecorator(size: size.width * 0.9, color: Colors.orange.withOpacity(0.05)),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildModernHeader(),

                const Spacer(),

                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 15),
                  duration: const Duration(seconds: 3),
                  curve: Curves.easeInOutSine,
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(0, value),
                      child: Container(
                        height: size.height * 0.30,
                        padding: const EdgeInsets.all(20),
                        child: Image.asset(
                          "assets/team.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(),
                _buildBottomPanel(context, size),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
            ],
          ),
          child: const Icon(Icons.shield_outlined, color: Color(0xFF4A90E2), size: 32),
        ),
        const SizedBox(height: 16),
        const Text(
          "Siber Kahraman",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2D3142),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 3,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.orangeAccent,
            borderRadius: BorderRadius.circular(10),
          ),
        )
      ],
    );
  }

  Widget _buildBottomPanel(BuildContext context, Size size) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(50),
          topRight: Radius.circular(50),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Güvenli Bir Yolculuk! ✨",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Dijital dünyada nazik olmayı öğren, kendini koru ve topluluğumuzun bir parçası ol.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF9196A2),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 35),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KayitEkrani())),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text(
                "Macerayı Başlat",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GirisEkrani())),
            child: RichText(
              text: const TextSpan(
                text: "Hesabın Var Mı? ",
                style: TextStyle(color: Color(0xFF9196A2), fontSize: 16),
                children: [
                  TextSpan(
                    text: "Giriş Yap",
                    style: TextStyle(
                      color: Color(0xFF4A90E2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleDecorator extends StatelessWidget {
  final double size;
  final Color color;
  const _CircleDecorator({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}