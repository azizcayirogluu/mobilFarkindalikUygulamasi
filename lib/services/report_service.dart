import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  //Tüm veritabanı verilerini toplayıp PDF raporu oluşturur ve yazdırma ekranını aç.
  Future<void> sistemRaporuOlustur() async {
    final pdf = pw.Document();

    try {
      //Firestore'daki ilgili tüm koleksiyonlardan ham veriler çek
      final progressSnap = await _db.collection('usersProgress').get();
      final usersSnap = await _db.collection('users').get();
      final storiesSnap = await _db.collection('stories').get();
      final scenariosSnap = await _db.collection('scenarios').get();
      final videosSnap = await _db.collection('videos').get();

      // SAYAÇLAR: Raporun istatistik bölümünde kullanılacak toplam değerlerin tutulduğu değişkenler.
      int toplamHata = 0;
      int toplamSure = 0;
      int toplamPuan = 0;
      int toplamOkunanHikaye = 0;
      int toplamEmpati = 0;
      int toplamDikkat = 0;
      int toplamYardim = 0;

      // VERİ İŞLEME DÖNGÜSÜ: Her kullanıcının ilerleme verisi tek tek analiz edilir.
      for (var doc in progressSnap.docs) {
        final data = doc.data();
        final stats = data['istatistikler'] ?? {};
        final karar = stats['karar_yapisi'] ?? {};

        toplamHata += (stats['hatali_cevaplar'] as int? ?? 0);
        toplamSure += (stats['toplam_sure_dk'] as int? ?? 0);
        toplamPuan += (data['toplam_puan'] as int? ?? 0);
        toplamOkunanHikaye += (data['okunan_hikayeler'] as List? ?? []).length;

        // Karar yapısı altındaki puanlar (empati, dikkat vb.) toplama eklenir.
        toplamEmpati += (karar['empati'] as int? ?? 0);
        toplamDikkat += (karar['dikkat'] as int? ?? 0);
        toplamYardim += (karar['yardim'] as int? ?? 0);
      }

      // SENARYO ANALİZİ: Mevcut senaryolardaki toplam soru sayısı hesaplanır.
      int toplamSoruSayisi = 0;
      for (var doc in scenariosSnap.docs) {
        final bolumler = (doc.data()['bolumler'] as List? ?? []);
        for (var bolum in bolumler) {
          toplamSoruSayisi += (bolum['sorular'] as List? ?? []).length;
        }
      }

      // Ortalama hesaplama için kullanıcı sayısı alınır (Sıfıra bölünme hatası engellenir).
      int userCount = usersSnap.docs.isNotEmpty ? usersSnap.docs.length : 1;

      // PDF SAYFA OLUŞTURMA: Çok sayfalı (MultiPage) yapı ile içerik sığmadığında otomatik yeni sayfaya geçer.
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) => _buildHeader(), // Her sayfanın üst başlığı
          build: (pw.Context context) {
            return [
              _buildSectionTitle("1. SISTEM GENEL ENVANTERI"),
              _buildInventoryTable(usersSnap, scenariosSnap, storiesSnap, videosSnap, toplamSoruSayisi),
              pw.SizedBox(height: 20),

              _buildSectionTitle("2. ETKILESIM VE BASARI ANALIZI"),
              pw.Row(
                children: [
                  pw.Expanded(child: _pdfStatBox("Toplam Puan", "$toplamPuan TP")),
                  pw.Expanded(child: _pdfStatBox("Toplam Süre", "$toplamSure dk")),
                  pw.Expanded(child: _pdfStatBox("Toplam Hata", "$toplamHata")),
                ],
              ),
              pw.SizedBox(height: 10),
              _pdfProgressBar("Ortalama Empati", (toplamEmpati / userCount) / 100),
              _pdfProgressBar("Ortalama Siber Dikkat", (toplamDikkat / userCount) / 100),
              _pdfProgressBar("Ortalama Yardimseverlik", (toplamYardim / userCount) / 100),
              pw.SizedBox(height: 20),

              pw.NewPage(),
              _buildSectionTitle("3. DETAYLI KULLANICI IZLEME RAPORU"),
              _buildUserDetailTable(usersSnap, progressSnap),

              pw.SizedBox(height: 30),
              pw.Divider(color: PdfColors.grey400),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                    "Zorbalik Farkindalik Platformu - Güncel Veritabani Analiz Ciktisi: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}",
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ),
            ];
          },
          footer: (pw.Context context) => _buildFooter(context),
        ),
      );

      //Oluşturulan PDF'i cihaza sunar.
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'sistem_analizi_raporu_${DateFormat('dd_MM_yyyy_HH_mm').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      print("Rapor Hatası: $e");
    }
  }

  // Tasarım ve logo (varsa) kısmını yöneten widget.
  pw.Widget _buildHeader() {
    return pw.Container(
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue900, width: 2))),
      padding: const pw.EdgeInsets.only(bottom: 10),
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Zorbalik Farkindalik Sistem Analiz Raporu", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColors.blue900)),
              pw.Text("Kapsamli Sistem & Kullanici Raporu", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            ],
          ),
          pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()), style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blue800)),
    );
  }

  //Sistemdeki toplam içerik miktarını listeleyen tablo.
  pw.Widget _buildInventoryTable(users, scenarios, stories, videos, soruCount) {
    return pw.Table.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
      data: <List<String>>[
        ['Varlik Tipi', 'Miktar'],
        ['Kayitli Kullanicilar', '${users.docs.length}'],
        ['Senaryolar', '${scenarios.docs.length}'],
        ['Toplam Soru Havuzu', '$soruCount Soru'],
        ['Egitici Hikayeler', '${stories.docs.length}'],
        ['Egitim Videolari', '${videos.docs.length}'],
      ],
    );
  }

  //Tüm kullanıcıların bireysel performans verilerini birleştirir.
  pw.Widget _buildUserDetailTable(QuerySnapshot usersSnap, QuerySnapshot progressSnap) {
    // Performans için ilerleme verilerini UID üzerinden eşleşecek şekilde bir haritaya (Map) dönüştürür.
    Map<String, dynamic> progressMap = {
      for (var doc in progressSnap.docs) doc.id: doc.data()
    };

    return pw.Table.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      cellStyle: const pw.TextStyle(fontSize: 8),
      data: <List<String>>[
        ['Kullanici Adi', 'Durum', 'Toplam Puan', 'Süre', 'Son Hareket'],
        for (var userDoc in usersSnap.docs)
          _generateUserRow(userDoc, progressMap[userDoc.id]),
      ],
    );
  }

  //Tek bir kullanıcının bilgilerini tablo satırı formatına getirir.
  List<String> _generateUserRow(DocumentSnapshot userDoc, dynamic progressData) {
    final userData = userDoc.data() as Map<String, dynamic>;

    final String kullaniciAdi = userData['kullaniciAdi'] ?? "Bilinmiyor";
    final bool isOnline = userData['isOnline'] ?? false;

    final dynamic rawLastSeen = userData['sonGorulme'];

    final String puan = progressData != null ? "${progressData['toplam_puan'] ?? 0}" : "0";
    final String sure = progressData != null ? "${progressData['istatistikler']?['toplam_sure_dk'] ?? 0} dk" : "0 dk";

    String sonHareketStr = "Bilinmiyor";

    //Son görülme zamanını okunabilir formata sokar.
    if (isOnline) {
      sonHareketStr = "Aktif (Simdi)";
    } else if (rawLastSeen != null) {
      try {
        DateTime date;
        if (rawLastSeen is Timestamp) {
          date = rawLastSeen.toDate();
        } else if (rawLastSeen is String) {
          date = DateTime.parse(rawLastSeen);
        } else {
          throw Exception("Bilinmeyen tip");
        }
        sonHareketStr = DateFormat('dd/MM HH:mm').format(date);
      } catch (e) {
        sonHareketStr = "Tarih Hatası";
      }
    }

    return [
      kullaniciAdi,
      isOnline ? "ONLINE" : "OFFLINE",
      puan,
      sure,
      sonHareketStr,
    ];
  }

  //Stilize edilmiş veri kutucuğu tasarımı.
  pw.Widget _pdfStatBox(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.all(5),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5)),
      child: pw.Column(
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        ],
      ),
    );
  }

  //Grafiksel ilerleme çubuğu çizimi.
  pw.Widget _pdfProgressBar(String label, double val) {
    final double clampedVal = val.clamp(0.0, 1.0);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
              pw.Text("${(clampedVal * 100).toInt()}%", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Container(
            height: 6,
            width: double.infinity,
            decoration: pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.circular(3)),
            child: pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Container(
                width: 480.0 * clampedVal, // Sayfa genişliğine göre orantılanmış genişlik.
                height: 6,
                decoration: pw.BoxDecoration(color: PdfColors.blue700, borderRadius: pw.BorderRadius.circular(3)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text("Sayfa ${context.pageNumber} / ${context.pagesCount}", style: const pw.TextStyle(color: PdfColors.grey, fontSize: 8)),
    );
  }
}