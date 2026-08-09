import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- YENİ ÖZELLİK: OLAY BİLDİRİMİ ---
  Future<bool> olayBildir({
    required String baslik,
    required String detay,
    required String konum,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      await _db.collection('reports').add({
        // Security rules bind this immutable reporter identity to the signed-in user.
        'reporterId': user.uid,
        'uid': user.uid,
        'kullaniciAdi': user.displayName ?? 'Bilinmiyor',
        'baslik': baslik,
        'detay': detay,
        'konum': konum,
        'tarih': FieldValue.serverTimestamp(),
        'durum': 'YENİ',
      });
      return true;
    } catch (e) {
      debugPrint("Olay bildirme hatası: $e");
      return false;
    }
  }

  // --- MEVCUT PDF RAPORU OLUŞTURMA ---
  Future<void> sistemRaporuOlustur() async {
    final pdf = pw.Document();
    final DateTime now = DateTime.now();
    final String formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(now);

    final turkishFont = await PdfGoogleFonts.robotoRegular();
    final turkishFontBold = await PdfGoogleFonts.robotoBold();

    try {
      final resultsCounts = await Future.wait([
        _db.collection('users').count().get(),
        _db.collection('scenarios').count().get(),
        _db.collection('stories').count().get(),
        _db.collection('videos').count().get(),
      ]);

      final int totalUsers = resultsCounts[0].count ?? 0;
      final int totalScenarios = resultsCounts[1].count ?? 0;
      final int totalStories = resultsCounts[2].count ?? 0;
      final int totalVideos = resultsCounts[3].count ?? 0;

      final dangerSnap = await _db.collection('usersProgress').where('riskDurumu', isEqualTo: 'TEHLİKELİ').get();
      final riskySnap = await _db.collection('usersProgress').where('riskDurumu', isEqualTo: 'RİSKLİ').get();
      
      final activeUsersSnap = await _db.collection('users').orderBy('sonGorulme', descending: true).limit(50).get();
      final List<String> uids = activeUsersSnap.docs.map((d) => d.id).toList();
      
      Map<String, dynamic> progressMap = {};
      if (uids.isNotEmpty) {
        // Firestore `whereIn` supports at most 30 values. Keep the admin PDF
        // report resilient when the active-user window is larger than that.
        for (var start = 0; start < uids.length; start += 30) {
          final end = (start + 30 < uids.length) ? start + 30 : uids.length;
          final progressSnap = await _db
              .collection('usersProgress')
              .where(FieldPath.documentId, whereIn: uids.sublist(start, end))
              .get();
          for (final doc in progressSnap.docs) {
            progressMap[doc.id] = doc.data();
          }
        }
      }

      int totalPoints = 0;
      int totalBadges = 0;
      int totalErrors = 0;
      
      for (var data in progressMap.values) {
        totalPoints += (data['toplam_puan'] as int? ?? 0);
        totalBadges += (data['rozetler'] as List? ?? []).length;
        totalErrors += (data['istatistikler']?['hatali_cevaplar'] as int? ?? 0);
      }

      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(base: turkishFont, bold: turkishFontBold),
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => _buildHeader(formattedDate),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            _buildSectionTitle("1. YÖNETİCİ ÖZETİ"),
            _buildSummaryGrid(totalUsers, totalScenarios, totalStories, totalVideos),
            pw.SizedBox(height: 30),
            _buildSectionTitle("2. PERFORMANS METRİKLERİ (Son 50 Kullanıcı)"),
            _buildStatRow(totalPoints, totalBadges, totalErrors),
            pw.SizedBox(height: 30),
            _buildSectionTitle("3. GÜVENLİK VE RİSK ANALİZİ"),
            _buildRiskDistribution(totalUsers, dangerSnap.docs.length, riskySnap.docs.length),
            pw.SizedBox(height: 20),
            if (dangerSnap.docs.isNotEmpty) _buildDangerTable(dangerSnap.docs),
            pw.SizedBox(height: 30),
            pw.NewPage(),
            _buildSectionTitle("4. DETAYLI KULLANICI İZLEME LİSTESİ"),
            _buildUserTable(activeUsersSnap.docs, progressMap),
            pw.SizedBox(height: 40),
            _buildFinalNote(formattedDate),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'KahramanDostum_Rapor.pdf');
    } catch (e) {
      debugPrint("PDF Rapor Hatası: $e");
    }
  }

  pw.Widget _buildHeader(String date) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      margin: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue900, width: 2.5))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("KAHRAMAN DOSTUM", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.Text("Sistem Operasyon ve Güvenlik Analizi Raporu", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text("Rapor Tarihi", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text(date, style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: const pw.BoxDecoration(color: PdfColors.blue50, borderRadius: pw.BorderRadius.all(pw.Radius.circular(4))),
        child: pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
      ),
    );
  }

  pw.Widget _buildSummaryGrid(int u, int s, int st, int v) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _summaryBox("Toplam Kahraman", "$u", PdfColors.blue700),
        _summaryBox("Aktif Senaryo", "$s", PdfColors.indigo700),
        _summaryBox("Hikaye Sayısı", "$st", PdfColors.orange700),
        _summaryBox("Eğitim Videosu", "$v", PdfColors.pink700),
      ],
    );
  }

  pw.Widget _summaryBox(String label, String value, PdfColor color) {
    return pw.Container(
      width: 110, padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
          pw.SizedBox(height: 4),
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.white), textAlign: pw.TextAlign.center),
        ],
      ),
    );
  }

  pw.Widget _buildStatRow(int p, int b, int e) {
    return pw.Row(
      children: [
        pw.Expanded(child: _detailStatBox("Toplam Puan", "$p TP", PdfColors.amber700)),
        pw.SizedBox(width: 15),
        pw.Expanded(child: _detailStatBox("Kazanılan Rozet", "$b Adet", PdfColors.purple700)),
        pw.SizedBox(width: 15),
        pw.Expanded(child: _detailStatBox("Toplam Hata", "$e Kez", PdfColors.red700)),
      ],
    );
  }

  pw.Widget _detailStatBox(String l, String v, PdfColor c) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: c, width: 1.5), borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Column(
        children: [
          pw.Text(v, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: c)),
          pw.Text(l, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
        ],
      ),
    );
  }

  pw.Widget _buildRiskDistribution(int total, int danger, int risky) {
    int safe = total - danger - risky;
    return pw.Row(
      children: [
        pw.Expanded(child: _riskBar("GÜVENLİ", safe, total, PdfColors.green700)),
        pw.SizedBox(width: 10),
        pw.Expanded(child: _riskBar("RİSKLİ", risky, total, PdfColors.orange700)),
        pw.SizedBox(width: 10),
        pw.Expanded(child: _riskBar("TEHLİKELİ", danger, total, PdfColors.red700)),
      ],
    );
  }

  pw.Widget _riskBar(String l, int v, int t, PdfColor c) {
    double percent = t > 0 ? v / t : 0;
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Column(
        children: [
          pw.Text(l, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: c)),
          pw.SizedBox(height: 5),
          pw.Text("$v Kişi", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Text("%${(percent * 100).toInt()}", style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  pw.Widget _buildDangerTable(List<DocumentSnapshot> docs) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: PdfColors.red50, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("⚠️ ACİL MÜDAHALE GEREKTİREN VAKALAR", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.red900)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.red800),
            cellStyle: const pw.TextStyle(fontSize: 7),
            data: [
              ['Kahraman Adı', 'Risk Nedeni'],
              for (var doc in docs) [doc.get('kullaniciAdi') ?? 'Bilinmiyor', doc.get('riskNedeni') ?? '-'],
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildUserTable(List<DocumentSnapshot> users, Map<String, dynamic> progress) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
      cellStyle: const pw.TextStyle(fontSize: 8),
      data: [
        ['Adı', 'Risk Durumu', 'Puan', 'Rozet', 'Son Görülme'],
        for (var user in users) _buildUserRow(user, progress[user.id]),
      ],
    );
  }

  List<String> _buildUserRow(DocumentSnapshot user, dynamic prog) {
    final name = user.get('kullaniciAdi') ?? 'İsimsiz';
    String lastSeen = '-';
    if (user.get('sonGorulme') != null) {
      try {
        lastSeen = DateFormat('dd/MM HH:mm').format((user.get('sonGorulme') as Timestamp).toDate());
      } catch (e) {}
    }
    if (prog == null) return [name, 'Veri Yok', '0', '0', lastSeen];
    return [name, prog['riskDurumu'] ?? 'BELİRSİZ', "${prog['toplam_puan'] ?? 0}", "${(prog['rozetler'] as List? ?? []).length}", lastSeen];
  }

  pw.Widget _buildFinalNote(String date) {
    return pw.Align(alignment: pw.Alignment.center, child: pw.Column(children: [pw.Divider(color: PdfColors.grey300), pw.Text("Bu rapor Kahraman Dostum CMS tarafından otomatik olarak oluşturulmuştur.", style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)), pw.Text("Oluşturma Tarihi: $date", style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600))]));
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(alignment: pw.Alignment.centerRight, margin: const pw.EdgeInsets.only(top: 20), child: pw.Text("Sayfa ${context.pageNumber} / ${context.pagesCount}", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)));
  }
}
