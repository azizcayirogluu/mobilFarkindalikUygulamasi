import 'package:flutter/material.dart';

/// Demografik Yaş Grubu Dağılım Kartı
class AgeGroupDistributionCard extends StatelessWidget {
  final int group6to12;
  final int group13to18;

  const AgeGroupDistributionCard({
    super.key,
    required this.group6to12,
    required this.group13to18,
  });

  @override
  Widget build(BuildContext context) {
    final int total = group6to12 + group13to18;
    final double ratio6to12 = total > 0 ? (group6to12 / total) : 0.5;
    final double ratio13to18 = total > 0 ? (group13to18 / total) : 0.5;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pie_chart_rounded, color: Colors.indigo, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                "Yaş Grubu Demografisi",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  Expanded(
                    flex: (ratio6to12 * 100).round(),
                    child: Container(color: Colors.blue),
                  ),
                  Expanded(
                    flex: (ratio13to18 * 100).round(),
                    child: Container(color: Colors.teal),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legendItem("6-12 Yaş Grubu", group6to12, (ratio6to12 * 100).toStringAsFixed(1), Colors.blue),
              _legendItem("13-18 Yaş Grubu", group13to18, (ratio13to18 * 100).toStringAsFixed(1), Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, int count, String percentage, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "$count (%$percentage)",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Bildirim İzin Oranı Kartı
class NotificationPermissionCard extends StatelessWidget {
  final int totalUsers;
  final int enabledUsers;

  const NotificationPermissionCard({
    super.key,
    required this.totalUsers,
    required this.enabledUsers,
  });

  @override
  Widget build(BuildContext context) {
    final double percent = totalUsers > 0 ? (enabledUsers / totalUsers) : 0.0;
    final String percentStr = (percent * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_active_rounded, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                "Bildirim İzin Oranı",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: percent,
            minHeight: 12,
            backgroundColor: const Color(0xFFF1F5F9),
            color: Colors.amber.shade600,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Aktif Bildirim İzinleri",
                style: TextStyle(
                  color: Colors.blueGrey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "$enabledUsers / $totalUsers (%$percentStr)",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Metrik Dokümantasyonu ve Sistem Bilgilendirme Kartı
class SystemMetricsDocumentationCard extends StatelessWidget {
  const SystemMetricsDocumentationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF0F172A), size: 20),
              const SizedBox(width: 10),
              const Text(
                "Veri Metodolojisi & Zaman Serisi Notu",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "1. Tüm KPI ve içerik verileri veritabanındaki gerçek kayıtlardan (users, usersProgress, scenarios, stories, videos) hesaplanmıştır.\n"
            "2. Çocuk gizliliği standartları gereğince sohbet metinleri veya kişisel parolalar hiçbir aşamada işlenmemekte ve dışa aktarılmamaktadır.\n"
            "3. Mevcut 'usersProgress' koleksiyonu kümülatif tamamlamaları saklamaktadır. Adım adım zaman serili olay akışı (Event Stream Log) ihtiyacı için zaman damgalı olay kaydı koleksiyonu önerilmektedir.",
            style: TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
