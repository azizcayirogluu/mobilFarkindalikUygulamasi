import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';

class VideoManager extends StatefulWidget {
  const VideoManager({super.key});

  @override
  State<VideoManager> createState() => _VideoManagerState();
}

class _VideoManagerState extends State<VideoManager> {
  // Firestore veritabanı erişimi için kullanılan ana nesne
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.zemin,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 30),
            _buildQuickStats(),
            const SizedBox(height: 25),
            Expanded(
              // StreamBuilder: 'videos' koleksiyonunu eklenme tarihine göre canlı olarak dinler
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('videos').orderBy('eklenmeTarihi', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }
                  final docs = snapshot.data!.docs;
                  // Videoları 3 sütunlu ızgara yapısında görüntüler
                  return GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 25,
                      mainAxisSpacing: 25,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final docId = docs[index].id;
                      // URL'den YouTube ID'sini çekerek kapak görseli ve oynatma linki oluşturur
                      final String? videoId = data['youtubeId'] ?? _extractYoutubeId(data['url']);
                      return _buildPremiumVideoCard(docId, data, videoId ?? "error");
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("VİDEO STÜDYOSU", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.yaziRengi)),
            const Text("Tüm metadata ve içerik detaylarını buradan yönetin.", style: TextStyle(color: Colors.blueGrey)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showVideoStudioDialog(),
          icon: const Icon(Icons.video_call_rounded),
          label: const Text("YENİ İÇERİK EKLE"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
          ),
        ),
      ],
    );
  }

//Video ekleme ekranı
  void _showVideoStudioDialog({String? docId, Map<String, dynamic>? existingData}) {
    final tC = TextEditingController(text: existingData?['baslik']);
    final sC = TextEditingController(text: existingData?['altBaslik']);
    final aC = TextEditingController(text: existingData?['aciklama']);
    final uC = TextEditingController(text: existingData?['url'] ?? existingData?['youtubeId']);
    final durC = TextEditingController(text: existingData?['sure'] ?? "02:30");

    String selectedIcon = existingData?['ikon'] ?? "play_circle_filled_rounded";
    String selectedColor = existingData?['renk'] ?? "0xFFE57373";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: Container(
            width: 1100,
            height: 850,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
            child: Row(
              children: [
                // Sol Panel: Canlı Önizleme
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.grey.shade50),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("CANLI ÖNİZLEME", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 12)),
                        const SizedBox(height: 30),
                        ValueListenableBuilder(
                          valueListenable: uC,
                          builder: (context, value, child) {
                            final String id = _extractYoutubeId(uC.text);
                            return Container(
                              width: 320, height: 180,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
                              ),
                              child: _buildThumbnailImage(id),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Text("Seçilen Renk: ", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        Container(width: 40, height: 5, decoration: BoxDecoration(color: Color(int.parse(selectedColor)), borderRadius: BorderRadius.circular(10))),
                      ],
                    ),
                  ),
                ),
                // Sağ Panel: Veri Giriş Formu
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(docId == null ? "Yeni Video" : "Düzenle", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                              const CloseButton(),
                            ],
                          ),
                          const SizedBox(height: 30),
                          _buildStudioField(tC, "Başlık", Icons.title_rounded, hint: "Akran Zorbalığı | Sessiz Çığlık"),
                          const SizedBox(height: 15),
                          _buildStudioField(sC, "Alt Başlık", Icons.subtitles_rounded, hint: "İzle ve farkındalık kazan."),
                          const SizedBox(height: 15),
                          _buildStudioField(aC, "Açıklama", Icons.description_rounded, maxLines: 3, hint: "Sessiz kalma, sesini yükselt!"),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(child: _buildStudioField(uC, "YouTube Linki / ID", Icons.link_rounded)),
                              const SizedBox(width: 15),
                              SizedBox(width: 120, child: _buildStudioField(durC, "Süre", Icons.timer_rounded, hint: "02:58")),
                            ],
                          ),
                          const SizedBox(height: 25),
                          const Text("RENK SEÇİMİ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                          const SizedBox(height: 10),
                          _buildColorRow(selectedColor, (val) => setDialogState(() => selectedColor = val)),
                          const SizedBox(height: 25),
                          const Text("İKON SEÇİMİ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                          const SizedBox(height: 10),
                          _buildIconRow(selectedIcon, (val) => setDialogState(() => selectedIcon = val)),
                          const SizedBox(height: 40),
                          _buildDialogButtons(docId, tC, sC, aC, uC, durC, selectedIcon, selectedColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI YARDIMCILARI ---
  Widget _buildColorRow(String current, Function(String) onSelect) {
    final List<String> colors = ["0xFFE57373", "0xFF81C784", "0xFF64B5F6", "0xFFFFD54F", "0xFF9575CD", "0xFF4DB6AC"];
    return Row(
      children: colors.map((c) => GestureDetector(
        onTap: () => onSelect(c),
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          width: 35, height: 35,
          decoration: BoxDecoration(
            color: Color(int.parse(c)),
            shape: BoxShape.circle,
            border: current == c ? Border.all(color: Colors.black, width: 3) : null,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildIconRow(String current, Function(String) onSelect) {
    final Map<String, IconData> icons = {
      "play_circle_filled_rounded": Icons.play_circle_filled_rounded,
      "school_rounded": Icons.school_rounded,
      "psychology_rounded": Icons.psychology_rounded,
      "security_rounded": Icons.security_rounded,
      "star_rounded": Icons.star_rounded,
    };
    return Row(
      children: icons.entries.map((e) => IconButton(
        icon: Icon(e.value, color: current == e.key ? Colors.redAccent : Colors.grey.shade400, size: 30),
        onPressed: () => onSelect(e.key),
      )).toList(),
    );
  }

  Widget _buildStudioField(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.redAccent, size: 20),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
          ),
        ),
      ],
    );
  }

  // --- CRUD İŞLEMLERİ (Kaydetme Butonları) ---
  Widget _buildDialogButtons(String? id, TextEditingController t, TextEditingController s, TextEditingController a, TextEditingController u, TextEditingController d, String icon, String color) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(22), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            child: const Text("İPTAL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              if (t.text.isEmpty || u.text.isEmpty) return;
              // Linkten YouTube ID'sini çıkarıp Firestore'a kaydeder
              final String vidId = _extractYoutubeId(u.text);
              final data = {
                'baslik': t.text,
                'altBaslik': s.text,
                'aciklama': a.text,
                'url': u.text,
                'youtubeId': vidId,
                'sure': d.text,
                'ikon': icon,
                'renk': color,
                'kapakYolu': null,
                'eklenmeTarihi': id == null ? FieldValue.serverTimestamp() : (existingDataTimestamp(id)),
              };
              if (id == null) await _firestore.collection('videos').add(data);
              else await _firestore.collection('videos').doc(id).update(data);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.all(22), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            child: const Text("KAYDET VE YAYINLA", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // Ana sayfadaki her bir video kartını oluşturan yapı
  Widget _buildPremiumVideoCard(String docId, Map<String, dynamic> data, String videoId) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                _buildThumbnailImage(videoId), // YouTube üzerinden kapak görselini çeker
                _buildPlayOverlay(videoId),    // Tıklanıldığında YouTube'a yönlendirir
                Positioned(
                  top: 12, left: 12,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(int.parse(data['renk'] ?? "0xFFE57373")),
                    child: Icon(_getIconData(data['ikon']), color: Colors.white, size: 14),
                  ),
                ),
                Positioned(
                  top: 12, right: 12,
                  child: Row(
                    children: [
                      _circleActionBtn(Icons.edit_rounded, Colors.blue, () => _showVideoStudioDialog(docId: docId, existingData: data)),
                      const SizedBox(width: 8),
                      _circleActionBtn(Icons.delete_outline_rounded, Colors.redAccent, () => _deleteVideo(docId)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(data['baslik'] ?? "Başlıksız", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14), maxLines: 1),
                  const SizedBox(height: 4),
                  Text("${data['sure'] ?? '--:--'} • ${data['altBaslik'] ?? ''}", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 11), maxLines: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // YouTube resmî API'sini kullanarak videonun kapak fotoğrafını çeker
  Widget _buildThumbnailImage(String id) {
    return Container(
      width: double.infinity, height: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: id == "error"
            ? Container(color: Colors.grey.shade100, child: const Icon(Icons.videocam_off_rounded, color: Colors.grey, size: 40))
            : Image.network('https://img.youtube.com/vi/$id/0.jpg', fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade100)),
      ),
    );
  }

  // Videoya tıklandığında url_launcher paketi ile YouTube uygulamasını veya tarayıcıyı açar
  Widget _buildPlayOverlay(String id) {
    return Positioned.fill(
      child: InkWell(
        onTap: () async {
          final url = 'https://www.youtube.com/watch?v=$id';
          if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url));
        },
        child: Container(color: Colors.black12, child: const Center(child: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.play_arrow_rounded, color: Colors.redAccent)))),
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case "school_rounded": return Icons.school_rounded;
      case "psychology_rounded": return Icons.psychology_rounded;
      case "security_rounded": return Icons.security_rounded;
      case "star_rounded": return Icons.star_rounded;
      default: return Icons.play_circle_filled_rounded;
    }
  }

  dynamic existingDataTimestamp(String id) => FieldValue.serverTimestamp();

  Widget _circleActionBtn(IconData i, Color c, VoidCallback o) {
    return IconButton(onPressed: o, icon: Icon(i, color: c, size: 18), style: IconButton.styleFrom(backgroundColor: Colors.white, elevation: 4));
  }

  Widget _buildQuickStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('videos').snapshots(),
      builder: (context, snap) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Text("Sistemde ${snap.hasData ? snap.data!.docs.length : 0} aktif video tanımlı.", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
      ),
    );
  }

  // REGEX kullanarak standart YouTube URL'lerinden veya Shorts linklerinden sadece ID kısmını ayıklar
  String _extractYoutubeId(String? url) {
    if (url == null || url.isEmpty) return "error";
    if (url.length == 11) return url;
    RegExp regExp = RegExp(r'.*(?:(?:youtu\.be\/|v\/|vi\/|u\/\w\/|embed\/|shorts\/)|(?:(?:watch)?\?v(?:i)?=|\&v(?:i)?=))([^#\&\?]*).*');
    final match = regExp.firstMatch(url);
    return (match != null && match.groupCount >= 1) ? match.group(1)! : "error";
  }

  void _deleteVideo(String id) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Sil"), content: const Text("Bu video silinsin mi?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text("Hayır")),
        ElevatedButton(onPressed: () async { await _firestore.collection('videos').doc(id).delete(); Navigator.pop(c); }, child: const Text("Evet")),
      ],
    ));
  }

  Widget _buildEmptyState() => const Center(child: Text("Video bulunamadı."));
}