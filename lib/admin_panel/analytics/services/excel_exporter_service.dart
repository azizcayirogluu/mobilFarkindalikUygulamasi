import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../../services/file_saver/file_saver.dart' as saver;

class ExcelExportResult {
  final bool success;
  final String fileName;
  final String? filePathOrName;
  final String? errorMessage;

  ExcelExportResult({
    required this.success,
    required this.fileName,
    this.filePathOrName,
    this.errorMessage,
  });
}

class ExcelExporterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Firestore verilerini sorgulayarak Power Query / PivotTable uyumlu
  /// çok sayfalı (7 Sheet) Excel (.xlsx) dosyasını üretir ve indirir.
  Future<ExcelExportResult> generateAndExportAnalyticsReport({
    required DateTime startDate,
    required DateTime endDate,
    required String filterLabel,
  }) async {
    try {
      final excel = Excel.createExcel();

      // Varsayılan 'Sheet1' sayfasını sil veya yeniden adlandır
      const String defaultSheet = 'Sheet1';

      // 1. Yönetici Özeti (Executive Summary)
      final sheetSummary = excel['1_Yonetici_Ozeti'];
      excel.setDefaultSheet('1_Yonetici_Ozeti');
      if (excel.sheets.containsKey(defaultSheet)) {
        excel.delete(defaultSheet);
      }

      // Verileri Firestore'dan çek (Performans için batched get)
      final usersSnap = await _firestore.collection('users').get();
      final progressSnap = await _firestore.collection('usersProgress').get();
      final scenariosSnap = await _firestore.collection('scenarios').get();
      final storiesSnap = await _firestore.collection('stories').get();
      final videosSnap = await _firestore.collection('videos').get();
      final detectiveSnap = await _firestore.collection('detective_questions').get();
      final badgesSnap = await _firestore.collection('badges').get();

      final int totalUsers = usersSnap.docs.length;
      final int totalProgressDocs = progressSnap.docs.length;

      // Filtreleme tarih aralığındaki yeni kullanıcılar ve aktifler
      int newUsersCount = 0;
      int activeUsersCount = 0;
      int notificationsEnabledCount = 0;
      int group6to12Count = 0;
      int group13to18Count = 0;

      for (var doc in usersSnap.docs) {
        final data = doc.data();
        final kayitTarihi = (data['kayitTarihi'] as Timestamp?)?.toDate();
        final sonGorulme = (data['sonGorulme'] as Timestamp?)?.toDate();
        final bildirimAcik = data['bildirimlerAcik'] as bool? ?? false;
        final yasGrubu = data['yasGrubu']?.toString() ?? '6-12';

        if (kayitTarihi != null &&
            kayitTarihi.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            kayitTarihi.isBefore(endDate.add(const Duration(days: 1)))) {
          newUsersCount++;
        }

        if (sonGorulme != null &&
            sonGorulme.isAfter(startDate.subtract(const Duration(seconds: 1)))) {
          activeUsersCount++;
        }

        if (bildirimAcik) notificationsEnabledCount++;

        if (yasGrubu == '6-12') {
          group6to12Count++;
        } else {
          group13to18Count++;
        }
      }

      // İlerleme toplamları
      int totalScenarioCompletions = 0;
      int totalStoriesRead = 0;
      int totalVideosWatched = 0;
      int totalBadgesEarned = 0;
      int totalPointsEarned = 0;

      for (var doc in progressSnap.docs) {
        final data = doc.data();
        final senaryolar = (data['tamamlanan_senaryolar'] as List?)?.length ?? 0;
        final hikayeler = (data['okunan_hikayeler'] as List?)?.length ?? 0;
        final videolar = (data['izlenen_videolar'] as List?)?.length ?? 0;
        final rozetler = (data['rozetler'] as List?)?.length ?? 0;
        final puan = (data['puan'] as num?)?.toInt() ?? (data['toplam_puan'] as num?)?.toInt() ?? 0;

        totalScenarioCompletions += senaryolar;
        totalStoriesRead += hikayeler;
        totalVideosWatched += videolar;
        totalBadgesEarned += rozetler;
        totalPointsEarned += puan;
      }

      // --- SHEET 1: 1_Yonetici_Ozeti ---
      _buildSummarySheet(
        sheetSummary,
        filterLabel: filterLabel,
        startDate: startDate,
        endDate: endDate,
        totalUsers: totalUsers,
        newUsersCount: newUsersCount,
        activeUsersCount: activeUsersCount,
        notificationsEnabledCount: notificationsEnabledCount,
        group6to12Count: group6to12Count,
        group13to18Count: group13to18Count,
        totalScenarioCompletions: totalScenarioCompletions,
        totalStoriesRead: totalStoriesRead,
        totalVideosWatched: totalVideosWatched,
        totalBadgesEarned: totalBadgesEarned,
        totalPointsEarned: totalPointsEarned,
        totalScenarios: scenariosSnap.docs.length,
        totalStories: storiesSnap.docs.length,
        totalVideos: videosSnap.docs.length,
        totalDetectiveQuestions: detectiveSnap.docs.length,
        totalBadges: badgesSnap.docs.length,
      );

      // --- SHEET 2: 2_Kullanicilar_Ham_Veri ---
      final sheetUsers = excel['2_Kullanicilar_Ham_Veri'];
      _buildUsersRawSheet(sheetUsers, usersSnap.docs);

      // --- SHEET 3: 3_Ilerleme_Ham_Veri ---
      final sheetProgress = excel['3_Ilerleme_Ham_Veri'];
      _buildProgressRawSheet(sheetProgress, progressSnap.docs);

      // --- SHEET 4: 4_Senaryo_Katalogu ---
      final sheetScenarios = excel['4_Senaryo_Katalogu'];
      _buildScenariosSheet(sheetScenarios, scenariosSnap.docs);

      // --- SHEET 5: 5_Hikaye_Katalogu ---
      final sheetStories = excel['5_Hikaye_Katalogu'];
      _buildStoriesSheet(sheetStories, storiesSnap.docs);

      // --- SHEET 6: 6_Video_Katalogu ---
      final sheetVideos = excel['6_Video_Katalogu'];
      _buildVideosSheet(sheetVideos, videosSnap.docs);

      // --- SHEET 7: 7_Metrik_Dokumantasyonu_Eksikler ---
      final sheetDocs = excel['7_Metrik_Dokumantasyonu'];
      _buildMetricsDocsSheet(sheetDocs);

      // Dosya ismi oluştur: kahraman_dostum_analiz_YYYYMMDD.xlsx
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'kahraman_dostum_analiz_raporu_$dateStr.xlsx';

      // Excel verisini byte dizisine dönüştür
      final List<int>? fileBytes = excel.save();
      if (fileBytes == null || fileBytes.isEmpty) {
        return ExcelExportResult(
          success: false,
          fileName: fileName,
          errorMessage: 'Excel çıktısı üretilirken veri kodlanamadı.',
        );
      }

      // Kaydet / İndir
      final savedPath = await saver.saveAndShareBytes(
        fileName,
        fileBytes,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      return ExcelExportResult(
        success: true,
        fileName: fileName,
        filePathOrName: savedPath,
      );
    } catch (e, stack) {
      debugPrint("Excel İhracat Hatası: $e\n$stack");
      return ExcelExportResult(
        success: false,
        fileName: '',
        errorMessage: 'Excel raporu üretilirken hata oluştu: $e',
      );
    }
  }

  void _buildSummarySheet(
    Sheet sheet, {
    required String filterLabel,
    required DateTime startDate,
    required DateTime endDate,
    required int totalUsers,
    required int newUsersCount,
    required int activeUsersCount,
    required int notificationsEnabledCount,
    required int group6to12Count,
    required int group13to18Count,
    required int totalScenarioCompletions,
    required int totalStoriesRead,
    required int totalVideosWatched,
    required int totalBadgesEarned,
    required int totalPointsEarned,
    required int totalScenarios,
    required int totalStories,
    required int totalVideos,
    required int totalDetectiveQuestions,
    required int totalBadges,
  }) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    sheet.appendRow([
      TextCellValue('KAHRAMAN DOSTUM - YÖNETİCİ ÖZETİ VE PERFORMANS RAPORU'),
    ]);
    sheet.appendRow([TextCellValue('Rapor Tarihi: ${dateFormat.format(DateTime.now())}')]);
    sheet.appendRow([TextCellValue('Seçili Filtre Dönemi: $filterLabel (${DateFormat('dd.MM.yyyy').format(startDate)} - ${DateFormat('dd.MM.yyyy').format(endDate)})')]);
    sheet.appendRow([TextCellValue('')]);

    sheet.appendRow([TextCellValue('METRİK KATEGORİSİ'), TextCellValue('METRİK ADI'), TextCellValue('DEĞER'), TextCellValue('AÇIKLAMA')]);

    final rows = [
      ['Kullanıcı İstatistikleri', 'Toplam Kayıtlı Kullanıcı', totalUsers, 'Platforma kaydolmuş toplam kullanıcı sayısı'],
      ['Kullanıcı İstatistikleri', 'Seçili Dönem Yeni Kayıtlar', newUsersCount, 'Filtrelenen tarih aralığında kaydolan kullanıcılar'],
      ['Kullanıcı İstatistikleri', 'Aktif Kullanıcılar (Dönem İçi)', activeUsersCount, 'Filtrelenen tarih aralığında uygulamaya giren kullanıcılar'],
      ['Kullanıcı İstatistikleri', 'Bildirim İzin Oranı (%)', totalUsers > 0 ? '${((notificationsEnabledCount / totalUsers) * 100).toStringAsFixed(1)}%' : '0%', 'Bildirimleri açık olan kullanıcı yüzdesi'],
      ['Kullanıcı Demografisi', '6-12 Yaş Grubu Sayısı', group6to12Count, 'İlkokul / Ortaokul yaş grubu kullanıcı hacmi'],
      ['Kullanıcı Demografisi', '13-18 Yaş Grubu Sayısı', group13to18Count, 'Lise yaş grubu kullanıcı hacmi'],
      ['İçerik Etkileşimleri', 'Toplam Senaryo Tamamlama', totalScenarioCompletions, 'Kullanıcıların tamamladığı toplam senaryo sayısı'],
      ['İçerik Etkileşimleri', 'Toplam Okunan Hikaye', totalStoriesRead, 'Kullanıcıların bitirdiği toplam öykü sayısı'],
      ['İçerik Etkileşimleri', 'Toplam İzlenen Video', totalVideosWatched, 'Kullanıcıların izlediği toplam eğitim videosu'],
      ['Başarı & Puan', 'Kazanılan Toplam Rozet', totalBadgesEarned, 'Kullanıcılara dağıtılan toplam rozet adedi'],
      ['Başarı & Puan', 'Dağıtılan Toplam Puan', totalPointsEarned, 'Kullanıcıların kazandığı kümülatif puan'],
      ['Platform İçerik Hacmi', 'Katalog Senaryo Sayısı', totalScenarios, 'Sistemde tanımlı toplam senaryo'],
      ['Platform İçerik Hacmi', 'Katalog Hikaye Sayısı', totalStories, 'Sistemde tanımlı toplam öykü'],
      ['Platform İçerik Hacmi', 'Katalog Video Sayısı', totalVideos, 'Sistemde tanımlı toplam video'],
      ['Platform İçerik Hacmi', 'Siber Dedektif Soru Havuzu', totalDetectiveQuestions, 'Siber dedektif modülündeki soru sayısı'],
      ['Platform İçerik Hacmi', 'Tanımlı Rozet Türü Sayısı', totalBadges, 'Kazanılabilir farklı rozet türü sayısı'],
    ];

    for (var r in rows) {
      sheet.appendRow([
        TextCellValue(r[0].toString()),
        TextCellValue(r[1].toString()),
        r[2] is num ? IntCellValue(r[2] as int) : TextCellValue(r[2].toString()),
        TextCellValue(r[3].toString()),
      ]);
    }
  }

  void _buildUsersRawSheet(Sheet sheet, List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    sheet.appendRow([
      TextCellValue('Kullanici_ID'),
      TextCellValue('Kullanici_Adi'),
      TextCellValue('Yas_Grubu'),
      TextCellValue('Kayit_Tarihi'),
      TextCellValue('Son_Gorulme'),
      TextCellValue('Bildirim_Acik_Mi'),
      TextCellValue('Yonetici_Mi'),
      TextCellValue('Premium_Mu'),
    ]);

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    for (var doc in docs) {
      final data = doc.data();
      final kayitTarihi = (data['kayitTarihi'] as Timestamp?)?.toDate();
      final sonGorulme = (data['sonGorulme'] as Timestamp?)?.toDate();

      sheet.appendRow([
        TextCellValue(doc.id),
        TextCellValue(data['kullaniciAdi']?.toString() ?? 'Anonim'),
        TextCellValue(data['yasGrubu']?.toString() ?? '6-12'),
        TextCellValue(kayitTarihi != null ? dateFormat.format(kayitTarihi) : ''),
        TextCellValue(sonGorulme != null ? dateFormat.format(sonGorulme) : ''),
        TextCellValue((data['bildirimlerAcik'] as bool? ?? false) ? 'EVET' : 'HAYIR'),
        TextCellValue((data['isAdmin'] as bool? ?? false) ? 'EVET' : 'HAYIR'),
        TextCellValue((data['isPremium'] as bool? ?? false) ? 'EVET' : 'HAYIR'),
      ]);
    }
  }

  void _buildProgressRawSheet(Sheet sheet, List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    sheet.appendRow([
      TextCellValue('Kullanici_ID'),
      TextCellValue('Tamamlanan_Senaryo_Sayisi'),
      TextCellValue('Okunan_Hikaye_Sayisi'),
      TextCellValue('Izlenen_Video_Sayisi'),
      TextCellValue('Kazanilan_Rozet_Sayisi'),
      TextCellValue('Toplam_Puan'),
      TextCellValue('Toplam_Sure_Dk'),
      TextCellValue('Hatali_Cevap_Sayisi'),
      TextCellValue('Son_Islem_Tarihi'),
    ]);

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    for (var doc in docs) {
      final data = doc.data();
      final senaryolar = (data['tamamlanan_senaryolar'] as List?)?.length ?? 0;
      final hikayeler = (data['okunan_hikayeler'] as List?)?.length ?? 0;
      final videolar = (data['izlenen_videolar'] as List?)?.length ?? 0;
      final rozetler = (data['rozetler'] as List?)?.length ?? 0;
      final puan = (data['puan'] as num?)?.toInt() ?? (data['toplam_puan'] as num?)?.toInt() ?? 0;
      final istatistikler = data['istatistikler'] as Map<String, dynamic>?;
      final sureDk = (istatistikler?['toplam_sure_dk'] as num?)?.toInt() ?? 0;
      final hataliCevap = (istatistikler?['hatali_cevaplar'] as num?)?.toInt() ?? 0;
      final sonGuncelleme = (data['sonGuncelleme'] as Timestamp?)?.toDate();

      sheet.appendRow([
        TextCellValue(doc.id),
        IntCellValue(senaryolar),
        IntCellValue(hikayeler),
        IntCellValue(videolar),
        IntCellValue(rozetler),
        IntCellValue(puan),
        IntCellValue(sureDk),
        IntCellValue(hataliCevap),
        TextCellValue(sonGuncelleme != null ? dateFormat.format(sonGuncelleme) : ''),
      ]);
    }
  }

  void _buildScenariosSheet(Sheet sheet, List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    sheet.appendRow([
      TextCellValue('Senaryo_ID'),
      TextCellValue('Baslik'),
      TextCellValue('Alt_Baslik'),
      TextCellValue('Kategori'),
      TextCellValue('Yas_Grubu'),
      TextCellValue('Bolum_Sayisi'),
    ]);

    for (var doc in docs) {
      final data = doc.data();
      final bolumler = (data['bolumler'] as List?)?.length ?? 0;

      sheet.appendRow([
        TextCellValue(doc.id),
        TextCellValue(data['baslik']?.toString() ?? ''),
        TextCellValue(data['altBaslik']?.toString() ?? ''),
        TextCellValue(data['kategori']?.toString() ?? 'Genel'),
        TextCellValue(data['yasGrubu']?.toString() ?? 'Tüm Yaşlar'),
        IntCellValue(bolumler),
      ]);
    }
  }

  void _buildStoriesSheet(Sheet sheet, List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    sheet.appendRow([
      TextCellValue('Hikaye_ID'),
      TextCellValue('Baslik'),
      TextCellValue('Alt_Baslik'),
      TextCellValue('Kategori'),
      TextCellValue('Yas_Grubu'),
    ]);

    for (var doc in docs) {
      final data = doc.data();
      sheet.appendRow([
        TextCellValue(doc.id),
        TextCellValue(data['baslik']?.toString() ?? ''),
        TextCellValue(data['altBaslik']?.toString() ?? ''),
        TextCellValue(data['kategori']?.toString() ?? 'Genel'),
        TextCellValue(data['yasGrubu']?.toString() ?? '6-12'),
      ]);
    }
  }

  void _buildVideosSheet(Sheet sheet, List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    sheet.appendRow([
      TextCellValue('Video_ID'),
      TextCellValue('Baslik'),
      TextCellValue('Alt_Baslik'),
      TextCellValue('Sure'),
      TextCellValue('Youtube_ID'),
    ]);

    for (var doc in docs) {
      final data = doc.data();
      sheet.appendRow([
        TextCellValue(doc.id),
        TextCellValue(data['baslik']?.toString() ?? ''),
        TextCellValue(data['altBaslik']?.toString() ?? ''),
        TextCellValue(data['sure']?.toString() ?? ''),
        TextCellValue(data['youtubeId']?.toString() ?? ''),
      ]);
    }
  }

  void _buildMetricsDocsSheet(Sheet sheet) {
    sheet.appendRow([TextCellValue('DOKÜMANTASYON & VERİ MİMARİSİ BİLGİLENDİRMESİ')]);
    sheet.appendRow([TextCellValue('')]);

    final notes = [
      ['PivotTable & Power Query Uyumluğu', 'Tüm veri sayfaları (2_Kullanicilar, 3_Ilerleme, vb.) birleştirilmemiş başlık ve veri satırları içerir. Excel\'de "Ekle -> Özet Tablo (PivotTable)" ile tek tıkla çapraz analizler oluşturabilirsiniz.'],
      ['Çocuk Gizliliği Protekolü', 'Kullanıcı parolaları, Auth token\'ları, veli kişisel detayları ve Siber Dost özel mesaj sohbetleri hiçbir şekilde bu rapora yazılmaz.'],
      ['Zaman Serisi (Time-Series) Notu', 'Şu anki veritabanında "usersProgress" anlık kümülatif sayıları saklamaktadır. Adım adım zaman serisi olay izleme (Event Stream / Audit Log) altyapısı için "user_events" adında zaman damgalı yeni bir koleksiyon önerilmektedir.'],
      ['Firestore Veri Kaynakları', 'users: Profil & Demografi | usersProgress: İlerleme & Puan | scenarios, stories, videos: İçerik Kataloğu'],
    ];

    sheet.appendRow([TextCellValue('KONU'), TextCellValue('AÇIKLAMA & UYARILAR')]);
    for (var n in notes) {
      sheet.appendRow([TextCellValue(n[0]), TextCellValue(n[1])]);
    }
  }
}
