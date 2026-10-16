import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'siber_asistan_ekrani.dart';

class GuvenlikRehberiEkrani extends StatefulWidget {
  const GuvenlikRehberiEkrani({super.key});

  @override
  State<GuvenlikRehberiEkrani> createState() => _GuvenlikRehberiEkraniState();
}

class _GuvenlikRehberiEkraniState extends State<GuvenlikRehberiEkrani> {
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final ValueNotifier<bool> _isPlayingNotifier = ValueNotifier(false);

  int _selectedSection = 0;
  String? _loadedAsset;

  static const _quickPlanAudio = 'assets/audio/hizli_guvenlik_plani.mp3';

  static const List<_GuideSection> _sections = [
    _GuideSection(
      title: 'Zorbalığı Tanı 🔍',
      shortTitle: 'Tanı',
      icon: Icons.visibility_rounded,
      color: Color(0xFF3B82F6),
      audioAsset: 'assets/audio/zorbaligi_tani.mp3',
      intro: 'Zorbalığı tanımak, doğru yardımı istemenin ilk adımıdır.',
      points: [
        'Şaka iki kişi de kendini iyi hissediyorsa şakadır. Bir kişi üzülüyor veya korkuyorsa durmak gerekir.',
        'Zorbalık fiziksel, sözel, sosyal ya da dijital olabilir.',
        'Bunu yaşayan kişinin suçu değildir. Yardım istemek en doğru adımdır.',
      ],
      action: 'Bu davranış beni korkutuyor veya üzüyor mu?',
    ),
    _GuideSection(
      title: 'Güvende Kal 🛡️',
      shortTitle: 'Güvenlik',
      icon: Icons.shield_rounded,
      color: Color(0xFF10B981),
      audioAsset: 'assets/audio/guvende_kal.mp3',
      intro: 'Zor bir anda ilk hedef tartışmak değil, güvende kalmaktır.',
      points: [
        'Kendini tehlikede hissedersen tartışmaya girmeden hemen uzaklaş.',
        'Güvendiğin bir yetişkinden veya öğretmeninden destek iste.',
        'Fiziksel bir risk varsa tek başına çözmeye çalışma!',
      ],
      action: 'Tartışmaya girmeden hemen uzaklaş ve güvenli bir yere geç.',
    ),
    _GuideSection(
      title: 'Siber Zorbalık 📱',
      shortTitle: 'Dijital',
      icon: Icons.phonelink_lock_rounded,
      color: Color(0xFF8B5CF6),
      audioAsset: 'assets/audio/siber_zorbalik.mp3',
      intro: 'İnternette yapılan zorbalık da gerçektir ve engellenmelidir.',
      points: [
        'Rahatsız eden mesajın ekran görüntüsünü tarih görünecek şekilde sakla.',
        'Tartışmadan hesabı engelle ve şikayet et.',
        'Şifreni, adresini veya özel fotoğraflarını kimseyle paylaşma!',
      ],
      action: 'Ekran görüntüsü al, hesabı engelle ve bir yetişkine haber ver.',
    ),
    _GuideSection(
      title: 'Arkadaşına Destek Ol 🤝',
      shortTitle: 'Destek Ol',
      icon: Icons.groups_rounded,
      color: Color(0xFFF59E0B),
      audioAsset: 'assets/audio/arkadasina_destek_ol.mp3',
      intro: 'Sessiz kalmamak bir arkadaşının hayatını değiştirebilir.',
      points: [
        'Yanında olduğunu söyle: "Bu senin suçun değil, birlikte çözebiliriz."',
        'Olay tehlikeliyse araya girmek yerine hemen bir yetişkine söyle.',
        'Dedikodu veya alay videolarını sakın başkalarına yayma!',
      ],
      action: 'Arkadaşının yanında olduğunu hissettir ve yetişkine söyle.',
    ),
    _GuideSection(
      title: 'Yardım İstemek Cesarettir 🦁',
      shortTitle: 'Yardım İste',
      icon: Icons.volunteer_activism_rounded,
      color: Color(0xFFEC4899),
      audioAsset: 'assets/audio/yardim_iste.mp3',
      intro: 'Sorunu tek başına taşımak zorunda değilsin!',
      points: [
        '"Bana şu oldu, kendimi güvende hissetmiyorum" demeyi deneyebilirsin.',
        'İlk kişi seni anlamazsa başka bir güvenilir yetişkine anlat.',
        'Acil bir durum varsa 112 Acil Çağrı Merkezi’nden yardım iste.',
      ],
      action: 'Ailen, öğretmenlerin veya rehberlik servisi sana yardım için burada.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _listenToAudio();
  }

  void _listenToAudio() {
    _subscriptions.add(
      _audioPlayer.playerStateStream.listen((state) {
        if (!mounted) return;
        _isPlayingNotifier.value = state.playing;
      }),
    );
  }

  Future<void> _playAsset(String asset) async {
    try {
      if (_loadedAsset == asset) {
        if (_audioPlayer.playing) {
          await _audioPlayer.pause();
        } else {
          if (_audioPlayer.processingState == ProcessingState.completed) {
            await _audioPlayer.seek(Duration.zero);
          }
          await _audioPlayer.play();
        }
        return;
      }

      await _audioPlayer.stop();

      final ByteData data = await rootBundle.load(asset);
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = asset.split('/').last;
      final File tempFile = File('${tempDir.path}/$fileName');

      await tempFile.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );

      await _audioPlayer.setFilePath(tempFile.path);

      if (!mounted) return;
      setState(() {
        _loadedAsset = asset;
      });
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Ses Oynatma Hatası: $e');
      if (!mounted) return;
      _isPlayingNotifier.value = false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ses yüklenemedi: $asset'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _seekTo(double milliseconds) async {
    await _audioPlayer.seek(Duration(milliseconds: milliseconds.round()));
  }

  Future<void> _selectSection(int index) async {
    if (_selectedSection == index) return;
    await _audioPlayer.stop();
    if (!mounted) return;
    setState(() {
      _selectedSection = index;
      _loadedAsset = null;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _isPlayingNotifier.dispose();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final section = _sections[_selectedSection];
    final bottomInset = MediaQuery.paddingOf(context).bottom + 30;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Güvenlik Rehberi",
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0F4F46E5),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: Color(0xFF475569),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  children: [
                    _buildSubHeader(),
                    const SizedBox(height: 16),
                    _buildLearningTipCard(),
                    const SizedBox(height: 20),
                    _buildCategoryNavigation(),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset),
              sliver: SliverList.list(
                children: [
                  _buildContentCard(section),
                  const SizedBox(height: 20),
                  _buildSelfReflectionCard(section),
                  const SizedBox(height: 20),
                  _buildQuickActionPlan(),
                  const SizedBox(height: 20),
                  _buildAskAssistantCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubHeader() {
    return const Center(
      child: Text(
        "Bilgi, kendini korumanın ilk adımıdır. 💡",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLearningTipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Color(0xFFF59E0B),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bilgi, Güçtür! ⚡",
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Kısa bilgileri oku, kendini korumayı öğren.",
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.04);
  }

  Widget _buildCategoryNavigation() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _sections.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = _sections[index];
          final bool selected = index == _selectedSection;

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _selectSection(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 92,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? item.color : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? item.color
                      : item.color.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? item.color.withValues(alpha: 0.3)
                        : const Color(0x05000000),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    color: selected ? Colors.white : item.color,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.shortTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF1E293B),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentCard(_GuideSection section) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(section.title),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: section.color.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: section.color.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kart Başlığı ve Satır İçi Ses Dinleme Butonu
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: section.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(section.icon, color: section.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section.title,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _buildInlineAudioButton(section.audioAsset, section.color),
              ],
            ),

            // Satır içi oynatıcı detay paneli (Eğer o an oynatılıyorsa)
            _buildInlinePlayerProgress(section),

            const SizedBox(height: 16),
            Text(
              section.intro,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            ...section.points.asMap().entries.map(
                  (entry) => _buildPointItem(
                number: entry.key + 1,
                text: entry.value,
                color: section.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineAudioButton(String audioAsset, Color color) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isPlayingNotifier,
      builder: (context, isPlaying, _) {
        final isCurrent = _loadedAsset == audioAsset;
        final bool activePlaying = isCurrent && isPlaying;

        return ElevatedButton.icon(
          onPressed: () => _playAsset(audioAsset),
          style: ElevatedButton.styleFrom(
            backgroundColor: activePlaying ? color : color.withValues(alpha: 0.12),
            foregroundColor: activePlaying ? Colors.white : color,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: Icon(
            activePlaying ? Icons.pause_rounded : Icons.volume_up_rounded,
            size: 18,
          ),
          label: Text(
            activePlaying ? 'Durdur' : 'Dinle 🎧',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInlinePlayerProgress(_GuideSection section) {
    if (_loadedAsset != section.audioAsset) return const SizedBox.shrink();

    return StreamBuilder<Duration>(
      stream: _audioPlayer.positionStream,
      builder: (context, positionSnapshot) {
        return StreamBuilder<Duration?>(
          stream: _audioPlayer.durationStream,
          builder: (context, durationSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final duration = durationSnapshot.data ?? Duration.zero;
            final sliderMaximum = duration.inMilliseconds > 0
                ? duration.inMilliseconds.toDouble()
                : 1.0;
            final sliderValue = position.inMilliseconds
                .clamp(0, sliderMaximum.round())
                .toDouble();

            return Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: section.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(
                    _formatDuration(position),
                    style: TextStyle(
                      fontSize: 10,
                      color: section.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 5,
                        ),
                      ),
                      child: Slider(
                        value: sliderValue,
                        max: sliderMaximum,
                        activeColor: section.color,
                        inactiveColor: section.color.withValues(alpha: 0.2),
                        onChanged: (val) => _seekTo(val),
                      ),
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(
                      fontSize: 10,
                      color: section.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPointItem({
    required int number,
    required String text,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Text(
              '0$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfReflectionCard(_GuideSection section) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: section.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: section.color.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_rounded, color: section.color, size: 22),
              const SizedBox(width: 8),
              Text(
                "Kendine Sor 🤔",
                style: TextStyle(
                  color: section.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            section.action,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionPlan() {
    const steps = [
      ('01', 'Uzaklaş', 'Tartışmaya girmeden güvenli bir yere geç.'),
      ('02', 'Kanıtını Koru', 'Mesajları veya ekran görüntülerini sakla.'),
      ('03', 'Birine Anlat', 'Güvendiğin bir yetişkinden yardım iste.'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: Color(0xFFD97706), size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Şimdi Ne Yapabilirim? ⚡',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _isPlayingNotifier,
                builder: (context, isPlaying, _) {
                  final isCurrent = _loadedAsset == _quickPlanAudio;
                  final activePlaying = isCurrent && isPlaying;

                  return IconButton.filled(
                    tooltip: 'Dinle',
                    onPressed: () => _playAsset(_quickPlanAudio),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFDE68A),
                      foregroundColor: const Color(0xFF92400E),
                    ),
                    icon: Icon(
                      activePlaying
                          ? Icons.pause_rounded
                          : Icons.volume_up_rounded,
                      size: 20,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...steps.map(
                (step) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      step.$1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 13,
                          height: 1.35,
                        ),
                        children: [
                          TextSpan(
                            text: '${step.$2}: ',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          TextSpan(
                            text: step.$3,
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAskAssistantCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x336366F1),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.smart_toy_rounded, color: Colors.white, size: 26),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Aklına Bir Şey Mi Takıldı?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Siber Asistan ile konuşarak merak ettiklerini sorabilir, yalnız olmadığını hissedebilirsin.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SiberAsistanEkrani()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF4F46E5),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.chat_bubble_rounded, size: 18),
            label: const Text(
              'Siber Asistana Sor 🤖',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _GuideSection {
  const _GuideSection({
    required this.title,
    required this.shortTitle,
    required this.icon,
    required this.color,
    required this.audioAsset,
    required this.intro,
    required this.points,
    required this.action,
  });

  final String title;
  final String shortTitle;
  final IconData icon;
  final Color color;
  final String audioAsset;
  final String intro;
  final List<String> points;
  final String action;
}
