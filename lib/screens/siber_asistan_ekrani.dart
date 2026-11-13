import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/core/ai/offline_ai_engine.dart';
import 'package:zorbalik_uygulamasi/injection_container.dart';
import 'package:zorbalik_uygulamasi/services/tts_service.dart';
import 'package:zorbalik_uygulamasi/services/ad_manager.dart';
import 'package:zorbalik_uygulamasi/utils/app_logger.dart';
import 'package:zorbalik_uygulamasi/screens/siber_imdat_ekrani.dart';

/// Bu ekrana özel tasarım sabitleri (Kahraman Dostum evrenine özel ölçü dili).
class _Ui {
  static const background = AppColors.zemin;
  static const surface = Colors.white;
  static const textPrimary = AppColors.yaziRengi;
  static const textSecondary = Color(0xFF6B7088);
  static const textBody = Color(0xFF565B73);
  static const border = Color(0xFFE6E8F5);
  static const inputFill = Color(0xFFF1F3FB);
  static const pointBg = Color(0xFFFFF4DC);
  static const pointText = Color(0xFF7A4B00);
  static const dangerText = Color(0xFFB03A57);

  static const radiusBubble = 20.0;
  static const radiusTail = 6.0;
  static const radiusInput = 24.0;
  static const radiusDialog = 24.0;

  static const chatPadding = 16.0;
}

BoxDecoration _balonDekor({required bool isMe}) {
  return BoxDecoration(
    color: isMe ? AppColors.anaMavi : _Ui.surface,
    borderRadius: BorderRadius.only(
      topLeft: const Radius.circular(_Ui.radiusBubble),
      topRight: const Radius.circular(_Ui.radiusBubble),
      bottomLeft: Radius.circular(isMe ? _Ui.radiusBubble : _Ui.radiusTail),
      bottomRight: Radius.circular(isMe ? _Ui.radiusTail : _Ui.radiusBubble),
    ),
    border: isMe
        ? null
        : Border.all(color: AppColors.softPurple.withValues(alpha: 0.6), width: 1.5),
    boxShadow: [
      BoxShadow(
        color: AppColors.yaziRengi.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

class SiberAsistanEkrani extends StatefulWidget {
  const SiberAsistanEkrani({super.key});

  @override
  State<SiberAsistanEkrani> createState() => _SiberAsistanEkraniState();
}

class _SiberAsistanEkraniState extends State<SiberAsistanEkrani> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TtsService _ttsService = sl<TtsService>();
  final AdManager _adManager = sl<AdManager>();
  final OfflineAIEngine _offlineEngine = OfflineAIEngine();
  User? get _currentUser => FirebaseAuth.instance.currentUser;

  final List<Map<String, String>> _mesajlar = [];
  bool _yukleniyor = false;
  bool _sesAcik = false;
  bool _isExempt = false;
  int _kalanHak = 5;

  late bool _ilkYukleme;

  @override
  void initState() {
    super.initState();
    _ilkYukleme = _currentUser != null;
    _adManager.loadRewardedAd(onAdLoaded: () {});
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    final user = _currentUser;
    if (user == null) {
      AppLogger.log("SiberAsistan: Oturum açmış kullanıcı bulunamadı.");
      if (mounted) setState(() => _ilkYukleme = false);
      return;
    }
    final uid = user.uid;

    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (mounted && userDoc.exists) {
        setState(() {
          _isExempt = userDoc.data()?['isAdmin'] == true ||
              userDoc.data()?['isPremium'] == true;
        });
      }

      final progressDoc = await FirebaseFirestore.instance
          .collection('usersProgress')
          .doc(uid)
          .get();
      if (mounted && progressDoc.exists) {
        final pData = progressDoc.data();
        if (pData != null) {
          setState(() {
            _kalanHak = pData['gemini_hakki'] ?? 5;
          });
        }
      }

      _mesajlar.clear();
      _ilkMesajEkle();
      _scrollToBottom();
    } catch (e) {
      debugPrint("Veri yükleme hatası: $e");
    } finally {
      if (mounted) setState(() => _ilkYukleme = false);
    }
  }

  void _ilkMesajEkle() {
    final ad = _currentUser?.displayName ?? "Kahraman";
    setState(() {
      _mesajlar.add({
        "role": "assistant",
        "metin":
        "Selam $ad! Ben Siber Dost. Aklına takılan bir şey varsa, yaşadığın bir durumu anlatmak ya da bir konuda ne yapabileceğini öğrenmek istiyorsan buradayımm."
      });
    });
  }

  void clearChatSession() {
    if (mounted) {
      setState(() {
        _mesajlar.clear();
        _ilkMesajEkle();
      });
    } else {
      _mesajlar.clear();
    }
  }

  Future<void> _sohbetiTemizle() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: _Ui.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_Ui.radiusDialog)),
        icon: const _DialogIkon(
          icon: Icons.delete_outline_rounded,
          background: AppColors.softPink,
          color: _Ui.dangerText,
        ),
        title: const Text("Sohbeti temizleyelim mi?"),
        titleTextStyle: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800, color: _Ui.textPrimary),
        content: const Text(
          "Bu oturumdaki tüm mesajlar temizlenecek. Yeni bir sohbet başlatmak ister misin?",
          textAlign: TextAlign.center,
        ),
        contentTextStyle:
            const TextStyle(fontSize: 14, height: 1.4, color: _Ui.textBody),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: () => Navigator.pop(c, false),
            child: const Text("Vazgeç",
                style: TextStyle(
                    color: _Ui.textSecondary, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: () => Navigator.pop(c, true),
            child: const Text("Evet, temizle",
                style: TextStyle(
                    color: _Ui.dangerText, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (onay == true) {
      clearChatSession();
    }
  }

  Future<void> _mesajGonder(String metin) async {
    final temizMetin = metin.trim();
    if (temizMetin.isEmpty || _yukleniyor) return;
    if (!_isExempt && _kalanHak <= 0) {
      _enerjiUyarisi();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppLogger.error(
          "SiberAsistan: Mesaj gönderilemedi, oturum kapalı.", "unauthenticated");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Mesaj göndermek için lütfen giriş yapın."),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final sessionHistory = _mesajlar
        .where((m) => (m['metin'] ?? '').isNotEmpty)
        .map((m) => {
              'rol': m['role'] == 'user' ? 'user' : 'assistant',
              'metin': m['metin'] ?? '',
            })
        .toList();

    setState(() {
      _mesajlar.add({"role": "user", "metin": temizMetin});
      _yukleniyor = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      AppLogger.log(
        "SIBER_ASISTAN_CALL: "
        "Project: ${Firebase.app().options.projectId}, "
        "Region: europe-west1, "
        "Function: geminiChat, "
        "UID: ${user.uid}",
      );

      await user.getIdToken();

      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('geminiChat');
      final result = await callable.call({
        'mesaj': temizMetin,
        'gecmis': sessionHistory,
      });
      if (!mounted) return;
      final data = result.data as Map?;
      final botCevabi = data?['cevap']?.toString() ?? 'Buradayım Kahraman! 💙';

      setState(() {
        _yukleniyor = false;
        _mesajlar.add({"role": "assistant", "metin": botCevabi});
        if (data?['newLimit'] != null) _kalanHak = data!['newLimit'];
      });

      if (_sesAcik) _ttsService.speak(botCevabi);
      if (data?['riskLevel'] == 'IMMINENT') _tehlikeYonlendirmesi();
    } on FirebaseFunctionsException catch (e, stack) {
      AppLogger.error(
          "geminiChat FirebaseFunctionsException: [${e.code}] ${e.message}",
          e,
          stack);

      if (e.code == 'unauthenticated') {
        try {
          AppLogger.log(
              "SiberAsistan: Unauthenticated hatası alındı, token yenilenerek tekrar deneniyor...");
          await user.getIdToken(true);
          final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
              .httpsCallable('geminiChat');
          final retryResult = await callable.call({
            'mesaj': temizMetin,
            'gecmis': sessionHistory,
          });
          if (!mounted) return;
          final retryData = retryResult.data as Map?;
          final botCevabi =
              retryData?['cevap']?.toString() ?? 'Buradayım Kahraman! 💙';

          setState(() {
            _yukleniyor = false;
            _mesajlar.add({"role": "assistant", "metin": botCevabi});
            if (retryData?['newLimit'] != null) {
              _kalanHak = retryData!['newLimit'];
            }
          });

          if (_sesAcik) _ttsService.speak(botCevabi);
          if (retryData?['riskLevel'] == 'IMMINENT') _tehlikeYonlendirmesi();
          _scrollToBottom();
          return;
        } catch (retryError, retryStack) {
          AppLogger.error("SiberAsistan retry hatası", retryError, retryStack);
        }
      }

      final offlineCevap =
          await _offlineEngine.getResponseForMessage(temizMetin);
      if (mounted) {
        setState(() {
          _yukleniyor = false;
          _mesajlar.add({"role": "assistant", "metin": offlineCevap});
        });
        if (_sesAcik) _ttsService.speak(offlineCevap);
      }
    } catch (e, stack) {
      debugPrint("geminiChat Hatasi: $e");
      AppLogger.error("Siber Asistan geminiChat Hatasi", e, stack);
      final offlineCevap =
          await _offlineEngine.getResponseForMessage(temizMetin);
      if (mounted) {
        setState(() {
          _yukleniyor = false;
          _mesajlar.add({"role": "assistant", "metin": offlineCevap});
        });
        if (_sesAcik) _ttsService.speak(offlineCevap);
      }
    }
    _scrollToBottom();
  }

  void _tehlikeYonlendirmesi() {
    Future.delayed(1.seconds, () {
      if (mounted) {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const SiberImdatEkrani()));
      }
    });
  }

  void _enerjiUyarisi() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: _Ui.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_Ui.radiusDialog)),
        icon: const _DialogIkon(
          icon: Icons.bolt_rounded,
          background: _Ui.pointBg,
          color: AppColors.oyunSarisi,
        ),
        title: const Text("Siber Enerjin Bitti"),
        titleTextStyle: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800, color: _Ui.textPrimary),
        content: const Text(
          "Siber Dost'un biraz dinlenmesi gerek. Kısa bir video izleyerek +5 Siber Enerji kazanabilirsin!",
          textAlign: TextAlign.center,
        ),
        contentTextStyle:
            const TextStyle(fontSize: 14, height: 1.4, color: _Ui.textBody),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: () => Navigator.pop(c),
            child: const Text("Vazgeç",
                style: TextStyle(
                    color: _Ui.textSecondary, fontWeight: FontWeight.w600)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.anaMavi,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.pop(c);
              _reklamIzle();
            },
            icon: const Icon(Icons.play_circle_rounded, size: 20),
            label: const Text("Kazan (+5 ⚡)",
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _reklamIzle() {
    _adManager.showRewardedAd(
      onUserEarnedReward: () async {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await user.getIdToken();
          }
          final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
              .httpsCallable('grantAdReward');
          await callable.call();
          if (mounted) {
            setState(() {
              _kalanHak += 5;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  "Harika! +5 Siber Enerji Kazandın! ⚡",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                backgroundColor: AppColors.basariYesili,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            );
          }
        } catch (e) {
          AppLogger.error("Ödül işleme hatası", e);
        }
      },
      onAdClosed: () {
        _adManager.loadRewardedAd(onAdLoaded: () {});
      },
    );
  }

  @override
  void dispose() {
    _ttsService.stop();
    _controller.dispose();
    _scrollController.dispose();
    _mesajlar.clear();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: 300.ms,
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final klavyeAcik = MediaQuery.viewInsetsOf(context).bottom > 0;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _mesajlar.clear();
        }
      },
      child: Scaffold(
        backgroundColor: _Ui.background,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildStatsBar(),
            Expanded(child: _buildMessageList(reduceMotion)),
            if (_yukleniyor) _buildTypingIndicator(reduceMotion),
            if (!klavyeAcik) _buildQuickActions(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _Ui.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      leading: IconButton(
        tooltip: "Geri",
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 20, color: _Ui.textBody),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const _KahramanDostumBilgiSheet(),
          );
        },
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            const _BotAvatar(size: 40, isOnline: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Kahraman Dostum",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _Ui.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.basariYesili,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "Buradayım · Güvenli Alan",
                        style: TextStyle(
                          color: AppColors.basariYesili,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          tooltip: "Sohbeti temizle",
          icon: const Icon(Icons.delete_outline_rounded,
              color: _Ui.textBody, size: 22),
          onPressed: _sohbetiTemizle,
        ),
        IconButton(
          tooltip: _sesAcik ? "Sesli okumayı kapat" : "Sesli okumayı aç",
          icon: Icon(
            _sesAcik ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            color: _sesAcik ? AppColors.anaMavi : _Ui.textBody,
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _sesAcik = !_sesAcik;
              if (!_sesAcik) _ttsService.stop();
            });
          },
        ),
        const SizedBox(width: 6),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: _Ui.border),
      ),
    );
  }

  Widget _buildStatsBar() {
    final enerjiBitti = !_isExempt && _kalanHak <= 0;
    final int hakGosterim = _kalanHak.clamp(0, 5);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: _Ui.chatPadding, vertical: 10),
      decoration: BoxDecoration(
        color: _Ui.surface,
        border: const Border(bottom: BorderSide(color: _Ui.border, width: 1)),
      ),
      child: Row(
        children: [
          // Gamified Energy Badge
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      _isExempt
                          ? "Sınırsız mesaj hakkına sahipsin! ✨"
                          : "Her mesaj 1 Siber Enerji tüketir. Enerjin bittiğinde video izleyerek +5 Enerji kazanabilirsin! ⚡",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: AppColors.anaMavi,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 4),
                  ),
                );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: enerjiBitti ? AppColors.softPink : _Ui.pointBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: enerjiBitti
                      ? _Ui.dangerText.withValues(alpha: 0.3)
                      : AppColors.oyunSarisi.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    color: enerjiBitti ? _Ui.dangerText : AppColors.oyunSarisi,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isExempt ? "Sınırsız Güç" : "⚡ $_kalanHak Enerji",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: enerjiBitti ? _Ui.dangerText : _Ui.pointText,
                    ),
                  ),
                  if (!_isExempt) ...[
                    const SizedBox(width: 8),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Container(
                          margin: const EdgeInsets.only(left: 2),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index < hakGosterim
                                ? AppColors.oyunSarisi
                                : Colors.black12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Spacer(),
          const Icon(Icons.lock_outline_rounded,
              size: 13, color: _Ui.textSecondary),
          const SizedBox(width: 4),
          const Text(
            "Geçici Sohbet 🔒",
            style: TextStyle(
              fontSize: 11,
              color: _Ui.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(bool reduceMotion) {
    if (_mesajlar.isEmpty) {
      return Center(
        child: _ilkYukleme
            ? const CircularProgressIndicator()
            : SingleChildScrollView(child: _buildEmptyState()),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding:
          const EdgeInsets.fromLTRB(_Ui.chatPadding, 16, _Ui.chatPadding, 8),
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: _mesajlar.length,
      itemBuilder: (context, index) {
        final msg = _mesajlar[index];
        final isMe = msg['role'] == 'user';
        final balon = _ChatBubble(msg: msg, isMe: isMe);
        if (reduceMotion || index != _mesajlar.length - 1) return balon;
        return balon
            .animate()
            .fadeIn(duration: 200.ms)
            .slideY(begin: 0.03, end: 0, curve: Curves.easeOut);
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _BotAvatar(size: 80, isOnline: true),
          const SizedBox(height: 20),
          const Text(
            "Selam Kahraman! 👋",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _Ui.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Bugün aklına takılan ne var?",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.anaMavi,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _Ui.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x05000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              "İnternette, arkadaşlıklarında veya zorbalıkla ilgili merak ettiğin her şeyi bana sorabilirsin.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: _Ui.textBody,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool reduceMotion) {
    Widget nokta(int i) {
      final dot = Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.anaMavi.withValues(alpha: 0.8),
        ),
      );
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: reduceMotion
            ? dot
            : dot
                .animate(
                  delay: (i * 160).ms,
                  onPlay: (c) => c.repeat(reverse: true),
                )
                .fade(begin: 0.3, end: 1.0, duration: 500.ms),
      );
    }

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(_Ui.chatPadding, 0, _Ui.chatPadding, 12),
      child: Semantics(
        label: "Siber Dost düşünüyor",
        liveRegion: true,
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const _BotAvatar(size: 32),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: _balonDekor(isMe: false),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Düşünüyorum ",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _Ui.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    nokta(0),
                    nokta(1),
                    nokta(2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      (
        icon: Icons.shield_rounded,
        title: "Güvende kalmak istiyorum",
        color: const Color(0xFF10B981),
        prompt: "İnternette nasıl daha güvende kalabilirim? 🛡️",
      ),
      (
        icon: Icons.chat_bubble_rounded,
        title: "Bir şey oldu, anlatmak istiyorum",
        color: const Color(0xFF6366F1),
        prompt: "Birisi canımı sıktı, seninle konuşmak istiyorum. 💬",
      ),
      (
        icon: Icons.search_rounded,
        title: "Bu davranım zorbalık mı?",
        color: const Color(0xFFF59E0B),
        prompt: "Bana yapılan şey zorbalık mı, nasıl anlarım? 🔎",
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding:
          const EdgeInsets.fromLTRB(_Ui.chatPadding, 4, _Ui.chatPadding, 10),
      child: Row(
        children: [
          for (final item in actions)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _yukleniyor ? null : () => _mesajGonder(item.prompt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: item.color.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: item.color.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.icon, color: item.color, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: _Ui.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: item.color,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_Ui.radiusInput),
      borderSide: BorderSide.none,
    );

    return Container(
      decoration: const BoxDecoration(
        color: _Ui.surface,
        border: Border(top: BorderSide(color: _Ui.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Kişisel bilgi uyarı çubuğu (Çocuk güvenliği)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              color: const Color(0xFFEFF6FF),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined,
                      size: 12, color: Color(0xFF3B82F6)),
                  SizedBox(width: 6),
                  Text(
                    "🔒 Kişisel bilgilerini (adres, telefon, şifre) kimseyle paylaşma.",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  _Ui.chatPadding, 10, _Ui.chatPadding, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.send,
                      textCapitalization: TextCapitalization.sentences,
                      style:
                          const TextStyle(fontSize: 15, color: _Ui.textPrimary),
                      decoration: InputDecoration(
                        hintText: "Siber Dost'a bir şey sor...",
                        hintStyle: const TextStyle(
                            color: _Ui.textSecondary, fontSize: 14),
                        filled: true,
                        fillColor: _Ui.inputFill,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(_Ui.radiusInput),
                          borderSide: BorderSide(
                              color: AppColors.anaMavi.withValues(alpha: 0.9),
                              width: 1.5),
                        ),
                      ),
                      onSubmitted: _mesajGonder,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildSendButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return Semantics(
      button: true,
      enabled: !_yukleniyor,
      label: "Gönder",
      child: Material(
        color: _yukleniyor
            ? AppColors.anaMavi.withValues(alpha: 0.4)
            : AppColors.anaMavi,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _yukleniyor ? null : () => _mesajGonder(_controller.text),
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final Map<String, String> msg;
  final bool isMe;
  const _ChatBubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final metin = msg['metin'] ?? '';

    return Semantics(
      label: "${isMe ? 'Sen' : 'Siber Dost'}: $metin",
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: LayoutBuilder(
            builder: (context, box) {
              final avatarAlani = isMe ? 0.0 : 42.0;
              final maxBalon =
                  (box.maxWidth * 0.84 - avatarAlani).clamp(0.0, 520.0).toDouble();

              return Row(
                mainAxisAlignment:
                    isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isMe) ...[
                    const _BotAvatar(size: 34),
                    const SizedBox(width: 8)
                  ],
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxBalon),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: _balonDekor(isMe: isMe),
                      child: Text(
                        metin,
                        style: TextStyle(
                          color: isMe ? Colors.white : _Ui.textPrimary,
                          fontSize: 14.5,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BotAvatar extends StatelessWidget {
  final double size;
  final bool isOnline;
  const _BotAvatar({required this.size, this.isOnline = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.anaMavi, AppColors.yumusakMor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.anaMavi.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              color: AppColors.anaMavi,
              size: size * 0.55,
            ),
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.basariYesili,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _DialogIkon extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color color;
  const _DialogIkon(
      {required this.icon, required this.background, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(shape: BoxShape.circle, color: background),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

// ───────────────────────────── Bilgilendirme Sayfası ─────────────────────────────

class _KahramanDostumBilgiSheet extends StatelessWidget {
  const _KahramanDostumBilgiSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _Ui.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(_Ui.radiusDialog),
          topRight: Radius.circular(_Ui.radiusDialog),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _Ui.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(child: _BotAvatar(size: 84, isOnline: true)),
              const SizedBox(height: 16),
              const Text(
                "Siber Dost",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _Ui.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Senin siber güvenlik arkadaşın! 🌟",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.anaMavi,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Siber Dost; dijital dünyada güvende kalman, zorbalığın ne olduğunu öğrenmen ve merak ettiğin her şeyi sorman için tasarlanmış yapay zekâ destekli arkadaşındır.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: _Ui.textBody,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 36),
              const _BolumBasligi(ikon: "✨", baslik: "NELER YAPABİLİRİM?"),
              const SizedBox(height: 16),
              _AksiyonKarti(
                icon: Icons.question_answer_rounded,
                text: "Merak ettiklerini istediğin an sorabilirsin",
                iconColor: AppColors.anaMavi,
                bgColor: AppColors.anaMavi.withValues(alpha: 0.1),
              ),
              _AksiyonKarti(
                icon: Icons.shield_rounded,
                text:
                    "Zorbalıkla karşı karşıya kalınca ne yapabileceğini öğrenebilirsin",
                iconColor: AppColors.oyunSarisi,
                bgColor: _Ui.pointBg,
              ),
              _AksiyonKarti(
                icon: Icons.search_rounded,
                text: "Neyin zorbalık olup olmadığını keşfedebilirsin",
                iconColor: AppColors.basariYesili,
                bgColor: AppColors.basariYesili.withValues(alpha: 0.12),
              ),
              _AksiyonKarti(
                icon: Icons.sports_esports_rounded,
                text: "Eğitici oyunlar oynayabilirsin",
                iconColor: AppColors.yaziRengi,
                bgColor: AppColors.softPurple.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 32),
              const _BolumBasligi(
                  ikon: "🔒", baslik: "GİZLİLİK VE VERİ GÜVENLİĞİ"),
              const SizedBox(height: 16),
              _AksiyonKarti(
                icon: Icons.cleaning_services_rounded,
                text:
                    "Sohbetlerin veritabanında saklanmaz. Bu sayfadan ayrıldığında tüm konuşmalar tamamen temizlenir.",
                iconColor: AppColors.anaMavi,
                bgColor: AppColors.anaMavi.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 32),
              const _BolumBasligi(ikon: "🧠", baslik: "YAPAY ZEKÂ ALTYAPISI"),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _Ui.inputFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.auto_awesome_rounded,
                          color: AppColors.anaMavi, size: 22),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Gemini",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: _Ui.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Google'ın yapay zekâ teknolojisiyle desteklenmektedir.",
                            style: TextStyle(
                              fontSize: 13,
                              color: _Ui.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gpp_good_outlined,
                      color: _Ui.textSecondary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "GÜVENLİ ÖĞRENME",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: _Ui.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "Siber Dost, çocuklara zorbalık farkındalığı aşılamak için eğitici, güvenli ve yaşa uygun bir deneyim sunmak üzere tasarlanmıştır.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: _Ui.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.anaMavi,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Anladım, Kapat",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BolumBasligi extends StatelessWidget {
  final String ikon;
  final String baslik;

  const _BolumBasligi({required this.ikon, required this.baslik});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(ikon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          baslik,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: _Ui.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _AksiyonKarti extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;
  final Color bgColor;

  const _AksiyonKarti({
    required this.icon,
    required this.text,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Ui.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: _Ui.textSecondary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _Ui.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
