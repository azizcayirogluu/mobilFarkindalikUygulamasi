import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

enum UserSortOption {
  latestRegistered('Son Kayıt (Yeni -> Eski)', 'kayitTarihi', true, Icons.south_rounded),
  oldestRegistered('İlk Kayıt (Eski -> Yeni)', 'kayitTarihi', false, Icons.north_rounded),
  lastSeen('Son Görülme (Aktiflik)', 'sonGorulme', true, Icons.access_time_rounded),
  nameAsc('İsme Göre (A - Z)', 'kullaniciAdi', false, Icons.sort_by_alpha_rounded);

  final String label;
  final String field;
  final bool descending;
  final IconData icon;

  const UserSortOption(this.label, this.field, this.descending, this.icon);
}

enum UserFilterOption {
  all('Tümü', Icons.people_alt_rounded),
  online('Çevrimiçi', Icons.sensors_rounded),
  admin('Yöneticiler', Icons.admin_panel_settings_rounded),
  premium('Premium', Icons.stars_rounded),
  risky('Riskli / Tehlikeli', Icons.warning_amber_rounded);

  final String label;
  final IconData icon;

  const UserFilterOption(this.label, this.icon);
}

class UserManager extends StatefulWidget {
  const UserManager({super.key});

  @override
  State<UserManager> createState() => _UserManagerState();
}

class _UserManagerState extends State<UserManager> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  UserSortOption _sortOption = UserSortOption.latestRegistered;
  UserFilterOption _filterOption = UserFilterOption.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProHeader(),
            const SizedBox(height: 24),
            _buildStatSummaryCards(),
            const SizedBox(height: 24),
            _buildFilterAndControlsRow(),
            const SizedBox(height: 20),
            Expanded(child: _buildUserList()),
          ],
        ),
      ),
    );
  }

  Widget _buildProHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Kullanıcı Yönetim Ekranı",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Tüm kullanıcıların hesap yetkilerini, kayıt tarihlerini ve güvenlik analizlerini yönetin.",
              style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatSummaryCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 90,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data!.docs;
        final int totalUsers = docs.length;
        int onlineCount = 0;
        int adminCount = 0;
        int premiumCount = 0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (_isUserOnline(data)) onlineCount++;
          if (data['isAdmin'] == true) adminCount++;
          if (data['isPremium'] == true) premiumCount++;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                Expanded(
                  child: _statCard(
                    title: "Toplam Kullanıcı",
                    value: "$totalUsers",
                    icon: Icons.group_rounded,
                    color: Colors.blue,
                    badgeText: "Kayıtlı",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _statCard(
                    title: "Çevrimiçi",
                    value: "$onlineCount",
                    icon: Icons.sensors_rounded,
                    color: const Color(0xFF10B981),
                    badgeText: "Aktif",
                    isLive: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _statCard(
                    title: "Premium Üyeler",
                    value: "$premiumCount",
                    icon: Icons.stars_rounded,
                    color: Colors.amber.shade700,
                    badgeText: "Pro",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _statCard(
                    title: "Yöneticiler",
                    value: "$adminCount",
                    icon: Icons.admin_panel_settings_rounded,
                    color: Colors.indigo,
                    badgeText: "Admin",
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String badgeText,
    bool isLive = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey.shade600,
                      ),
                    ),
                    if (isLive) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndControlsRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Search Input
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim().toLowerCase());
                  },
                  decoration: InputDecoration(
                    hintText: "Kullanıcı adı, ID veya yaş grubu ile ara...",
                    hintStyle: TextStyle(color: Colors.blueGrey.shade400, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.blueGrey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Sort Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UserSortOption>(
                    value: _sortOption,
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.blueGrey),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                    onChanged: (UserSortOption? newOption) {
                      if (newOption != null) {
                        setState(() => _sortOption = newOption);
                      }
                    },
                    items: UserSortOption.values.map((opt) {
                      return DropdownMenuItem<UserSortOption>(
                        value: opt,
                        child: Row(
                          children: [
                            Icon(opt.icon, size: 18, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(opt.label),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: UserFilterOption.values.map((filter) {
                final bool isSelected = _filterOption == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    showCheckmark: false,
                    avatar: Icon(
                      filter.icon,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.blueGrey,
                    ),
                    label: Text(
                      filter.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.blueGrey.shade700,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Colors.blue,
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: BorderSide(
                      color: isSelected ? Colors.blue : const Color(0xFFE2E8F0),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _filterOption = filter);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy(_sortOption.field, descending: _sortOption.descending)
          .limit(100)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  "Kullanıcılar yüklenirken hata oluştu: ${userSnapshot.error}",
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userDocs = userSnapshot.data!.docs;

        if (userDocs.isEmpty) {
          return const Center(
            child: Text("Sistemde henüz kayıtlı kullanıcı bulunamadı."),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('usersProgress').snapshots(),
          builder: (context, progSnapshot) {
            if (!progSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final progressMap = <String, Map<String, dynamic>>{};
            for (var doc in progSnapshot.data!.docs) {
              progressMap[doc.id] = doc.data() as Map<String, dynamic>;
            }

            final filteredUsers = <QueryDocumentSnapshot>[];
            for (var userDoc in userDocs) {
              final userData = userDoc.data() as Map<String, dynamic>;
              final String uid = userDoc.id;
              final progData = progressMap[uid] ?? {};

              if (_matchesFilterAndSearch(userData, progData, uid)) {
                filteredUsers.add(userDoc);
              }
            }

            if (filteredUsers.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _filterOption == UserFilterOption.risky
                            ? Icons.verified_user_rounded
                            : Icons.search_off_rounded,
                        size: 48,
                        color: _filterOption == UserFilterOption.risky
                            ? Colors.green
                            : Colors.blueGrey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _filterOption == UserFilterOption.risky
                            ? "Riskli veya tehlikeli durumda kullanıcı bulunamadı."
                            : "Seçilen filtreye uygun kullanıcı bulunamadı.",
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final userDoc = filteredUsers[index];
                final userData = userDoc.data() as Map<String, dynamic>;
                final String uid = userDoc.id;
                final progData = progressMap[uid] ?? {};

                return _buildUserCard(context, uid, userData, progData);
              },
            );
          },
        );
      },
    );
  }

  bool _matchesFilterAndSearch(Map<String, dynamic> user, Map<String, dynamic> prog, String uid) {
    // 1. Search Query
    if (_searchQuery.isNotEmpty) {
      final name = (user['kullaniciAdi'] ?? '').toString().toLowerCase();
      final ageGroup = (user['yasGrubu'] ?? '').toString().toLowerCase();
      final fcmToken = (user['fcmToken'] ?? '').toString().toLowerCase();
      final userUid = uid.toLowerCase();
      final risk = (prog['riskDurumu'] ?? '').toString().toLowerCase();

      final matches = name.contains(_searchQuery) ||
          ageGroup.contains(_searchQuery) ||
          userUid.contains(_searchQuery) ||
          fcmToken.contains(_searchQuery) ||
          risk.contains(_searchQuery);

      if (!matches) return false;
    }

    // 2. Filter Option
    switch (_filterOption) {
      case UserFilterOption.all:
        return true;
      case UserFilterOption.online:
        return _isUserOnline(user);
      case UserFilterOption.admin:
        return user['isAdmin'] == true;
      case UserFilterOption.premium:
        return user['isPremium'] == true;
      case UserFilterOption.risky:
        return _isUserRisky(prog);
    }
  }

  bool _isUserRisky(Map<String, dynamic> prog) {
    final rawRisk = (prog['riskDurumu'] ?? '').toString().trim().toUpperCase();
    if (rawRisk.isEmpty ||
        rawRisk == 'GÜVENLİ' ||
        rawRisk == 'GUVENLI' ||
        rawRisk == 'BELİRSİZ' ||
        rawRisk == 'BELIRSIZ') {
      return false;
    }

    return rawRisk.contains('RİSK') ||
        rawRisk.contains('RISK') ||
        rawRisk.contains('TEHLİK') ||
        rawRisk.contains('TEHLIK') ||
        rawRisk == 'RİSKLİ' ||
        rawRisk == 'TEHLİKELİ' ||
        rawRisk == 'RISKLI' ||
        rawRisk == 'TEHLIKELI';
  }

  Widget _buildUserCard(
    BuildContext context,
    String uid,
    Map<String, dynamic> user,
    Map<String, dynamic> prog,
  ) {
    final String risk = prog['riskDurumu'] ?? "BELİRSİZ";
    final Color riskColor = _getRiskColor(risk);
    final bool isOnline = _isUserOnline(user);
    final bool isAdmin = user['isAdmin'] == true;
    final bool isPremium = user['isPremium'] == true;
    final String? avatarUrl = user['avatarUrl'];
    final String userName = user['kullaniciAdi'] ?? "İsimsiz";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: riskColor.withValues(alpha: 0.1),
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : "K",
                      style: TextStyle(
                        color: riskColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey.shade400,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                userName,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (isAdmin) ...[
              _tagBadge("ADMIN", Colors.indigo, Icons.shield_rounded),
              const SizedBox(width: 6),
            ],
            if (isPremium) ...[
              _tagBadge("PRO", Colors.amber.shade800, Icons.star_rounded),
              const SizedBox(width: 6),
            ],
            _badge(user['yasGrubu'] ?? "-", Colors.blueGrey),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Wrap(
            spacing: 16,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _infoItem(Icons.calendar_today_rounded, "Kayıt: ${_formatDate(user['kayitTarihi'])}", Colors.blueGrey),
              _infoItem(Icons.access_time_rounded, "Son Görülme: ${_formatRelativeDate(user['sonGorulme'])}", isOnline ? Colors.green : Colors.blueGrey),
              _infoItem(Icons.stars_rounded, "${prog['toplam_puan'] ?? 0} TP", Colors.amber.shade700),
              _infoItem(Icons.emoji_events_rounded, "${(prog['rozetler'] as List? ?? []).length} Rozet", Colors.purple),
              _infoItem(Icons.security_rounded, risk, riskColor),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionBtn(
              Icons.troubleshoot_rounded,
              Colors.indigo,
              "Detaylar",
              () => _showUserDetails(context, uid, user, prog),
            ),
            const SizedBox(width: 6),
            _actionBtn(
              isAdmin ? Icons.admin_panel_settings : Icons.admin_panel_settings_outlined,
              isAdmin ? Colors.indigo : Colors.grey,
              isAdmin ? "Yönetici Yetkisini Kaldır" : "Yönetici Yap",
              () => _toggleAdmin(uid, userName, isAdmin),
            ),
            const SizedBox(width: 6),
            _actionBtn(
              isPremium ? Icons.star : Icons.star_border,
              isPremium ? Colors.amber.shade800 : Colors.grey,
              isPremium ? "Premium İptal Et" : "Premium Yap",
              () => _togglePremium(uid, userName, isPremium),
            ),
            const SizedBox(width: 6),
            _actionBtn(
              Icons.delete_sweep_rounded,
              Colors.redAccent,
              "Kullanıcıyı Sil",
              () => _deleteUser(context, uid, userName),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagBadge(String t, Color c, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: c),
          const SizedBox(width: 3),
          Text(
            t,
            style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData i, String t, Color c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(i, size: 13, color: c),
        const SizedBox(width: 4),
        Text(
          t,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _badge(String t, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        t,
        style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _actionBtn(IconData i, Color c, String tooltip, VoidCallback o) {
    return Container(
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: o,
        icon: Icon(i, color: c, size: 18),
        tooltip: tooltip,
        splashRadius: 22,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _showUserDetails(
    BuildContext context,
    String uid,
    Map<String, dynamic> user,
    Map<String, dynamic> prog,
  ) {
    showDialog(
      context: context,
      builder: (c) {
        bool currentIsAdmin = user['isAdmin'] == true;
        bool currentIsPremium = user['isPremium'] == true;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final String name = user['kullaniciAdi'] ?? 'İsimsiz';
            final String? avatarUrl = user['avatarUrl'];
            final String? fcmToken = user['fcmToken'];
            final bool isOnline = _isUserOnline(user);
            final String risk = prog['riskDurumu'] ?? "BELİRSİZ";
            final Color riskColor = _getRiskColor(risk);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              titlePadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.all(24),
              title: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white24,
                          backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? CachedNetworkImageProvider(avatarUrl)
                              : null,
                          child: (avatarUrl == null || avatarUrl.isEmpty)
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : "K",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: isOnline ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$name - Detaylı Analiz",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                isOnline ? "Çevrimiçi" : "Çevrimdışı",
                                style: TextStyle(
                                  color: isOnline ? Colors.greenAccent : Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "Yaş: ${user['yasGrubu'] ?? '-'}",
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(c),
                    ),
                  ],
                ),
              ),
              content: SizedBox(
                width: 580,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // USER ID SECTION
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.fingerprint_rounded, color: Colors.blueGrey, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "UID: $uid",
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkWell(
                              onTap: () => _copyToClipboard(context, uid, "Kullanıcı ID (UID)"),
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(Icons.copy_rounded, size: 16, color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // TIMESTAMPS SECTION
                      const Text(
                        "KAYIT & AKTİFLİK ZAMANLARI",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: Colors.blueGrey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _detailRow("Kayıt Tarihi", _formatDate(user['kayitTarihi'])),
                      _detailRow("Son Görülme", "${_formatDate(user['sonGorulme'])} (${_formatRelativeDate(user['sonGorulme'])})"),
                      _detailRow("Token Son Güncelleme", _formatDate(user['lastTokenUpdate'])),

                      const Divider(height: 30),

                      // PRIVILEGES & SWITCHES SECTION
                      const Text(
                        "YETKİ VE ÜYELİK YÖNETİMİ",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: Colors.blueGrey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text(
                                "Yönetici Yetkisi (isAdmin)",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: const Text(
                                "Kullanıcıya yönetim paneline erişim hakkı verir.",
                                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                              ),
                              secondary: Icon(
                                Icons.admin_panel_settings_rounded,
                                color: currentIsAdmin ? Colors.indigo : Colors.grey,
                              ),
                              value: currentIsAdmin,
                              onChanged: (val) async {
                                setModalState(() => currentIsAdmin = val);
                                await FirebaseFirestore.instance.collection('users').doc(uid).update({'isAdmin': val});
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("$name yetkisi ${val ? 'Yönetici' : 'Kullanıcı'} yapıldı.")),
                                  );
                                }
                              },
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              title: const Text(
                                "Premium Üyelik (isPremium)",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: const Text(
                                "Kullanıcıya sınırsız AI ve özel içerik erişimi tanımlar.",
                                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                              ),
                              secondary: Icon(
                                Icons.stars_rounded,
                                color: currentIsPremium ? Colors.amber.shade800 : Colors.grey,
                              ),
                              value: currentIsPremium,
                              onChanged: (val) async {
                                setModalState(() => currentIsPremium = val);
                                await FirebaseFirestore.instance.collection('users').doc(uid).update({'isPremium': val});
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("$name Premium durumu ${val ? 'Aktif' : 'Pasif'} yapıldı.")),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 30),

                      // FCM TOKEN SECTION
                      const Text(
                        "FCM PUSH NOTIFICATION TOKEN",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: Colors.blueGrey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  (fcmToken != null && fcmToken.isNotEmpty)
                                      ? "Cihaz Token'ı Kayıtlı"
                                      : "Token Bulunamadı",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: (fcmToken != null && fcmToken.isNotEmpty)
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                if (fcmToken != null && fcmToken.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.blue),
                                    onPressed: () => _copyToClipboard(context, fcmToken, "FCM Token"),
                                    tooltip: "Token'ı Kopyala",
                                  ),
                              ],
                            ),
                            if (fcmToken != null && fcmToken.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              SelectableText(
                                fcmToken,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: Colors.black87,
                                ),
                                maxLines: 3,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const Divider(height: 30),

                      // SECURITY & RISK ANALYSIS
                      const Text(
                        "GÜVENLİK VE RİSK ANALİZİ",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: Colors.blueGrey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: riskColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: riskColor.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.security_rounded, color: riskColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "Risk Durumu: $risk",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: riskColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              prog['riskNedeni'] ?? "Henüz bir risk tespiti yapılmadı.",
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // RECENT ERRORS & EDUCATION NEEDS
                      const Text(
                        "SON HATALAR & EĞİTİM İHTİYAÇLARI",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: Colors.blueGrey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      (prog['son_hatalar'] as List? ?? []).isEmpty
                          ? Text(
                              "Tespit edilen özel bir eğitim ihtiyacı veya hata yok.",
                              style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade600),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (prog['son_hatalar'] as List? ?? [])
                                  .map((e) => _badge(e.toString(), Colors.redAccent))
                                  .toList(),
                            ),

                      const SizedBox(height: 20),

                      // PROGRESS & BADGES
                      const Text(
                        "İLERLEME VE BAŞARILAR",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: Colors.blueGrey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _detailRow("Toplam Tecrübe Puanı (TP)", "${prog['toplam_puan'] ?? 0} TP"),
                      _detailRow("Kazanılan Rozet Sayısı", "${(prog['rozetler'] as List? ?? []).length}"),
                    ],
                  ),
                ),
              ),
              actions: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(c);
                    _deleteUser(context, uid, name);
                  },
                  icon: const Icon(Icons.delete_forever_rounded, size: 18),
                  label: const Text("Kullanıcıyı Sil"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text("Kapat", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggleAdmin(String uid, String name, bool currentIsAdmin) async {
    final bool newAdminStatus = !currentIsAdmin;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isAdmin': newAdminStatus,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "$name kullanıcısının yönetici yetkisi ${newAdminStatus ? 'verildi' : 'kaldırıldı'}.",
            ),
            backgroundColor: newAdminStatus ? Colors.indigo : Colors.grey.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Yetki güncellenirken hata oluştu: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _togglePremium(String uid, String name, bool currentIsPremium) async {
    final bool newPremiumStatus = !currentIsPremium;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isPremium': newPremiumStatus,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "$name kullanıcısının Premium durumu ${newPremiumStatus ? 'aktif yapıldı' : 'iptal edildi'}.",
            ),
            backgroundColor: newPremiumStatus ? Colors.amber.shade800 : Colors.grey.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Premium durumu güncellenirken hata oluştu: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$label panoya kopyalandı!"),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }

  bool _isUserOnline(Map<String, dynamic> user) {
    if (user['isOnline'] != true) return false;
    final lastSeen = user['sonGorulme'];
    if (lastSeen == null) return false;

    DateTime date;
    if (lastSeen is Timestamp) {
      date = lastSeen.toDate();
    } else if (lastSeen is DateTime) {
      date = lastSeen;
    } else if (lastSeen is String) {
      date = DateTime.tryParse(lastSeen) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else if (lastSeen is int) {
      date = DateTime.fromMillisecondsSinceEpoch(lastSeen);
    } else {
      return false;
    }

    // Kullanıcı son 5 dakika içinde aktifleştiyse çevrimiçidir
    final diff = DateTime.now().difference(date);
    return diff.inMinutes <= 5;
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "Bilinmiyor";
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp is String) {
        date = DateTime.tryParse(timestamp) ?? DateTime.now();
      } else if (timestamp is int) {
        date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        return "Geçersiz Tarih";
      }
      return DateFormat('dd.MM.yyyy HH:mm').format(date);
    } catch (_) {
      return "Format Hatası";
    }
  }

  String _formatRelativeDate(dynamic timestamp) {
    if (timestamp == null) return "Bilinmiyor";
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp is String) {
        date = DateTime.tryParse(timestamp) ?? DateTime.now();
      } else if (timestamp is int) {
        date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        return "Bilinmiyor";
      }

      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return "Şimdi";
      if (diff.inMinutes < 60) return "${diff.inMinutes} dk önce";
      if (diff.inHours < 24) return "${diff.inHours} saat önce";
      if (diff.inDays < 7) return "${diff.inDays} gün önce";
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (_) {
      return "Bilinmiyor";
    }
  }

  Color _getRiskColor(String? r) {
    if (r == null) return Colors.green;
    final upper = r.trim().toUpperCase();
    if (upper.contains('TEHLİK') || upper.contains('TEHLIK')) return Colors.red;
    if (upper.contains('RİSK') || upper.contains('RISK')) return Colors.orange;
    return Colors.green;
  }

  void _deleteUser(BuildContext context, String uid, String? name) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Kullanıcıyı Sil", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          "${name ?? 'Bu'} kullanıcısını ve tüm verilerini sistemden kalıcı olarak silmek istediğinize emin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(c);
              _performDeleteUser(context, uid, name);
            },
            child: const Text("SİL"),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteUser(BuildContext context, String uid, String? name) async {
    try {
      final deleteFn = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('deleteUser');
      await deleteFn.call({'uid': uid});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$name kullanıcısı silindi.")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Silme işlemi başarısız: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _detailRow(String l, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l,
            style: TextStyle(color: Colors.blueGrey.shade600, fontWeight: FontWeight.w500, fontSize: 13),
          ),
          SelectableText(
            v,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }
}
