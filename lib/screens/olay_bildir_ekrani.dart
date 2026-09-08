import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/services/report_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OlayBildirEkrani extends StatefulWidget {
  const OlayBildirEkrani({super.key});

  @override
  State<OlayBildirEkrani> createState() => _OlayBildirEkraniState();
}

class _OlayBildirEkraniState extends State<OlayBildirEkrani> {
  final TextEditingController _baslikController = TextEditingController();
  final TextEditingController _detayController = TextEditingController();
  final TextEditingController _konumController = TextEditingController();
  final ReportService _reportService = ReportService();
  bool _isLoading = false;

  @override
  void dispose() {
    _baslikController.dispose();
    _detayController.dispose();
    _konumController.dispose();
    super.dispose();
  }

  void _gonder() async {
    final String baslik = _baslikController.text.trim();
    final String detay = _detayController.text.trim();
    final String konum = _konumController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (baslik.isEmpty || detay.isEmpty) {
      _mesajGoster(
        "Lütfen olay başlığını ve detaylarını yaz canım! 😊",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _reportService.olayBildir(
      baslik: baslik,
      detay: detay,
      konum: konum.isEmpty ? "Belirtilmedi" : konum,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        _baslikController.clear();
        _detayController.clear();
        _konumController.clear();
        _basariDialoguGoster();
      } else {
        _mesajGoster("Bir hata oluştu, lütfen tekrar dene.", isError: true);
      }
    }
  }

  void _basariDialoguGoster() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: const Text(
          "Mesajın Alındı! 🕊️",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          "Anlattıkların güvende. Kahraman ekibimiz bunu inceleyecek. Yalnız olmadığını sakın unutma! 🛡️",
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("TAMAM"),
            ),
          ),
        ],
      ),
    );
  }

  void _mesajGoster(String mesaj, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mesaj,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError ? Colors.redAccent : AppColors.anaMavi,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.zemin,
      appBar: AppBar(
        title: const Text(
          "BAŞIMA BİR ŞEY GELDİ",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.edit_note_rounded,
              size: 80,
              color: AppColors.anaMavi,
            ).animate().shake(),
            const SizedBox(height: 10),
            const Text(
              "Neler yaşadığını anlatmak ister misin?\nBiz seni dinliyoruz.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blueGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 30),
            _buildInput(
              "Olayın Özeti (Örn: Okulda siber zorbalık)",
              _baslikController,
              Icons.title_rounded,
            ),
            const SizedBox(height: 20),
            _buildInput(
              "Neler Oldu? (Tüm detayları yazabilirsin)",
              _detayController,
              Icons.description_rounded,
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            _buildInput(
              "Nerede Oldu? (Okul, Instagram, Park vb.)",
              _konumController,
              Icons.location_on_rounded,
            ),
            const SizedBox(height: 40),
            _isLoading
                ? const CircularProgressIndicator()
                : _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    String hint,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.anaMavi),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.anaMavi, width: 2),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppColors.anaGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.anaMavi.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _gonder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: const Text(
          "MESAJI GÖNDER 🚀",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
