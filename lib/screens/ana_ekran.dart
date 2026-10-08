import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/senaryo_detay_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/hikaye_detay_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/video_detay_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/siber_dedektif_oyunu.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zorbalik_uygulamasi/services/content_service.dart';
import 'package:zorbalik_uygulamasi/widgets/profile_avatar.dart';

/// Bu ekrana özel tasarım sabitleri (renk, radius, boşluk).
class _Ui {
  static const background = AppColors.zemin;
  static const surface = Colors.white;
  static const textPrimary = AppColors.yaziRengi;
  static const textSecondary = Color(0xFF6B7088);
  static const textBody = Color(0xFF565B73);
  static const border = Color(0xFFE6E8F5);
  static const pointBg = Color(0xFFFFF4DC);
  static const pointIcon = AppColors.oyunSarisi;

  static const radiusCard = 24.0; // Öneri kartları
  static const radiusHero = 28.0; // Macera seviyesi kartı
  static const radiusPill = 999.0;

  static const pagePadding = 20.0;
  static const maxContentWidth = 640.0;
  static const itemGap = 14.0;
}

class _IlerlemeOzeti {
  final int puan;
  final int tamamlanan;
  const _IlerlemeOzeti(this.puan, this.tamamlanan);
}

class AnaSayfa extends StatefulWidget {
  final VoidCallback onProfileTap;
  final Function(int) onTabChanged;
  final String kullaniciAdi;

  /// Üst widget alt navigasyonu içeriğin ÜZERİNE bindiriyorsa
  /// (extendBody / Stack), o navigasyonun yüksekliğini buradan ver.
  /// Normal Scaffold.bottomNavigationBar kullanılıyorsa 0 kalmalı.
  final double altKaplamaBoslugu;

  const AnaSayfa({
    super.key,
    required this.onProfileTap,
    required this.onTabChanged,
    required this.kullaniciAdi,
    this.altKaplamaBoslugu = 0,
  });

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  List<Map<String, dynamic>> _kesifHavuzu = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _toplamGorevSayisi = 0;

  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final ContentService _contentService = ContentService();

  // Stream'ler build içinde değil bir kez oluşturulur; setState'te
  // yeniden abone olunup yanıp sönme yaşanmaz.
  Stream<DocumentSnapshot>? _userStream;
  Stream<DocumentSnapshot>? _progressStream;

  @override
  void initState() {
    super.initState();
    final user = _currentUser;
    if (user != null) {
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots();
      _progressStream = _contentService.getUserProgressStream(user.uid);
    }
    _initData();
  }

  // ───────────────────────── Veri yardımcıları ─────────────────────────

  Color _hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return AppColors.anaMavi;
    try {
      final buffer = StringBuffer();
      final cleanHex = hexString.replaceFirst('#', '').replaceFirst('0x', '');
      if (cleanHex.length == 6) buffer.write('ff');
      buffer.write(cleanHex);
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return AppColors.anaMavi;
    }
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'psychology':
        return Icons.psychology_alt_rounded;
      case 'auto_stories':
        return Icons.auto_stories_rounded;
      case 'play':
        return Icons.play_circle_filled_rounded;
      case 'search':
        return Icons.search_rounded;
      default:
        return Icons.stars_rounded;
    }
  }

  String _ilerlemeMesaji(double ilerleme) {
    final yuzde = (ilerleme * 100).toInt();
    if (yuzde == 0) return "Maceraya atılmaya hazır mısın?";
    if (yuzde < 40) return "Harika bir başlangıç yapıyorsun!";
    if (yuzde < 80) return "Gerçek bir siber koruyucu oluyorsun!";
    return "Neredeyse efsanevi bir kahramansın!";
  }

  String _altMetin(Map item) {
    if (item['tip'] == "HİKAYE") {
      final feedback = (item['data'] as Map?)?['feedbackMessage']?.toString();
      return (feedback != null && feedback.isNotEmpty)
          ? feedback
          : "Kahramanlık yolunda yeni bir öykü!";
    }
    return (item['altBaslik'] ?? '').toString();
  }

  /// Puan ve tamamlanan görev sayısı. Hesaplama mantığı eskisiyle aynı.
  _IlerlemeOzeti _ozetle(DocumentSnapshot? snap) {
    if (snap == null || !snap.exists) return const _IlerlemeOzeti(0, 0);

    final data = snap.data() as Map<String, dynamic>;
    final int puan = data['toplam_puan'] ?? 0;
    final List bitti = data['tamamlanan_bolumler'] as List? ?? [];
    final List okundu = data['okunan_hikayeler'] as List? ?? [];
    final List dedektif = data['bilinen_dedektif_sorulari'] as List? ?? [];

    // Senaryo ID'lerini güvenli şekilde ayır ve SET yap
    final Set<String> tamamlananSenaryoIdleri = {};
    for (final item in bitti) {
      final s = item.toString();
      tamamlananSenaryoIdleri.add(s.contains('_') ? s.split('_')[0] : s);
    }

    return _IlerlemeOzeti(
      puan,
      tamamlananSenaryoIdleri.length + okundu.length + dedektif.length,
    );
  }

  Future<void> _initData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final data = await _contentService.fetchDiscoveryData();

      if (mounted) {
        setState(() {
          _toplamGorevSayisi = data['toplamGorevSayisi'];
          final List<Map<String, dynamic>> rawHavuz =
          List<Map<String, dynamic>>.from(data['kesifHavuzu']);
          _kesifHavuzu = rawHavuz.map((item) {
            item['renk'] = _hexToColor(item['renkStr']);
            item['ikon'] = _getIcon(item['ikonStr']);
            return item;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Veri yükleme hatası (AnaSayfa): $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      // Liste zaten doluysa ekranı bozmadan sadece bilgilendir.
      if (_kesifHavuzu.isNotEmpty) {
        _showMessage("İçerikler güncellenemedi. Tekrar denemek için ekranı aşağı çek.");
      }
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
  }

  // ───────────────────────────── Build ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const ColoredBox(
        color: _Ui.background,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // Geniş ekranda içerik ortalanır; telefonda sabit 20 px kenar boşluğu.
    final hPad = width > _Ui.maxContentWidth + 2 * _Ui.pagePadding
        ? (width - _Ui.maxContentWidth) / 2
        : _Ui.pagePadding;

    // Alt sistem çubuğu (3 tuş / gesture) için gerçek inset kullanılır.
    final bottomSpace =
        MediaQuery.paddingOf(context).bottom +
            widget.altKaplamaBoslugu +
            _Ui.pagePadding;

    final showSkeleton = _isLoading && _kesifHavuzu.isEmpty;

    return ColoredBox(
      color: _Ui.background,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _initData,
          color: AppColors.anaMavi,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              _sliverBox(hPad, _buildHeader(), top: 16, bottom: 20),
              _sliverBox(hPad, _buildProgressCard()),
              _sliverBox(hPad, _buildSectionTitle(), top: 28, bottom: 16),
              if (showSkeleton)
                _sliverBox(hPad, _buildSkeletonList(reduceMotion))
              else if (_kesifHavuzu.isEmpty)
                _sliverBox(
                  hPad,
                  _hasError
                      ? _buildStateMessage(
                    icon: Icons.cloud_off_rounded,
                    title: "İçerikler yüklenemedi",
                    message: "Bağlantını kontrol edip tekrar dene.",
                    buttonLabel: "Tekrar dene",
                  )
                      : _buildStateMessage(
                    icon: Icons.explore_outlined,
                    title: "Henüz öneri yok",
                    message:
                    "Yeni içerikler eklendiğinde burada görünecek.",
                    buttonLabel: "Yenile",
                  ),
                  top: 24,
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, i) {
                      final card = Padding(
                        padding: const EdgeInsets.only(bottom: _Ui.itemGap),
                        child: _buildContentCard(_kesifHavuzu[i]),
                      );
                      // Sadece ilk görünen kartlar hafifçe belirir.
                      if (reduceMotion || i >= 8) return card;
                      return card
                          .animate(delay: (i * 40).ms)
                          .fadeIn(duration: 250.ms)
                          .slideY(begin: 0.06, end: 0, curve: Curves.easeOut);
                    }, childCount: _kesifHavuzu.length),
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: bottomSpace)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sliverBox(
      double hPad,
      Widget child, {
        double top = 0,
        double bottom = 0,
      }) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(hPad, top, hPad, bottom),
      sliver: SliverToBoxAdapter(child: child),
    );
  }

  // ─────────────────────────── Başlık ───────────────────────────

  Widget _buildHeader() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream,
      builder: (context, userSnap) {
        String aktifAd = widget.kullaniciAdi;
        String aktifAvatar = "assets/image/boy.png";

        if (userSnap.hasData && userSnap.data!.exists) {
          final uData = userSnap.data!.data() as Map<String, dynamic>;
          aktifAd = uData['kullaniciAdi'] ?? aktifAd;
          final String? dbAvatar = uData['avatarUrl'];
          if (dbAvatar != null && dbAvatar.isNotEmpty) {
            aktifAvatar = normalizeProfileAvatar(dbAvatar);
          }
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "KAHRAMAN GÜNLÜĞÜ",
                    style: TextStyle(
                      color: _Ui.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Selam, $aktifAd",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _Ui.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildAvatarButton(aktifAvatar),
          ],
        );
      },
    );
  }

  Widget _buildAvatarButton(String avatarPath) {
    return Semantics(
      button: true,
      label: "Profil",
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.onProfileTap,
          child: Hero(
            tag: 'profile_avatar',
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _Ui.surface,
                border: Border.all(color: _Ui.border, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: ProfileAvatar(
                  image: avatarPath,
                  radius: 24,
                  backgroundColor: _Ui.surface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── İlerleme kartı ─────────────────────────

  Widget _blob(double boyut, Color renk) {
    return IgnorePointer(
      child: Container(
        width: boyut,
        height: boyut,
        decoration: BoxDecoration(shape: BoxShape.circle, color: renk),
      ),
    );
  }

  Widget _buildProgressCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _progressStream,
      builder: (context, snap) {
        final ozet = _ozetle(snap.data);
        final double ilerleme = _toplamGorevSayisi > 0
            ? (ozet.tamamlanan / _toplamGorevSayisi).clamp(0.0, 1.0)
            : 0.0;
        final int yuzde = (ilerleme * 100).toInt();
        final reduceMotion = MediaQuery.disableAnimationsOf(context);

        return Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _Ui.surface,
            borderRadius: BorderRadius.circular(_Ui.radiusHero),
            border: Border.all(color: _Ui.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.yaziRengi.withAlpha(14),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Dekor daireler köşelerde kalır, yazı alanına girmez.
              Positioned(right: -36, top: -36, child: _blob(112, AppColors.softPink)),
              Positioned(
                left: -44,
                bottom: -52,
                child: _blob(124, AppColors.softPurple.withAlpha(150)),
              ),
              Positioned(right: 28, bottom: -34, child: _blob(72, _Ui.pointBg)),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _Ui.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.oyunSarisi.withAlpha(60),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: AppColors.oyunSarisi,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "MACERA SEVİYESİ",
                                    style: TextStyle(
                                      color: _Ui.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "%$yuzde tamamlandı ✨",
                                    style: const TextStyle(
                                      color: _Ui.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        _buildPointBadge(ozet.puan),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildProgressBar(ilerleme, yuzde, reduceMotion),
                    const SizedBox(height: 12),
                    Text(
                      _ilerlemeMesaji(ilerleme),
                      style: const TextStyle(
                        color: _Ui.textBody,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(double ilerleme, int yuzde, bool reduceMotion) {
    return Semantics(
      label: "Macera ilerlemesi",
      value: "%$yuzde",
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_Ui.radiusPill),
          child: Container(
            height: 12,
            width: double.infinity,
            color: AppColors.softPurple.withAlpha(160),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: ilerleme),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.anaMavi, AppColors.yumusakMor],
                      ),
                      borderRadius: BorderRadius.circular(_Ui.radiusPill),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPointBadge(int puan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.yaziRengi,
        borderRadius: BorderRadius.circular(_Ui.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: _Ui.pointIcon, size: 18),
          const SizedBox(width: 6),
          Text(
            "$puan puan",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Semantics(
      header: true,
      child: const Text(
        "Günün Önerileri 🚀",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: _Ui.textPrimary,
        ),
      ),
    );
  }

  /// Okunabilirlik için kart renginin koyu tonu (kategori etiketi).
  Color _koyuTon(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness(hsl.lightness > 0.4 ? 0.4 : hsl.lightness)
        .toColor();
  }

  Widget _buildContentCard(Map item) {
    final Color color = item['renk'];
    final Color koyu = _koyuTon(color);
    final String baslik = (item['baslik'] ?? '').toString();
    final radius = BorderRadius.circular(_Ui.radiusCard);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.yaziRengi.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Material + InkWell: dokunma efekti kartın üstünde görünür.
      child: Material(
        color: _Ui.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: color.withAlpha(45), width: 1.5),
        ),
        child: InkWell(
          onTap: () => _route(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(item['ikon'], color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (item['tip'] ?? '').toString(),
                        style: TextStyle(
                          color: koyu,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        baslik,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: _Ui.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _altMetin(item),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _Ui.textBody,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: koyu.withAlpha(160),
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────── Loading / Error / Empty ───────────────────

  Widget _buildSkeletonList(bool reduceMotion) {
    Widget bar(double widthFactor, double height) => FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: _Ui.border,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );

    final list = Column(
      children: List.generate(
        3,
            (_) => Container(
          margin: const EdgeInsets.only(bottom: _Ui.itemGap),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _Ui.surface,
            borderRadius: BorderRadius.circular(_Ui.radiusCard),
            border: Border.all(color: _Ui.border),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _Ui.border,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(0.3, 10),
                    const SizedBox(height: 10),
                    bar(0.8, 14),
                    const SizedBox(height: 8),
                    bar(0.6, 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      label: "İçerikler yükleniyor",
      liveRegion: true,
      child: ExcludeSemantics(
        child: reduceMotion
            ? list
            : list
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fade(begin: 0.5, end: 1.0, duration: 900.ms),
      ),
    );
  }

  Widget _buildStateMessage({
    required IconData icon,
    required String title,
    required String message,
    required String buttonLabel,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.anaMavi.withAlpha(26),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: AppColors.anaMavi, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _Ui.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: _Ui.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isLoading ? null : _initData,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.anaMavi,
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(buttonLabel, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────── Yönlendirme ─────────────────────────────

  Future<void> _route(Map item) async {
    final data = item['data'];
    if (item['tip'] == "SENARYO") {
      final docId = (item['id'] ?? '').toString().trim();
      if (docId.isEmpty) {
        _showMessage("Bu öneri artık geçersiz. Liste yenileniyor...");
        await _initData();
        return;
      }

      try {
        final doc = await FirebaseFirestore.instance
            .collection('scenarios')
            .doc(docId)
            .get();
        if (!doc.exists) {
          if (!mounted) return;
          _showMessage(
            "Bu senaryo artık mevcut değil. Diğer önerilere bakıyoruz...",
          );
          await _initData();
          return;
        }
      } catch (_) {
        if (!mounted) return;
        _showMessage("Senaryo bilgisi yüklenirken bir sorun oluştu.");
        return;
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SenaryoDetayEkrani(docId: docId, bolumIndex: 0),
        ),
      );
      return;
    } else if (item['tip'] == "HİKAYE") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HikayeDetayEkrani(
            baslik: data['baslik'],
            gorselYolu: data['gorselYolu'],
            temaRengi: item['renk'],
            hikayeMetni: data['hikayeMetni'],
            feedbackMessage: data['feedbackMessage'],
          ),
        ),
      );
    } else if (item['tip'] == "VİDEO") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoDetayEkrani(
            baslik: data['baslik'],
            youtubeId: data['youtubeId'],
            tumVideolarJson: _kesifHavuzu,
          ),
        ),
      );
    } else if (item['tip'] == "SİBER DEDEKTİF") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SiberDedektifOyunu()),
      );
    }
  }
}