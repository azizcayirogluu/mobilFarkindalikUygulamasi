import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';

class PasswordAnalysisResult {
  final double score;
  final String label;
  final Color color;
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;
  final bool hasSpecialChar;
  final bool isCommonPassword;
  final String feedbackMessage;

  const PasswordAnalysisResult({
    required this.score,
    required this.label,
    required this.color,
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSpecialChar,
    required this.isCommonPassword,
    required this.feedbackMessage,
  });

  static PasswordAnalysisResult analyze(String rawPassword) {
    final password = rawPassword.trim();

    if (password.isEmpty) {
      return const PasswordAnalysisResult(
        score: 0.0,
        label: "Şifreni Yaz 🔒",
        color: Color(0xFF94A3B8),
        hasMinLength: false,
        hasUppercase: false,
        hasLowercase: false,
        hasNumber: false,
        hasSpecialChar: false,
        isCommonPassword: false,
        feedbackMessage: "Sayı, harf ve özel karakterler kullanarak örnek bir şifre yaz.",
      );
    }

    const commonPasswords = {
      '123456',
      'password',
      'qwerty',
      '12345678',
      '111111',
      '000000',
      '123123',
      'abc123',
      '123456789',
      '87654321',
      'şifre',
      'sifre',
      '1234',
      '12345',
      'admin',
      'iloveyou',
      'mehmet',
      'ahmet',
      '1234567',
    };

    if (commonPasswords.contains(password.toLowerCase())) {
      return const PasswordAnalysisResult(
        score: 0.1,
        label: "Çok Zayıf 🚫",
        color: Color(0xFFEF4444),
        hasMinLength: false,
        hasUppercase: false,
        hasLowercase: false,
        hasNumber: false,
        hasSpecialChar: false,
        isCommonPassword: true,
        feedbackMessage:
            "Bu çok bilinen bir şifre! Tahmin edilmesi çok kolay. Lütfen harf, sayı ve özel karakterlerden oluşan benzersiz bir şifre dene.",
      );
    }

    final hasMinLength = password.length >= 8;
    final hasUppercase = RegExp(r'[A-ZÇĞİÖŞÜ]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-zçğıöşü]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialChar =
        RegExp(r'''[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>/?~`]''').hasMatch(password);

    double score = 0.0;
    if (hasMinLength) score += (password.length >= 12) ? 0.30 : 0.20;
    if (hasUppercase) score += 0.15;
    if (hasLowercase) score += 0.15;
    if (hasNumber) score += 0.20;
    if (hasSpecialChar) score += 0.20;

    score = score.clamp(0.0, 1.0);

    String label;
    Color color;

    if (score < 0.3) {
      label = "🔴 Başlangıç";
      color = const Color(0xFFEF4444);
    } else if (score < 0.5) {
      label = "🟠 Gelişiyor";
      color = const Color(0xFFF97316);
    } else if (score < 0.7) {
      label = "🟡 İyi";
      color = const Color(0xFFF59E0B);
    } else if (score < 0.9) {
      label = "🟢 Güçlü";
      color = const Color(0xFF10B981);
    } else {
      label = "🟢✨ Şifre Ustası!";
      color = const Color(0xFF059669);
    }

    String feedbackMessage;
    if (score >= 0.9) {
      feedbackMessage =
          "Harika! 🔐✨ Şifren uzun, harf, sayı ve özel karakter içeriyor. Artık bir Şifre Ustası'sın!";
    } else if (!hasNumber && !hasSpecialChar) {
      feedbackMessage =
          "Şifren güzel başladı! Sayı (0-9) ve özel karakter (! @ #) ekleyerek onu daha güçlü yapabilirsin. 💪";
    } else if (!hasSpecialChar) {
      feedbackMessage =
          "Çok iyi! Sayı ve harf eklemişsin. Şimdi ! ? # @ gibi özel bir karakter eklemeyi dene. 🔐";
    } else if (!hasMinLength) {
      feedbackMessage =
          "İyi gidiyorsun! Şifreni biraz daha uzatarak (en az 8 karakter) kalkanını güçlendir. 🛡️";
    } else if (!hasUppercase) {
      feedbackMessage = "Harika! Bir de BÜYÜK harf eklemeyi dene. 🔤";
    } else {
      feedbackMessage =
          "Çok güzel! Birkaç karakter daha ekleyerek Şifre Ustası seviyesine ulaşabilirsin. 🚀";
    }

    return PasswordAnalysisResult(
      score: score,
      label: label,
      color: color,
      hasMinLength: hasMinLength,
      hasUppercase: hasUppercase,
      hasLowercase: hasLowercase,
      hasNumber: hasNumber,
      hasSpecialChar: hasSpecialChar,
      isCommonPassword: false,
      feedbackMessage: feedbackMessage,
    );
  }
}

class SifreUstasiEkrani extends StatefulWidget {
  const SifreUstasiEkrani({super.key});

  @override
  State<SifreUstasiEkrani> createState() => _SifreUstasiEkraniState();
}

class _SifreUstasiEkraniState extends State<SifreUstasiEkrani> {
  final TextEditingController _passwordController = TextEditingController();
  late ConfettiController _confettiController;
  bool _showPassword = false;
  PasswordAnalysisResult _result = PasswordAnalysisResult.analyze('');

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    // Güvenlik Kuralı: Ekrandan çıkıldığında şifre belleği temizlenir,
    // hiçbir yere kaydedilmez.
    _passwordController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onPasswordChanged(String val) {
    setState(() {
      _result = PasswordAnalysisResult.analyze(val);
    });
  }

  void _clearPassword() {
    _passwordController.clear();
    setState(() {
      _result = PasswordAnalysisResult.analyze('');
    });
  }

  void _checkPasswordModal() {
    FocusScope.of(context).unfocus();
    final isMaster = _result.score >= 0.9;
    if (isMaster) {
      _confettiController.play();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomPadding = MediaQuery.paddingOf(context).bottom + 20;
        return Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPadding),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _result.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isMaster ? Icons.workspace_premium_rounded : Icons.lock_rounded,
                    color: _result.color,
                    size: 48,
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.bounceOut),
                const SizedBox(height: 16),
                Text(
                  isMaster ? "ŞİFRE USTASI OLDU! 🏆" : "ŞİFRE ANALİZİ 🔍",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _result.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _result.color,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _result.feedbackMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _result.color,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    isMaster ? "DEVAM ET 🚀" : "ŞİFREMİ GÜÇLENDİR ⚡",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom + 20;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "Şifre Ustası 🔐",
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
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
        body: Stack(
          children: [
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 10, 20, bottomInset),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderCard(),
                          const SizedBox(height: 20),
                          _buildGuideCard(),
                          const SizedBox(height: 24),
                          _buildInteractiveSection(),
                          const SizedBox(height: 24),
                          _buildSecurityFooterNote(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.yellow,
                  Colors.amber,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.key_rounded,
              color: Color(0xFF3B82F6),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Şifrelerini Güçlü Yap! 🔐",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "İyi bir şifreyi tahmin etmek zor, hatırlamak ise kolay olmalı.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
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

  Widget _buildGuideCard() {
    const steps = [
      ("🔢", "Sayı ekle", "123 gibi tahmin edilmesi kolay sayılardan kaçın."),
      ("🔤", "Büyük & küçük harf", "Farklı harf türlerini bir arada kullan."),
      ("🔐", "Özel karakter ekle", "! ? # @ gibi karakterler kullan."),
      ("📏", "Uzun tut", "Uzun şifreler genellikle daha güçlüdür."),
      (
        "🚫",
        "Kişisel bilgi kullanma",
        "Adın, doğum tarihin veya okulun gibi bilgileri kullanma."
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_moon_rounded, color: Color(0xFF3B82F6), size: 22),
              SizedBox(width: 8),
              Text(
                "Güçlü Şifre Nasıl Olur? 🔐",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.$1, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.$2,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.$3,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  Widget _buildInteractiveSection() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Şimdi Sen Dene! 🧠",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Eğitici bir örnek şifre yaz ve gücünü test et.",
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),

          // Password Input Field
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            onChanged: _onPasswordChanged,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              letterSpacing: 1.1,
            ),
            decoration: InputDecoration(
              hintText: "Örn: Kahraman!2026",
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
              prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFF6366F1)),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_passwordController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8)),
                      onPressed: _clearPassword,
                    ),
                  IconButton(
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: const Color(0xFF6366F1),
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                ],
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide:
                    const BorderSide(color: Color(0xFF6366F1), width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.shield_outlined, size: 14, color: Color(0xFF64748B)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Bu şifre yalnızca bu simülasyonda kontrol edilir ve hiçbir yere kaydedilmez.",
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Strength Progress Bar & Label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ŞİFRE GÜCÜ",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF64748B),
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                _result.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: _result.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _result.score,
              minHeight: 10,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(_result.color),
            ),
          ),

          const SizedBox(height: 20),

          // Criteria Checklist
          _buildCheckItem("En az 8 karakter", _result.hasMinLength),
          _buildCheckItem("Büyük harf (A-Z)", _result.hasUppercase),
          _buildCheckItem("Küçük harf (a-z)", _result.hasLowercase),
          _buildCheckItem("Sayı (0-9)", _result.hasNumber),
          _buildCheckItem("Özel karakter (! ? # @)", _result.hasSpecialChar),

          const SizedBox(height: 20),

          // Smart Feedback Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _result.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _result.color.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_rounded, color: _result.color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _result.feedbackMessage,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _passwordController.text.trim().isEmpty
                  ? null
                  : _checkPasswordModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.search_rounded, size: 20),
              label: const Text(
                "ŞİFREMİ KONTROL ET 🔍",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String title, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isMet ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isMet ? FontWeight.w800 : FontWeight.w500,
              color: isMet ? const Color(0xFF1E293B) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFooterNote() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFD97706), size: 20),
              SizedBox(width: 8),
              Text(
                "💡 Unutma!",
                style: TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "1. Gerçek hesaplarında adını, doğum tarihini veya kolay tahmin edilen bilgileri şifre yapma.\n2. Şifreni arkadaşların dahil kimseyle paylaşma!",
            style: TextStyle(
              color: Color(0xFF78350F),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
