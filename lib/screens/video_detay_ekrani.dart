import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';

List<Map<String, dynamic>> normalizeVideoList(List<dynamic> source) {
  final List<Map<String, dynamic>> normalized = [];
  final Set<String> seenIds = <String>{};

  for (final item in source) {
    if (item is! Map) continue;

    final map = Map<String, dynamic>.from(item as Map);
    final dynamic rawYoutubeId = map['youtubeId'] ?? map['data']?['youtubeId'];
    final String youtubeId = rawYoutubeId?.toString().trim() ?? '';

    if (youtubeId.isEmpty) continue;

    final String idKey = youtubeId;
    if (seenIds.contains(idKey)) continue;
    seenIds.add(idKey);

    if (map['data'] is Map &&
        map['data']['youtubeId'] != null &&
        map['data']['youtubeId'].toString().trim().isNotEmpty) {
      final data = Map<String, dynamic>.from(map['data'] as Map);
      data['youtubeId'] = youtubeId;
      data['baslik'] ??= map['baslik'] ?? data['baslik'];
      normalized.add(data);
      continue;
    }

    normalized.add(map);
  }

  return normalized;
}

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
  final String _userName =
      FirebaseAuth.instance.currentUser?.displayName ?? "Kahraman";
  late List<Map<String, dynamic>> _videoList;

  @override
  void initState() {
    super.initState();
    _videoList = normalizeVideoList(widget.tumVideolarJson);
    _currentId = widget.youtubeId;
    _currentTitle = widget.baslik;

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

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
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
    if (id == _currentId) return;

    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text(
                "İnternet bağlantını kontrol etmelisin! 🌐",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
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
    const Color backgroundSubtle = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: backgroundSubtle,
      appBar: AppBar(
        toolbarHeight: 75,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 16),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          _currentTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.35,
            ),
            decoration: BoxDecoration(
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
              child: _isOnline
                  ? YoutubePlayer(controller: _controller)
                  : _buildNoInternet(),
            ),
          ),

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
                        style: TextStyle(
                          color: widget.temaRengi,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Selam, $_userName! ✨",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _currentTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ).animate(key: ValueKey(_currentId)).fadeIn().slideX(begin: -0.05),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: Divider(color: Color(0xFFE2E8F0)),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 10),
            child: Row(
              children: [
                const Text("⚡", style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                const Text(
                  "SIRADAKİ EĞİTİMLER",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF475569),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(22, 2, 22, 30),
              physics: const BouncingScrollPhysics(),
              itemCount: _videoList.where((video) {
                final String yId = (video['youtubeId'] ?? video['data']?['youtubeId'])?.toString().trim() ?? '';
                return yId.isNotEmpty && yId != _currentId;
              }).length,
              itemBuilder: (context, index) {
                final otherVideos = _videoList.where((video) {
                  final String yId = (video['youtubeId'] ?? video['data']?['youtubeId'])?.toString().trim() ?? '';
                  return yId.isNotEmpty && yId != _currentId;
                }).toList();

                final video = otherVideos[index];
                final String yId = (video['youtubeId'] ?? video['data']?['youtubeId'])?.toString().trim() ?? '';
                
                return _buildVideoKarti(video, yId, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoKarti(dynamic video, String yId, int index) {
    final title = (video['baslik'] ?? video['data']?['baslik'] ?? 'İsimsiz Video').toString();
    final duration = video['sure'] ?? video['data']?['sure'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _videoDegistir(yId, title),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: "https://img.youtube.com/vi/$yId/mqdefault.jpg",
                    width: 105,
                    height: 68,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: Color(0xFF1E293B),
                          height: 1.3,
                        ),
                      ),
                      if (duration != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          duration.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blueGrey.shade300,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms, delay: (index * 30).ms).slideY(begin: 0.08);
  }

  Widget _buildNoInternet() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 50).animate(onPlay: (c) => c.repeat(reverse: true)).shake(),
          const SizedBox(height: 12),
          const Text("İnternet Aranıyor...", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          TextButton(
            onPressed: _checkInitialConnection,
            child: const Text("YENİDEN DENE", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
