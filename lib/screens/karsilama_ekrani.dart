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
          // Arka Plan Süslemeleri
          Positioned(
            top: -size.width * 0.2,
            right: -size.width * 0.2,
            child: _CircleDecorator(
              size: size.width * 0.8,
              color: Colors.blue.withOpacity(0.1),
            ),
          ),
          Positioned(
            bottom: size.height * 0.1,
            left: -size.width * 0.3,
            child: _CircleDecorator(
              size: size.width * 0.9,
              color: Colors.orange.withOpacity(0.05),
            ),
          ),

          // LayoutBuilder ve SingleChildScrollView ile küçük ekran güvencesi
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight, // Ekran büyükse tam kaplasın
                    ),
                    child: IntrinsicHeight(
                      // İçeriklerin dikeyde düzgün yayılması için
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 24,
                          ), // Küçük ekranlar için aralık biraz daraltıldı
                          _buildModernHeader(),

                          // Sabit Spacer yerine esnek bir boşluk yapısı
                          Expanded(
                            flex: 2,
                            child: TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0, end: 15),
                              duration: const Duration(seconds: 3),
                              curve: Curves.easeInOutSine,
                              builder: (context, double value, child) {
                                return Transform.translate(
                                  offset: Offset(0, value),
                                  child: Container(
                                    height: size.height * 0.25,
                                    padding: const EdgeInsets.all(20),
                                    child: Image.asset(
                                      "assets/app_icon_two.png",
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const Expanded(flex: 1, child: SizedBox(height: 20)),
                          _buildBottomPanel(context, size),
                        ],
                      ),
                    ),
                  ),
                );
              },
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
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: Color(0xFF4A90E2),
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Siber Kahraman",
          style: TextStyle(
            fontSize:
                26, // Yazı boyutu çok küçük ekranlar için 28'den 26'ya çekildi
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
        ),
      ],
    );
  }

  Widget _buildBottomPanel(BuildContext context, Size size) {
    return Container(
      width: double.infinity,
      // Küçük ekranlarda padding'lerin taşma yapmaması için dikey padding 40'tan 30'a düşürüldü
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(
            40,
          ), // Kavis minik telefonlarda kaba durmasın diye 50'den 40'a çekildi
          topRight: Radius.circular(40),
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
              fontSize: 22, // 24'ten 22'ye çekildi
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Dijital dünyada nazik olmayı öğren, kendini koru ve topluluğumuzun bir parçası ol.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14, // 15'ten 14'e çekildi
              color: Color(0xFF9196A2),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 25), // Boşluk 35'ten 25'e düşürüldü
          // Buton tasarımı responsive yapıldı
          SizedBox(
            width: double.infinity,
            height:
                56, // Standart modern buton yüksekliği (60 çok kaba kaçabiliyordu)
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KayitEkrani()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Macerayı Başlat",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GirisEkrani()),
            ),
            child: RichText(
              text: const TextSpan(
                text: "Hesabın Var Mı? ",
                style: TextStyle(color: Color(0xFF9196A2), fontSize: 15),
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
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
