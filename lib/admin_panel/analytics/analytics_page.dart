import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'services/excel_exporter_service.dart';
import 'widgets/analytics_charts.dart';
import 'widgets/date_range_picker_bar.dart';
import 'widgets/kpi_card.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late DateTime _startDate;
  late DateTime _endDate;
  String _filterLabel = "Son 30 Gün";
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  void _onDateRangeSelected(DateRangeSelection selection) {
    setState(() {
      _startDate = selection.startDate;
      _endDate = selection.endDate;
      _filterLabel = selection.label;
    });
  }

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);

    try {
      final exporter = ExcelExporterService();
      final result = await exporter.generateAndExportAnalyticsReport(
        startDate: _startDate,
        endDate: _endDate,
        filterLabel: _filterLabel,
      );

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Excel raporu oluşturuldu ve indirildi! (${result.fileName})",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata: ${result.errorMessage}"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Dışa aktarma hatası: $e"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildToolbar(),
            const SizedBox(height: 32),
            _buildKPISection(),
            const SizedBox(height: 32),
            _buildDemographicsAndDetailsSection(),
            const SizedBox(height: 32),
            const SystemMetricsDocumentationCard(),
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
              "Raporlama ve Analiz Merkezi",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Platform kullanıcı aktivitesi, içerik performans metrikleri ve PivotTable uyumlu Excel ihraç merkezi.",
              style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 14),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.anaMavi.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.anaMavi.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              CircleAvatar(radius: 4, backgroundColor: AppColors.anaMavi),
              SizedBox(width: 8),
              Text(
                "GERÇEK ZAMANLI VERİ",
                style: TextStyle(
                  color: AppColors.anaMavi,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: [
        Expanded(
          child: DateRangePickerBar(
            onRangeSelected: _onDateRangeSelected,
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _isExporting ? null : _exportToExcel,
          icon: _isExporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.table_chart_rounded, size: 18),
          label: Text(
            _isExporting ? "HAZIRLANIYOR..." : "EXCEL RAPORU OLUŞTUR (XLSX)",
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildKPISection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, usersSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore.collection('usersProgress').snapshots(),
          builder: (context, progressSnapshot) {
            final isUsersLoading = usersSnapshot.connectionState == ConnectionState.waiting;
            final isProgressLoading = progressSnapshot.connectionState == ConnectionState.waiting;

            if (isUsersLoading || isProgressLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final userDocs = usersSnapshot.data?.docs ?? [];
            final progressDocs = progressSnapshot.data?.docs ?? [];

            final int totalUsers = userDocs.length;
            int newUsersCount = 0;
            int activeUsersCount = 0;
            int onlineUsersCount = 0;

            for (var doc in userDocs) {
              final data = doc.data();
              final kayitTarihi = (data['kayitTarihi'] as Timestamp?)?.toDate();
              final sonGorulme = (data['sonGorulme'] as Timestamp?)?.toDate();
              final isOnline = data['isOnline'] as bool? ?? false;

              if (isOnline) onlineUsersCount++;

              if (kayitTarihi != null &&
                  kayitTarihi.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
                  kayitTarihi.isBefore(_endDate.add(const Duration(days: 1)))) {
                newUsersCount++;
              }

              if (sonGorulme != null &&
                  sonGorulme.isAfter(_startDate.subtract(const Duration(seconds: 1)))) {
                activeUsersCount++;
              }
            }

            int totalScenarioCompletions = 0;
            int totalStoriesRead = 0;
            int totalVideosWatched = 0;
            int totalPointsEarned = 0;

            for (var doc in progressDocs) {
              final data = doc.data();
              totalScenarioCompletions += (data['tamamlanan_senaryolar'] as List?)?.length ?? 0;
              totalStoriesRead += (data['okunan_hikayeler'] as List?)?.length ?? 0;
              totalVideosWatched += (data['izlenen_videolar'] as List?)?.length ?? 0;
              totalPointsEarned += (data['puan'] as num?)?.toInt() ?? (data['toplam_puan'] as num?)?.toInt() ?? 0;
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 1000;
                final crossAxisCount = isWide ? 4 : 2;

                final kpiItems = [
                  KPICard(
                    title: "Toplam Kayıtlı Kahraman",
                    value: "$totalUsers",
                    subtitle: "Platform genel kullanıcı hacmi",
                    icon: Icons.people_alt_rounded,
                    color: Colors.blue,
                    badgeText: "$onlineUsersCount Çevrimiçi",
                  ),
                  KPICard(
                    title: "Yeni Kayıtlar",
                    value: "$newUsersCount",
                    subtitle: "$_filterLabel içindeki yeni üyelikler",
                    icon: Icons.person_add_alt_1_rounded,
                    color: Colors.teal,
                    badgeText: _filterLabel,
                  ),
                  KPICard(
                    title: "Dönem İçi Aktif Kullanıcı",
                    value: "$activeUsersCount",
                    subtitle: "$_filterLabel içinde işlem yapanlar",
                    icon: Icons.bolt_rounded,
                    color: Colors.indigo,
                    badgeText: "Aktiflik",
                  ),
                  KPICard(
                    title: "Senaryo Tamamlamaları",
                    value: "$totalScenarioCompletions",
                    subtitle: "Kullanıcıların bitirdiği senaryolar",
                    icon: Icons.schema_rounded,
                    color: Colors.purple,
                  ),
                  KPICard(
                    title: "Okunan Öykü Sayısı",
                    value: "$totalStoriesRead",
                    subtitle: "Biten kütüphane hikayeleri",
                    icon: Icons.menu_book_rounded,
                    color: Colors.orange,
                  ),
                  KPICard(
                    title: "İzlenen Eğitim Videosu",
                    value: "$totalVideosWatched",
                    subtitle: "İzlenen siber güvenlik videoları",
                    icon: Icons.play_circle_fill_rounded,
                    color: Colors.pink,
                  ),
                  KPICard(
                    title: "Dağıtılan Toplam Puan",
                    value: "$totalPointsEarned",
                    subtitle: "Başarılar sonucu kazanılan puan",
                    icon: Icons.stars_rounded,
                    color: Colors.amber.shade700,
                  ),
                  KPICard(
                    title: "İlerleme Kaydı Bulunan",
                    value: "${progressDocs.length}",
                    subtitle: "En az 1 etkileşimi olan hesaplar",
                    icon: Icons.insights_rounded,
                    color: Colors.cyan,
                  ),
                ];

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 165,
                  ),
                  itemCount: kpiItems.length,
                  itemBuilder: (context, index) => kpiItems[index],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDemographicsAndDetailsSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;
        int group6to12 = 0;
        int group13to18 = 0;
        int notificationsEnabled = 0;

        for (var doc in docs) {
          final data = doc.data();
          final yasGrubu = data['yasGrubu']?.toString() ?? '6-12';
          final bildirim = data['bildirimlerAcik'] as bool? ?? false;

          if (yasGrubu == '6-12') {
            group6to12++;
          } else {
            group13to18++;
          }

          if (bildirim) notificationsEnabled++;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AgeGroupDistributionCard(
                group6to12: group6to12,
                group13to18: group13to18,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: NotificationPermissionCard(
                totalUsers: docs.length,
                enabledUsers: notificationsEnabled,
              ),
            ),
          ],
        );
      },
    );
  }
}
