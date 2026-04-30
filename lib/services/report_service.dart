import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Tüm veritabanı verilerini toplayıp PDF raporu oluşturur ve yazdırma ekranını açar.
  Future<void> sistemRaporuOlustur() async {
    final pdf = pw.Document();

    try {
      // Firestore'daki ilgili tüm koleksiyonlardan ham verileri çek
      final progressSnap = await _db.collection('usersProgress').get();
      final usersSnap = await _db.collection('users').get();
      final storiesSnap = await _db.collection('stories').get();
      final scenariosSnap = await _db.collection('scenarios').get();
      final videosSnap = await _db.collection('videos').get();

      // SAYAÇLAR
      int toplamHata = 0;
      int toplamSure = 0;
      int toplamPuan = 0;
      int toplamRozet = 0;
      int toplamEmpati = 0;
      int toplamDikkat = 0;
      int toplamYardim = 0;

      int guvenliSayisi = 0;
      int riskliSayisi = 0;
      int tehlikedeSayisi = 0;

      // Tehlikede olan kullanıcıların listesi
      List<Map<String, dynamic>> tehlikeliKullanicilar = [];

      // Performans için ilerleme verilerini UID üzerinden eşleşecek şekilde bir haritaya (Map) dönüştürür.
      Map<String, dynamic> progressMap = {
        for (var doc in progressSnap.docs) doc.id: doc.data()
      };

      // VERİ İŞLEME DÖNGÜSÜ
      for (var userDoc in usersSnap.docs) {
        final uid = userDoc.id;
        final userData = userDoc.data();
        final String kullaniciAdi = userData['kullaniciAdi'] ?? "Bilinmiyor";

        final progressData = progressMap[uid] ?? {};
        final stats = progressData['istatistikler'] ?? {};
        final karar = stats['karar_yapisi'] ?? {};
        final rozetler = progressData['rozetler'] as List? ?? [];

        toplamHata += (stats['hatali_cevaplar'] as int? ?? 0);
        toplamSure += (stats['toplam_sure_dk'] as int? ?? 0);
        toplamPuan += (progressData['toplam_puan'] as int? ?? 0);
        toplamRozet += rozetler.length;

        toplamEmpati += (karar['empati'] as int? ?? 0);
        toplamDikkat += (karar['dikkat'] as int? ?? 0);
        toplamYardim += (karar['yardim'] as int? ?? 0);

        // Risk Analizi
        final riskDurumu = progressData['riskDurumu'] ?? 'BILINMIYOR';
        final riskNedeni = progressData['riskNedeni'] ?? '-';

        if (riskDurumu == 'GUVENLI') {
          guvenliSayisi++;
        } else if (riskDurumu == 'OLABILIR') {
          riskliSayisi++;
        } else if (riskDurumu == 'TEHLIKEDE') {
          tehlikedeSayisi++;
          tehlikeliKullanicilar.add({
            'kullaniciAdi': kullaniciAdi,
            'riskNedeni': riskNedeni,
          });
        }
      }

      // SENARYO ANALİZİ
      int toplamSoruSayisi = 0;
      for (var doc in scenariosSnap.docs) {
        final bolumler = (doc.data()['bolumler'] as List? ?? []);
        for (var bolum in bolumler) {
          toplamSoruSayisi += (bolum['sorular'] as List? ?? []).length;
        }
      }

      int userCount = usersSnap.docs.isNotEmpty ? usersSnap.docs.length : 1;

      // Ortalama beceriler hesaplanıyor
      double ortEmpati = (toplamEmpati / userCount);
      double ortDikkat = (toplamDikkat / userCount);
      double ortYardim = (toplamYardim / userCount);

      // En zayıf yeteneği bulma
      String zayifYetenek = "Siber Farkındalık (Dikkat)";
      double minDeger = ortDikkat;

      if (ortEmpati < minDeger) {
        minDeger = ortEmpati;
        zayifYetenek = "Empati ve İletişim";
      }
      if (ortYardim < minDeger) {
        minDeger = ortYardim;
        zayifYetenek = "Yardımseverlik (Müdahale)";
      }

      String zayifYonetimMesaji =
          "Sistem genelinde öğrencilerin en çok zorlandığı alan **$zayifYetenek** becerisidir. Platforma bu konuyla alakalı daha fazla senaryo ve hikaye eklemeniz önerilir.";

      // PDF SAYFA OLUŞTURMA
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) => _buildHeader(),
          build: (pw.Context context) {
            return [
              _buildSectionTitle("1. SİSTEM GENEL ENVANTERİ"),
              _buildInventoryTable(
                usersSnap,
                scenariosSnap,
                storiesSnap,
                videosSnap,
                toplamSoruSayisi,
              ),
              pw.SizedBox(height: 20),

              _buildSectionTitle("2. ETKİLEŞİM VE BAŞARI ANALİZİ"),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _pdfStatBox(
                      "Toplam Puan",
                      "$toplamPuan TP",
                      PdfColors.orange700,
                    ),
                  ),
                  pw.Expanded(
                    child: _pdfStatBox(
                      "Toplam Süre",
                      "$toplamSure dk",
                      PdfColors.blue700,
                    ),
                  ),
                  pw.Expanded(
                    child: _pdfStatBox(
                      "Dağıtılan Rozet",
                      "$toplamRozet Adet",
                      PdfColors.amber700,
                    ),
                  ),
                  pw.Expanded(
                    child: _pdfStatBox(
                      "Toplam Hata",
                      "$toplamHata Kez",
                      PdfColors.red700,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 15),
              _pdfProgressBar("Ortalama Empati Yeteneği", ortEmpati / 100, PdfColors.pink),
              _pdfProgressBar(
                "Ortalama Siber Dikkat & Farkındalık",
                ortDikkat / 100,
                PdfColors.green,
              ),
              _pdfProgressBar("Ortalama Yardımseverlik", ortYardim / 100, PdfColors.orange),

              // Zayıf yön çıkarımı (AI Insight)
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 15),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  border: pw.Border.all(color: PdfColors.blue200),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("💡  ", style: const pw.TextStyle(fontSize: 14)),
                    pw.Expanded(
                      child: pw.Text(
                        zayifYonetimMesaji,
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.blue900),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              _buildSectionTitle("3. SİBER GÜVENLİK VE YAPAY ZEKA RİSK ÖZETİ"),
              pw.Text(
                "Siber Asistan (Yapay Zeka), tüm kullanıcıların uygulama içi hatalarını ve sohbet geçmişlerini analiz ederek aşağıdaki risk dağılımını tespit etmiştir:",
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _pdfRiskBox("GÜVENLİ", "$guvenliSayisi öğrenci", PdfColors.green),
                  ),
                  pw.Expanded(
                    child: _pdfRiskBox("OLABİLİR (RİSKLİ)", "$riskliSayisi öğrenci", PdfColors.orange),
                  ),
                  pw.Expanded(
                    child: _pdfRiskBox("TEHLİKEDE!", "$tehlikedeSayisi öğrenci", PdfColors.red),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Acil Müdahale Tablosu
              if (tehlikeliKullanicilar.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red50,
                    border: pw.Border.all(color: PdfColors.red),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "⚠️ ACİL MÜDAHALE GEREKTİREN KULLANICILAR",
                        style: pw.TextStyle(
                          color: PdfColors.red900,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.TableHelper.fromTextArray(
                        headerStyle: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 10,
                        ),
                        headerDecoration: const pw.BoxDecoration(color: PdfColors.red800),
                        cellStyle: const pw.TextStyle(fontSize: 9),
                        data: <List<String>>[
                          ['Kullanıcı Adı', 'Yapay Zeka Risk Nedeni (Açıklama)'],
                          for (var t in tehlikeliKullanicilar)
                            [t['kullaniciAdi']!, t['riskNedeni']!],
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
              ],

              pw.NewPage(),
              _buildSectionTitle("4. DETAYLI KULLANICI İZLEME RAPORU"),
              _buildUserDetailTable(usersSnap, progressMap),

              pw.SizedBox(height: 30),
              pw.Divider(color: PdfColors.grey400),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  "Zorbalık Farkındalık Platformu - Güncel Veritabanı Analiz Çıktısı: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}",
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ),
            ];
          },
          footer: (pw.Context context) => _buildFooter(context),
        ),
      );

      // Oluşturulan PDF'i cihaza sunar.
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name:
            'SiberKahraman_Sistem_Analizi_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      debugPrint("Rapor Hatası: $e");
    }
  }

  pw.Widget _buildHeader() {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.indigo900, width: 2)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 10),
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "SİBER KAHRAMAN YÖNETİM RAPORU",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 18,
                  color: PdfColors.indigo900,
                ),
              ),
              pw.Text(
                "Kapsamlı Sistem & Psikolojik Analiz Çıktısı",
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Text(
            DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 14,
          color: PdfColors.indigo800,
        ),
      ),
    );
  }

  pw.Widget _buildInventoryTable(
    QuerySnapshot users,
    QuerySnapshot scenarios,
    QuerySnapshot stories,
    QuerySnapshot videos,
    int soruCount,
  ) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo700),
      cellHeight: 25,
      data: <List<String>>[
        ['Varlık Tipi', 'Sistemdeki Toplam Miktar'],
        ['Kayıtlı öğrenciler / Kahramanlar', '${users.docs.length} Kişi'],
        ['Eğitim Senaryoları', '${scenarios.docs.length} Senaryo'],
        ['Toplam Soru Havuzu', '$soruCount Soru'],
        ['Eğitici Hikayeler', '${stories.docs.length} Hikaye'],
        ['Eğitim Videoları', '${videos.docs.length} Video'],
      ],
    );
  }

  pw.Widget _buildUserDetailTable(QuerySnapshot usersSnap, Map<String, dynamic> progressMap) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo800),
      cellStyle: const pw.TextStyle(fontSize: 8),
      data: <List<String>>[
        ['Kullanıcı Adı', 'YZ Risk Durumu', 'Kazanılan Rozet', 'Toplam Puan', 'Süre', 'Son Görülme'],
        for (var userDoc in usersSnap.docs) _generateUserRow(userDoc, progressMap[userDoc.id]),
      ],
    );
  }

  List<String> _generateUserRow(DocumentSnapshot userDoc, dynamic progressData) {
    final userData = userDoc.data() as Map<String, dynamic>;
    final String kullaniciAdi = userData['kullaniciAdi'] ?? "Bilinmiyor";
    final dynamic rawLastSeen = userData['sonGorulme'];

    final String risk =
        progressData != null ? (progressData['riskDurumu'] ?? "BILINMIYOR") : "BILINMIYOR";
    final String rozet = progressData != null ? "${(progressData['rozetler'] as List? ?? []).length}" : "0";
    final String puan = progressData != null ? "${progressData['toplam_puan'] ?? 0}" : "0";
    final String sure =
        progressData != null ? "${progressData['istatistikler']?['toplam_sure_dk'] ?? 0} dk" : "0 dk";

    String sonHareketStr = "Bilinmiyor";

    if (rawLastSeen != null) {
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
        sonHareketStr = "Hata";
      }
    }

    return [kullaniciAdi, risk, rozet, puan, sure, sonHareketStr];
  }

  pw.Widget _pdfStatBox(String label, String value, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.all(4),
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 1.5),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfRiskBox(String label, String value, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.all(4),
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfProgressBar(String label, double val, PdfColor color) {
    final double clampedVal = val.clamp(0.0, 1.0);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.Text(
                "${(clampedVal * 100).toInt()}%",
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            height: 8,
            width: double.infinity,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Container(
                width: 480.0 * clampedVal, // Sayfa genişliğine göre orantılanmış genişlik.
                height: 8,
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
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
      child: pw.Text(
        "Sayfa ${context.pageNumber} / ${context.pagesCount}",
        style: const pw.TextStyle(color: PdfColors.grey, fontSize: 8),
      ),
    );
  }
}
