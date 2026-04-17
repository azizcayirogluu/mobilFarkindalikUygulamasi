import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/ana_navigation_ekrani.dart';
import 'package:zorbalik_uygulamasi/screens/giris_yapma_ekrani.dart';

class KayitEkrani extends StatefulWidget {
  const KayitEkrani({super.key});

  @override
  State<KayitEkrani> createState() => _KayitEkraniState();
}

class _KayitEkraniState extends State<KayitEkrani> {

  // Kullanıcı girişlerini kontrol etmek için kullanılan denetleyiciler
  String seciliGrup = "";
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;

  // Firebase Auth ve Firestore işlemlerini başlatan ana fonksiyon
  void _kayitSureciniBaslat() async {
    final String kullaniciAdi = _usernameController.text.trim().toLowerCase();
    final String pin = _pinController.text.trim();

    // Giriş Validasyonu: Bilgilerin eksiksiz ve kriterlere uygun olduğunu kontrol eder
    if (kullaniciAdi.isEmpty) {
      _mesajGoster("Lütfen bir kullanıcı adı seç! 😊", isError: true);
      return;
    }
    if (pin.length < 6) {
      _mesajGoster("Güvenliğin için PIN kodu 6 haneli olmalı! 🔐", isError: true);
      return;
    }
    if (seciliGrup.isEmpty) {
      _mesajGoster("Lütfen yaş grubunu seç! 🎂", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Uygulamaya özel sahte bir e-posta yapısıyla kimlik doğrulama oluşturulur
      final String fakeEmail = "$kullaniciAdi@zorbalik.app";

      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: fakeEmail,
        password: pin,
      );

      final String uid = userCredential.user!.uid;

      // Firestore Batch: Birden fazla dökümanı tek seferde (atomik) kaydetmeyi sağlar
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // 'users' koleksiyonuna temel profil bilgilerini kaydeder
      batch.set(FirebaseFirestore.instance.collection('users').doc(uid), {
        'uid': uid,
        'kullaniciAdi': kullaniciAdi,
        'yasGrubu': seciliGrup,
        'isAdmin': false,
        'isOnline': true,
        'sonGorulme': FieldValue.serverTimestamp(),
        'kayitTarihi': FieldValue.serverTimestamp(),
      });

      // 'usersProgress' koleksiyonuna oyunlaştırma ve ilerleme verilerini kaydeder
      batch.set(FirebaseFirestore.instance.collection('usersProgress').doc(uid), {
        'uid': uid,
        'kullaniciAdi': kullaniciAdi,
        'tamamlanan_bolumler': [],
        'okunan_hikayeler': [],
        'rozetler': [],
        'toplam_puan': 0,
        'sonGuncelleme': FieldValue.serverTimestamp(),
      });

      await batch.commit(); // Tüm verileri aynı anda sunucuya gönderir
      await userCredential.user!.updateDisplayName(kullaniciAdi);

      if (!mounted) return;
      _mesajGoster("Hoş geldin siber kahraman $kullaniciAdi! 🛡️");

      // Kayıt başarılıysa geri dönülemez şekilde ana navigasyon ekranına yönlendirir
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AnaNavigation()), (route) => false);
    } on FirebaseAuthException catch (e) {
      // Firebase özel hata mesajlarını kullanıcıya dostça iletir
      if (e.code == 'email-already-in-use') {
        _mesajGoster("Bu kullanıcı adı zaten alınmış! Başka bir tane dene. ✨", isError: true);
      } else {
        _mesajGoster("Hata: ${e.message}", isError: true);
      }
    } catch (e) {
      _mesajGoster("Bir hata oluştu, internetini kontrol eder misin? 🌐", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // SnackBar kullanarak kullanıcıya geri bildirim veren fonksiyon
  void _mesajGoster(String mesaj, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mesaj, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: isError ? Colors.redAccent : AppColors.accentMavi,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.zemin,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Navigator.pop(context))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              const Text("KAHRAMAN KAYDI 🚀", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.yaziRengi)),
              const SizedBox(height: 20),
              _buildWelcomeCard(),
              const SizedBox(height: 20),
              _buildFormKarti(),
              const SizedBox(height: 20),
              _buildLoginLink(),
            ],
          ),
        ),
      ),
    );
  }

  // Karşılama kartı
  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/elEleKarsilama2.png',
            height: 140,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.handshake_rounded, size: 80, color: AppColors.anaMavi),
          ),
          const SizedBox(height: 10),
          const Text(
            "Siber dünyada el ele güvendeyiz!",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Kullanıcıdan bilgi alan ana kayıt formu
  Widget _buildFormKarti() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(35), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)]),
      child: Column(
        children: [
          _buildInput("Kullanıcı Adı", "Örn: ali_kahraman", Icons.face_rounded, _usernameController, isPin: false),
          const SizedBox(height: 20),
          _buildInput("6 Haneli PIN", "• • • • • •", Icons.lock_outline_rounded, _pinController, isPin: true),
          const SizedBox(height: 25),
          const Align(alignment: Alignment.centerLeft, child: Text("  Yaş Grubu", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.blueGrey, fontSize: 13))),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildYasKarti("6 - 12 Yaş", "6-12"),
              const SizedBox(width: 15),
              _buildYasKarti("13 - 18 Yaş", "13-18"),
            ],
          ),
          const SizedBox(height: 35),
          _isLoading ? const CircularProgressIndicator() : _buildBaslaButonu(),
        ],
      ),
    );
  }

  // Özelleştirilmiş giriş alanı
  Widget _buildInput(String title, String hint, IconData icon, TextEditingController controller, {required bool isPin}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("  $title", style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.blueGrey, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPin,
          keyboardType: isPin ? TextInputType.number : TextInputType.text,
          maxLength: isPin ? 6 : 20,
          decoration: InputDecoration(
            counterText: "",
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.accentMavi),
            filled: true,
            fillColor: AppColors.zemin,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.accentMavi, width: 2)),
          ),
        ),
      ],
    );
  }

  // yaş grubu seçici widget
  Widget _buildYasKarti(String range, String group) {
    bool selected = seciliGrup == group;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => seciliGrup = group),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentMavi.withOpacity(0.1) : AppColors.zemin,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.accentMavi : Colors.transparent, width: 2),
          ),
          child: Center(child: Text(range, style: TextStyle(fontWeight: FontWeight.w900, color: selected ? AppColors.accentMavi : AppColors.yaziRengi, fontSize: 12))),
        ),
      ),
    );
  }

  // Kayıt işlemini onaylayan buton
  Widget _buildBaslaButonu() {
    return Container(
      width: double.infinity, height: 60,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: AppColors.anaGradient),
      child: ElevatedButton(
        onPressed: _kayitSureciniBaslat,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        child: const Text("KAYIT OL VE BAŞLA! 🚀", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
    );
  }

  // Hesabı olan kullanıcıları giriş ekranına yönlendiren metin
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Zaten bir hesabın var mı?", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600)),
        TextButton(
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GirisEkrani())),
          child: const Text("Giriş Yap", style: TextStyle(color: AppColors.anaMavi, fontWeight: FontWeight.w900, fontSize: 15)),
        ),
      ],
    );
  }
}