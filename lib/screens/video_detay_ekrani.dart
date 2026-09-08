import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    this.temaRengi = const Color(0xFF3B82F6),
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
  final String _userName = FirebaseAuth.instance.currentUser?.displayName ?? "Kahraman";

  @override
  void initState() {
    super.initState();
    _currentId = widget.youtubeId;
    _currentTitle = widget.baslik;

    // Web ve Mobil Uyumlu Gelişmiş Iframe Yapılandırması
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        color: 'blue',
        strictRelatedVideos: true,
      ),
    )..loadVideoById(videoId: _currentId);

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
    final bool currentStatus = !result.contains(ConnectivityResult.none);

    if (_isOnline != currentStatus) {
      setState(() {
        _isOnline = currentStatus;
      });
      if (!_isOnline) {
        _controller.pauseVideo();
      } else {
        _controller.playVideo();
      }
    }
  }

  void _videoDegistir(String id, String baslik) {
    if (id == _currentId) return; // Zaten oynatılan videoya tıklandıysa işlem yapma

    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text("İnternet bağlantını kontrol etmelisin! 🌐", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      );
      return;
    }

    setState(() {
      _currentId = id;
      _currentTitle = baslik;
    });
    _controller.loadVideoById(videoId: id);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundSubtle = Color(0xFFF0F9FF);

    return Scaffold(
      backgroundColor: backgroundSubtle,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 16),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          " $_currentTitle 🎬",
          style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.3),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Sinematik Oynatıcı Alanı
          Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.38),
            decoration: BoxDecoration(
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              child: _isOnline
                  ? YoutubePlayer(controller: _controller)
                  : _buildNoInternet(),
            ),
          ),

          // Video Bilgileri Kısmı
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.temaRengi.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "GÖREV VİDEOSU",
                        style: TextStyle(color: widget.temaRengi, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Harika bir içerik, $_userName! ✨",
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                    _currentTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.3, letterSpacing: -0.3)
                ).animate(key: ValueKey(_currentId)).fadeIn(duration: 300.ms).slideX(begin: -0.05),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: Divider(color: Color(0xFFE2E8F0), thickness: 1.5),
          ),

          // Liste Başlığı
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 10),
            child: Row(
              children: [
                const Text("⚡", style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                const Text(
                    "SIRADAKİ EĞİTİMLER",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF475569), letterSpacing: 1.2)
                ),
              ],
            ),
          ),

          // Önerilen Video Listesi
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(22, 2, 22, 30),
              physics: const BouncingScrollPhysics(),
              itemCount: widget.tumVideolarJson.length,
              itemBuilder: (context, index) {
                final video = widget.tumVideolarJson[index];
                final String? yId = video['youtubeId']?.toString();
                if (yId == null) return const SizedBox.shrink();

                final bool isPlayingNow = (yId == _currentId);

                return _buildVideoKarti(video, yId, isPlayingNow, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Oyunlaştırılmış Hücre Kartı Tasarımı
  Widget _buildVideoKarti(dynamic video, String yId, bool isPlayingNow, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isPlayingNow ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isPlayingNow ? const Color(0xFFBFDBFE) : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(isPlayingNow ? 0.04 : 0.02),
              blurRadius: 15,
              offset: const Offset(0, 6)
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _videoDegistir(yId, video['baslik'] ?? "İsimsiz Video"),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                            imageUrl: "https://img.youtube.com/vi/$yId/mqdefault.jpg",
                            width: 105,
                            height: 68,
                            fit: BoxFit.cover
                        ),
                      ),
                      if (isPlayingNow)
                        Container(
                          width: 105,
                          height: 68,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 24).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            video['baslik'] ?? "İsimsiz Video",
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13.5,
                                color: isPlayingNow ? const Color(0xFF1D4ED8) : const Color(0xFF1E293B),
                                height: 1.3
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis
                        ),
                        if (isPlayingNow) ...[
                          const SizedBox(height: 5),
                          const Text(
                            "Şu An Oynatılıyor 🎯",
                            style: TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.w900),
                          ),
                        ] else if (video['sure'] != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            video['sure'].toString(),
                            style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade300, fontWeight: FontWeight.w700),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms, delay: (index * 30).ms).slideY(begin: 0.08, curve: Curves.easeOut);
  }

  // İnternet Koptuğunda Gösterilecek İnteraktif ve Eğlenceli Tasarım
  Widget _buildNoInternet() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 55)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shake(hz: 2, duration: 1.seconds),
          const SizedBox(height: 12),
          const Text(
            "Sinyal Aranıyor...",
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white12,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: _checkInitialConnection,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
            label: const Text("YENİDEN DENE", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
