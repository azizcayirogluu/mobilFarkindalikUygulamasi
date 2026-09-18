import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:just_audio/just_audio.dart';
import '../app_theme.dart';
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
  final ValueNotifier<double> _scrollProgressNotifier = ValueNotifier(0);
  final ValueNotifier<bool> _isPlayingNotifier = ValueNotifier(false);

  int _selectedSection = 0;
  String? _loadedAsset;
  String? _audioError;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  static const _quickPlanAudio = 'assets/audio/hizli_guvenlik_plani.mp3';

  static const List<_GuideSection> _sections = [
    _GuideSection(
      title: 'Zorbalığı Tanı 🔍',
      shortTitle: 'Tanı',
      icon: Icons.visibility_rounded,
      color: Color(0xFF6F8FB3),
      audioAsset: 'assets/audio/zorbaligi_tani.mp3',
      intro: 'Zorbalığı tanımak, doğru yardımı istemenin ilk adımıdır.',
      points: [
        'Şaka iki kişi de kendini iyi hissediyorsa şakadır. Bir kişi üzülüyor veya korkuyorsa durmak gerekir.',
        'Zorbalık fiziksel, sözel, sosyal ya da dijital olabilir.',
        'Bunu yaşayan kişinin suçu değildir. Yardım istemek en doğru adımdır.',
      ],
      action: 'Kendine sor: Bu davranış beni korkutuyor veya üzüyor mu?',
    ),
    _GuideSection(
      title: 'Güvende Kal 🛡️',
      shortTitle: 'Güvenlik',
      icon: Icons.shield_rounded,
      color: Color(0xFF6FA89C),
      audioAsset: 'assets/audio/guvende_kal.mp3',
      intro: 'Zor bir anda ilk hedef tartışmak değil, güvende kalmaktır.',
      points: [
        'Kendini tehlikede hissedersen tartışmaya girmeden hemen uzaklaş.',
        'Güvendiğin bir yetişkinden veya öğretmeninden destek iste.',
        'Fiziksel bir risk varsa tek başına çözmeye çalışma!',
      ],
      action: 'Kısa Plan: Uzaklaş, güvenilir bir yetişkine git ve anlat.',
    ),
    _GuideSection(
      title: 'Siber Zorbalık 📱',
      shortTitle: 'Dijital',
      icon: Icons.phonelink_lock_rounded,
      color: Color(0xFF9687B8),
      audioAsset: 'assets/audio/siber_zorbalik.mp3',
      intro: 'İnternette yapılan zorbalık da gerçektir ve engellenmelidir.',
      points: [
        'Rahatsız eden mesajın ekran görüntüsünü tarih görünecek şekilde sakla.',
        'Tartışmadan hesabı engelle ve şikayet et.',
        'Şifreni, adresini veya özel fotoğraflarını kimseyle paylaşma!',
      ],
      action: 'Kanıtı sakla, kişiyi engelle ve bir yetişkine haber ver.',
    ),
    _GuideSection(
      title: 'Arkadaşına Destek Ol 🤝',
      shortTitle: 'Destek Ol',
      icon: Icons.groups_rounded,
      color: Color(0xFFC58D72),
      audioAsset: 'assets/audio/arkadasina_destek_ol.mp3',
      intro: 'Sessiz kalmamak bir arkadaşının hayatını değiştirebilir.',
      points: [
        'Yanında olduğunu söyle: "Bu senin suçun değil, birlikte çözebiliriz."',
        'Olay tehlikeliyse araya girmek yerine hemen bir yetişkine söyle.',
        'Dedikodu veya alay videolarını sakın başkalarına yayma!',
      ],
      action: 'Nazikçe destek ol ve bir yetişkinden yardım iste.',
    ),
    _GuideSection(
      title: 'Yardım İstemek Cesarettir 🦁',
      shortTitle: 'Yardım İste',
      icon: Icons.volunteer_activism_rounded,
      color: Color(0xFFB78391),
      audioAsset: 'assets/audio/yardim_iste.mp3',
      intro: 'Sorunu tek başına taşımak zorunda değilsin!',
      points: [
        '"Bana şu oldu, kendimi güvende hissetmiyorum" demeyi deneyebilirsin.',
        'İlk kişi seni anlamazsa başka bir güvenilir yetişkine anlat.',
        'Acil bir durum varsa 112 Acil Çağrı Merkezi’nden yardım iste.',
      ],
      action: 'Hemen Seç: Aile, Öğretmen veya Rehberlik Servisi.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollProgress);
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

  void _updateScrollProgress() {
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent <= 0) return;

    final next = (_scrollController.offset / maxExtent).clamp(0.0, 1.0);
    if ((next - _scrollProgressNotifier.value).abs() > 0.01) {
      _scrollProgressNotifier.value = next;
    }
  }

  Future<void> _playAsset(String asset) async {
    try {
      setState(() => _audioError = null);

      if (_loadedAsset == asset) {
        if (_audioPlayer.processingState == ProcessingState.completed) {
          await _audioPlayer.seek(Duration.zero);
        }
        if (_audioPlayer.playing) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.play();
        }
        return;
      }

      await _audioPlayer.stop();
      final duration = await _audioPlayer.setAsset(asset);
      if (!mounted) return;

      setState(() {
        _loadedAsset = asset;
        _duration = duration ?? Duration.zero;
        _position = Duration.zero;
      });
      await _audioPlayer.play();
    } catch (_) {
      if (!mounted) return;
      _isPlayingNotifier.value = false;
      setState(() {
        _audioError = 'Ses dosyası oynatılamadı.';
      });
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
      _position = Duration.zero;
      _duration = Duration.zero;
      _audioError = null;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollProgressNotifier.dispose();
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

    return Scaffold(
      backgroundColor: AppColors.zemin,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            ValueListenableBuilder<double>(
              valueListenable: _scrollProgressNotifier,
              builder: (context, progress, _) {
                return LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  color: const Color(0xFF6F8FB3),
                  backgroundColor: AppColors.softPurple.withOpacity(0.3),
                );
              },
            ),
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHero()),
                  SliverToBoxAdapter(child: _buildSectionPicker()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
                    sliver: SliverList.list(
                      children: [
                        _buildLessonCard(section),
                        const SizedBox(height: 18),
                        _buildQuickPlan(),
                        const SizedBox(height: 18),
                        _buildAskForHelpCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildFloatingAudioPlayer(section),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.anaMavi.withOpacity(0.12),
                  blurRadius: 8,
                ),
              ],
            ),
            child: IconButton(
              tooltip: 'Geri dön',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 22,
                color: AppColors.anaMavi,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'GÜVENLİK REHBERİ 📚',
              style: TextStyle(
                color: AppColors.yaziRengi,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 12, 18, 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF7896B5), Color(0xFF9B9AC3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentMavi.withOpacity(0.3),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFD8B86A),
                size: 36,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bilgi, Gücündür! ⚡',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kısa bölümleri oku veya sesli dinle. Kendini korumayı öğren!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 250.ms).slideY(begin: -0.05),
    );
  }

  Widget _buildSectionPicker() {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: _sections.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = _sections[index];
          final selected = index == _selectedSection;
          return InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _selectSection(index),
            child: AnimatedContainer(
              duration: 200.ms,
              width: 90,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? item.color : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? item.color : item.color.withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? item.color.withOpacity(0.3)
                        : Colors.black.withOpacity(0.03),
                    blurRadius: 10,
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
                    size: 26,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.shortTitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.yaziRengi,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
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

  Widget _buildLessonCard(_GuideSection section) {
    return AnimatedSwitcher(
      duration: 250.ms,
      child: Container(
        key: ValueKey(section.title),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: section.color.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: section.color.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: section.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(section.icon, color: section.color, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section.title,
                    style: const TextStyle(
                      color: AppColors.yaziRengi,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              section.intro,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...section.points.asMap().entries.map(
              (entry) => _buildPoint(
                number: entry.key + 1,
                text: entry.value,
                color: section.color,
              ),
            ),
            const SizedBox(height: 8),
            _buildActionBox(section),
          ],
        ),
      ),
    );
  }

  Widget _buildPoint({
    required int number,
    required String text,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.yaziRengi,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBox(_GuideSection section) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: section.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: section.color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, color: section.color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              section.action,
              style: TextStyle(
                color: section.color,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPlan() {
    const steps = [
      ('1', 'Dur ve uzaklaş', 'Kendini güvene al.'),
      ('2', 'Kanıtı sakla', 'Ekran görüntüsü al veya not et.'),
      ('3', 'Yetişkine anlat', 'Yardımı birlikte iste.'),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EE),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Color(0xFFE0C98E), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: Color(0xFFC58D72)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Hızlı Güvenlik Planı ⚡',
                  style: TextStyle(
                    color: AppColors.yaziRengi,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _isPlayingNotifier,
                builder: (context, isPlaying, _) {
                  final isCurrentAudio = _loadedAsset == _quickPlanAudio;
                  return IconButton.filled(
                    tooltip: 'Dinle',
                    onPressed: () => _playAsset(_quickPlanAudio),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFE4CD93),
                      foregroundColor: AppColors.yaziRengi,
                    ),
                    icon: Icon(
                      isCurrentAudio && isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFFC58D72),
                    child: Text(
                      step.$1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: AppColors.yaziRengi,
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text: '${step.$2}: ',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          TextSpan(text: step.$3),
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

  Widget _buildAskForHelpCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9D91B8), Color(0xFFB79EAB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Color(0x4D9D91B8),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.forum_rounded, color: Colors.white, size: 26),
              SizedBox(width: 8),
              Text(
                'Aklına Bir Şey Mi Takıldı?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Siber Asistan ile konuşarak merak ettiklerini sorabilir, yalnız olmadığını hissedebilirsin.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
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
              foregroundColor: Color(0xFF756782),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_rounded),
            label: const Text(
              'Siber Asistana Sor 🤖',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  // Yenilenmiş Havada Yüzen Sevimli Ses Oynatıcı
  Widget _buildFloatingAudioPlayer(_GuideSection section) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isPlayingNotifier,
      builder: (context, isPlaying, _) {
        return StreamBuilder<Duration>(
          stream: _audioPlayer.positionStream,
          builder: (context, positionSnapshot) {
            return StreamBuilder<Duration?>(
              stream: _audioPlayer.durationStream,
              builder: (context, durationSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                final duration = durationSnapshot.data ?? Duration.zero;

                final isCurrentAudio = _loadedAsset == section.audioAsset;
                final sliderMaximum = duration.inMilliseconds > 0
                    ? duration.inMilliseconds.toDouble()
                    : 1.0;
                final sliderValue = position.inMilliseconds
                    .clamp(0, sliderMaximum.round())
                    .toDouble();

                return RepaintBoundary(
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: section.color.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: section.color.withOpacity(0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: section.color.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  section.icon,
                                  color: section.color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isCurrentAudio && isPlaying
                                          ? 'Seslendiriliyor... 🎧'
                                          : 'Sesli Dinle 🔊',
                                      style: TextStyle(
                                        color: section.color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      section.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.yaziRengi,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton.filled(
                                onPressed: () => _playAsset(section.audioAsset),
                                style: IconButton.styleFrom(
                                  backgroundColor: section.color,
                                  foregroundColor: Colors.white,
                                ),
                                icon: Icon(
                                  isCurrentAudio && isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                              ),
                            ],
                          ),
                          if (isCurrentAudio) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.yaziRengi,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderThemeData(
                                      trackHeight: 3,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6,
                                      ),
                                    ),
                                    child: Slider(
                                      value: sliderValue,
                                      max: sliderMaximum,
                                      activeColor: section.color,
                                      inactiveColor: section.color.withOpacity(
                                        0.15,
                                      ),
                                      onChanged: (value) => _seekTo(value),
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.yaziRengi,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
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
