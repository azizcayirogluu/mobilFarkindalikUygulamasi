import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:zorbalik_uygulamasi/services/ai_analysis_service.dart';

class UserManager extends StatefulWidget {
  const UserManager({super.key});

  @override
  State<UserManager> createState() => _UserManagerState();
}

class _UserManagerState extends State<UserManager> {
  // Firestore veritabanı işlemlerini yönetmek için ana referans
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AiAnalysisService _aiAnalysisService = AiAnalysisService();
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 35),
            Expanded(
              // StreamBuilder: 'users' koleksiyonunu kayıt tarihine göre sıralı ve canlı olarak dinler
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .orderBy('kayitTarihi', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6366F1),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("Sistemde henüz bir kahraman bulunmuyor."),
                    );
                  }

                  final users = snapshot.data!.docs;

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final doc = users[index];
                      final userData = doc.data() as Map<String, dynamic>;

                      final String username =
                          userData['kullaniciAdi'] ?? "İsimsiz";
                      final String yasGrubu = userData['yasGrubu'] ?? "-";
                      final String uid = doc
                          .id; // Doküman silme ve analiz çekme işlemleri için ID'yi saklar
                      final bool isOnline = userData['isOnline'] ?? false;

                      // Timestamp verisini güvenli bir şekilde çekmek için çift isimli kontrol (sonGörülme/sonGorulme)
                      final dynamic rawLastSeen =
                          userData['sonGörülme'] ?? userData['sonGorulme'];
                      final Timestamp? sonGorulme = rawLastSeen is Timestamp
                          ? rawLastSeen
                          : null;

                      return _buildUserCard(
                        username,
                        yasGrubu,
                        uid,
                        sonGorulme,
                      );
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
            const Text(
              "KAHRAMAN ANALİZİ",
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Sistemdeki kullanıcıların aktiflik ve gelişim durumları.",
              style: TextStyle(
                color: Colors.blueGrey.shade400,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        _buildTotalUserBadge(),
      ],
    );
  }

  // Her bir kullanıcı için oluşturulan liste elemanı
  Widget _buildUserCard(
    String username,
    String yas,
    String uid,
    Timestamp? sonGorulme,
  ) {
    String sonHareket = "Bilinmiyor";
    if (sonGorulme != null) {
      // Son görülme tarihini okunabilir formata çevirir
      sonHareket = DateFormat('dd/MM HH:mm').format(sonGorulme.toDate());
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.transparent, width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 25,
          vertical: 15,
        ),
        leading: Container(
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
            child: Text(
              username[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              username,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 19,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              _infoBadge(yas, Colors.orange),
              const SizedBox(width: 15),
              Icon(
                Icons.history_toggle_off_rounded,
                size: 14,
                color: Colors.blueGrey.shade300,
              ),
              const SizedBox(width: 5),
              Text(
                sonHareket,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blueGrey.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Analiz ikonuna basıldığında kullanıcının istatistiklerini getirir puan vs
            _actionIconButton(
              Icons.analytics_outlined,
              const Color(0xFF6366F1),
              () => _showUserAnalytics(username, uid),
            ),
            const SizedBox(width: 12),
            _actionIconButton(
              Icons.delete_outline_rounded,
              Colors.redAccent,
              () => _deleteUser(username, uid),
            ),
          ],
        ),
      ),
    );
  }

  // Seçili kullanıcının oyun gelişim verilerini (usersProgress) modal içinde gösterir
  void _showUserAnalytics(String username, String uid) {
    showDialog(
      context: context,
      builder: (context) => StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('usersProgress').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final stats = data['istatistikler'] ?? {};
          final karar = stats['karar_yapisi'] ?? {};
          final rozetler = data['rozetler'] as List? ?? [];
          final bolumler = data['tamamlanan_bolumler'] as List? ?? [];

          final riskDurumu = data['riskDurumu'] ?? 'BİLİNMİYOR';
          final riskNedeni =
              data['riskNedeni'] ??
              'Henüz yapay zeka tarafından analiz edilmedi.';

          return Dialog(
            backgroundColor: const Color(0xFFF8FAFC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(35),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              padding: const EdgeInsets.all(40),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _modalHeader(username),
                    const Divider(height: 40),
                    Wrap(
                      spacing: 30,
                      runSpacing: 30,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: [
                        SizedBox(
                          width: 500,
                          child: Column(
                            children: [
                              // Puan, süre ve hata gibi özet kutuları
                              Wrap(
                                spacing: 20,
                                runSpacing: 20,
                                children: [
                                  _premiumStatBox(
                                    "Toplam Puan",
                                    "${data['toplam_puan'] ?? 0}",
                                    Icons.bolt_rounded,
                                    Colors.orange,
                                  ),
                                  _premiumStatBox(
                                    "Eğitim Süresi",
                                    "${stats['toplam_sure_dk'] ?? 0} dk",
                                    Icons.timer_rounded,
                                    Colors.blue,
                                  ),
                                  _premiumStatBox(
                                    "Hatalı Karar",
                                    "${stats['hatali_cevaplar'] ?? 0}",
                                    Icons.error_outline_rounded,
                                    Colors.red,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),
                              // Empati, farkındalık gibi bar tipi analiz grafikleri
                              _buildCharacterChart(karar),
                              const SizedBox(height: 30),
                              _buildAIAnalysisSection(
                                uid,
                                riskDurumu,
                                riskNedeni,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 250,
                          child: _buildBadgeAndMissionList(
                            rozetler,
                            bolumler,
                          ), // Kazanılan rozetler ve bölümler
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCharacterChart(Map karar) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Gelişim Analiz Grafiği",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 25),
          // Bar değerlerini 0.0 - 1.0 arasına normalize ederek gösterir
          _skillBar(
            "Kullanıcıların Ortalama Empati Yeteneği",
            (karar['empati'] ?? 0) / 100,
            Colors.pinkAccent,
          ),
          _skillBar(
            "Kullanıcıların Ortalama Siber Farkındalığı",
            (karar['dikkat'] ?? 0) / 100,
            Colors.green,
          ),
          _skillBar(
            "Kullanıcıların Ortalama Yardımseverlik Oranı",
            (karar['yardim'] ?? 0) / 100,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysisSection(
    String uid,
    String riskDurumu,
    String riskNedeni,
  ) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline_rounded;
    if (riskDurumu == 'GÜVENLİ') {
      statusColor = Colors.green;
      statusIcon = Icons.shield_rounded;
    } else if (riskDurumu == 'OLABİLİR') {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_rounded;
    } else if (riskDurumu == 'TEHLİKEDE') {
      statusColor = Colors.redAccent;
      statusIcon = Icons.error_rounded;
    }

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 28),
                      const SizedBox(width: 10),
                      const Text(
                        "Yapay Zeka Risk Analizi",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  _isAnalyzing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : ElevatedButton.icon(
                          onPressed: () async {
                            setModalState(() => _isAnalyzing = true);
                            await _aiAnalysisService.kullaniciyiAnalizEt(uid);
                            setModalState(() => _isAnalyzing = false);
                          },
                          icon: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                          ),
                          label: const Text("Analiz Et"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    "Durum: ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      riskDurumu,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                riskNedeni,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _skillBar(String label, double val, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
              Text(
                "%${(val * 100).toInt()}",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: val.clamp(0.0, 1.0),
              backgroundColor: color.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeAndMissionList(List rozetler, List bolumler) {
    return Column(
      children: [
        _infoSection(
          "KAZANILAN ROZETLER",
          Icons.verified_rounded,
          rozetler,
          Colors.amber,
        ),
        const SizedBox(height: 20),
        _infoSection(
          "TAMAMLANAN GÖREVLER",
          Icons.task_alt_rounded,
          bolumler,
          Colors.green,
        ),
      ],
    );
  }

  Widget _infoSection(String title, IconData icon, List items, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: color,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          items.isEmpty
              ? Text(
                  "Henüz veri yok.",
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: items
                      .map((i) => _badge(i.toString(), color))
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _premiumStatBox(String t, String v, IconData i, Color c) {
    return Container(
      width:
          140, // Expanded yerine sabit genişlik verildi ki Wrap içinde düzgün aksın
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(i, color: c, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            v,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: Color(0xFF1E293B),
            ),
          ),
          Text(
            t,
            style: TextStyle(
              color: Colors.blueGrey.shade300,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _actionIconButton(IconData i, Color c, VoidCallback t) {
    return Container(
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
      ),
      child: IconButton(
        onPressed: t,
        icon: Icon(i, color: c, size: 22),
        hoverColor: c.withOpacity(0.15),
      ),
    );
  }



  Widget _infoBadge(String t, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        t,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _badge(String t, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        t.toUpperCase(),
        style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 10),
      ),
    );
  }

  // Toplam kullanıcı sayısını takip eden sağ üst köşedeki alan
  Widget _buildTotalUserBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20),
          ],
        ),
        child: Text(
          "Toplam ${s.hasData ? s.data!.docs.length : 0} Kahraman",
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF6366F1),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _modalHeader(String u) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              u.toUpperCase(),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
            ),
            const Text(
              "Detaylı Performans Analizi",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        const CloseButton(),
      ],
    );
  }

  // Kullanıcıyı hem 'users' hem de 'usersProgress' koleksiyonlarından kalıcı olarak siler
  void _deleteUser(String username, String uid) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Kullanıcıyı Sil"),
        content: Text(
          "$username kullanıcısını ve tüm verilerini sistemden silmek istediğinize emin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("VAZGEÇ"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              // İki farklı koleksiyondaki veriyi asenkron olarak temizler
              await _firestore.collection('users').doc(uid).delete();
              await _firestore.collection('usersProgress').doc(uid).delete();
              Navigator.pop(c);
            },
            child: const Text("SİL"),
          ),
        ],
      ),
    );
  }
}
