import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/services/analytics_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VideoDetayEkrani extends StatefulWidget {
  final String baslik;
  final String youtubeId;
  final List tumVideolarJson;
  final Color temaRengi;

  const VideoDetayEkrani({
    super.key,
    required this.baslik,
    required this.youtubeId,
    required this.tumVideolarJson,
    this.temaRengi = AppColors.anaMavi,
  });

  @override
  State<VideoDetayEkrani> createState() => _VideoDetayEkraniState();
}

class _VideoDetayEkraniState extends State<VideoDetayEkrani> {
  late YoutubePlayerController _controller;
  late String _currentId;
  late String _currentTitle;

  bool _isOnline = true;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _currentId = widget.youtubeId;
    _currentTitle = widget.baslik;

    _controller = YoutubePlayerController(
      initialVideoId: _currentId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false, hideControls: false),
    );

    _checkInitialConnection();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      _updateConnectionStatus(result);
    });
  }

  Future<void> _checkInitialConnection() async {
    List<ConnectivityResult> result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    if (!mounted) return;
    setState(() {
      _isOnline = !result.contains(ConnectivityResult.none);
    });

    if (!_isOnline) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _controller.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _videoDegistir(String id, String baslik) {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video değiştirmek için internet gerekiyor! 🌐"))
      );
      return;
    }
    setState(() {
      _currentId = id;
      _currentTitle = baslik;
    });
    _controller.load(id);
  }

  @override
  Widget build(BuildContext context) {
    final onerilenler = widget.tumVideolarJson.where((v) => v['youtubeId'] != _currentId).toList();

    return YoutubePlayerBuilder(
      onEnterFullScreen: () => SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight
      ]),
      onExitFullScreen: () => SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
      player: YoutubePlayer(
        controller: _controller,
        progressIndicatorColor: AppColors.accentMavi,
        onEnded: (metadata) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            int dakika = (metadata.duration.inMinutes > 0) ? metadata.duration.inMinutes : 1;
            AnalyticsService().sureEkle(user.uid, dakika);
          }
          if (onerilenler.isNotEmpty) {
            _videoDegistir(onerilenler[0]['youtubeId'], onerilenler[0]['baslik']);
          }
        },
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: AppColors.zemin,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.yaziRengi),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text("EĞİTİCİ VİDEO",
                style: TextStyle(color: AppColors.yaziRengi, fontWeight: FontWeight.w900, fontSize: 16)),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(color: Colors.black),
                child: _isOnline ? player : _buildNoInternet(),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_currentTitle,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.yaziRengi)),
                    const SizedBox(height: 10),
                    Container(height: 4, width: 50,
                        decoration: BoxDecoration(color: AppColors.anaMavi, borderRadius: BorderRadius.circular(10))),
                  ],
                ),
              ),

              const Divider(indent: 20, endIndent: 20),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("SIRADAKİ VİDEOLAR",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: onerilenler.length,
                  itemBuilder: (context, index) => _buildVideoKarti(onerilenler[index]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoKarti(dynamic video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: InkWell(
        onTap: () => _videoDegistir(video['youtubeId'], video['baslik']),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  "https://img.youtube.com/vi/${video['youtubeId']}/mqdefault.jpg",
                  width: 110, height: 70, fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(width: 110, height: 70, color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(video['baslik'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.yaziRengi),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Text("İzlemek için dokun", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_outline_rounded, color: AppColors.anaMavi),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoInternet() {
    return Container(
      height: 200, color: Colors.black87,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 50),
          const SizedBox(height: 10),
          const Text("İnternet Bağlantısı Yok", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          TextButton(onPressed: _checkInitialConnection, child: const Text("TEKRAR DENE", style: TextStyle(color: AppColors.anaMavi))),
        ],
      ),
    );
  }
}
