import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Haptik geri bildirim için
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zorbalik_uygulamasi/services/storage_service.dart';
import 'package:zorbalik_uygulamasi/screens/karsilama_ekrani.dart';

class OnboardingEkrani extends StatefulWidget {
  const OnboardingEkrani({super.key});

  @override
  State<OnboardingEkrani> createState() => _OnboardingEkraniState();
}

class _OnboardingEkraniState extends State<OnboardingEkrani> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Yeni Dijital Yol Arkadaşınla Tanış! 🤖",
      desc:
          "Merhaba Kahraman! Ben senin Siber Dostunum. İnternetin devasa dünyasında gezerken artık yalnız değilsin.",
      image: "assets/robot.png",
    ),
    OnboardingData(
      title: "Senin Gücün, Bizim Birliğimiz! 💪",
      desc:
          "Canını sıkan bir durum olduğunda asla sessiz kalma! Bana anlat, uzman ekibimizle hep yanındayız.",
      image: "assets/güclü-cocuklar2.jpg",
    ),
    OnboardingData(
      title: "Görevleri Tamamla, Rozetleri Kap! 🏆",
      desc:
          "Siber dünyayı korumak çok eğlenceli! Görevleri tamamla, puan topla ve gerçek bir koruyucu ol.",
      image: "assets/rozet.png",
    ),
  ];

  Future<void> _finishOnboarding() async {
    HapticFeedback.heavyImpact();
    await StorageService().setFirstRunComplete();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePages()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemBuilder: (context, index) => _buildPage(_pages[index]),
          ),

          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _finishOnboarding,
                  child: const Text(
                    "Atla",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: 500.ms,
                        curve: Curves.easeOutBack,
                      );
                    } else {
                      _finishOnboarding();
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  excludeFromSemantics: false,
                  trackpadScrollCausesScale: false,
                  child:
                      Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF7043), // Canlı turuncu
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              _currentPage == _pages.length - 1
                                  ? Icons.rocket_launch_rounded
                                  : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          )
                          .animate(
                            target: _currentPage == _pages.length - 1 ? 1 : 0,
                          )
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.1, 1.1),
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(data.image, height: 280)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(
                begin: -15,
                end: 15,
                duration: 2.seconds,
                curve: Curves.easeInOut,
              ),

          const SizedBox(height: 50),

          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF263238),
            ),
          ).animate().fadeIn().slideY(begin: 0.3),

          const SizedBox(height: 20),

          Text(
            data.desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.6,
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String desc;
  final String image;

  OnboardingData({
    required this.title,
    required this.desc,
    required this.image,
  });
}
