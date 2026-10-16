import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/gizlilik_politikasi_ekrani.dart';
import 'package:zorbalik_uygulamasi/utils/app_logger.dart';

class ParentConsentPendingEkrani extends StatefulWidget {
  final String uid;
  final String parentEmail;

  const ParentConsentPendingEkrani({
    super.key,
    required this.uid,
    required this.parentEmail,
  });

  @override
  State<ParentConsentPendingEkrani> createState() => _ParentConsentPendingEkraniState();
}

class _ParentConsentPendingEkraniState extends State<ParentConsentPendingEkrani> {
  bool _resending = false;
  late String _currentEmail;

  @override
  void initState() {
    super.initState();
    _currentEmail = widget.parentEmail;
  }

  Future<void> _resendEmail() async {
    if (_resending) return;
    setState(() => _resending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.getIdToken();
      }

      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable('requestParentConsent');
      await callable.call({'parentEmail': _currentEmail});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Onay e-postası tekrar gönderildi! ✉️ Lütfen spamlara da bakmayı unutmayın."),
            backgroundColor: AppColors.basariYesili,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error("requestParentConsent hatası", e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? "E-posta gönderilemedi. Lütfen biraz bekleyip tekrar deneyin."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      AppLogger.error("Onay e-postası gönderme hatası", e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bir sorun oluştu. Lütfen bağlantınızı kontrol ediniz."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _showChangeEmailDialog() async {
    final emailController = TextEditingController(text: _currentEmail);
    bool loading = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: const Text('Ebeveyn E-Postasını Değiştir', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              // Klavye açıldığında taşmayı önlemek için SingleChildScrollView eklendi
              content: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Onay e-postası yeni gireceğin adrese gönderilecektir.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Yeni Ebeveyn E-Postası",
                        prefixIcon: const Icon(Icons.mail_rounded, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('İptal', style: TextStyle(color: Color(0xFF64748B))),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.anaMavi),
                  onPressed: loading
                      ? null
                      : () async {
                    final newEmail = emailController.text.trim().toLowerCase();
                    if (newEmail.isEmpty || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(newEmail)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Geçerli bir e-posta adresi giriniz.')),
                      );
                      return;
                    }

                    setDialogState(() => loading = true);

                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) await user.getIdToken();

                      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable('updateParentEmail');
                      await callable.call({'newParentEmail': newEmail});

                      if (mounted) {
                        setState(() => _currentEmail = newEmail);
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ebeveyn e-postası güncellendi ve yeni onay linki gönderildi! ✉️'),
                            backgroundColor: AppColors.basariYesili,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      AppLogger.error("Ebeveyn e-posta güncelleme hatası", e);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('E-posta güncellenirken bir hata oluştu.'),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } finally {
                      setDialogState(() => loading = false);
                    }
                  },
                  // Buton metni sığmazsa taşmasını engellemek için FittedBox
                  child: loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const FittedBox(fit: BoxFit.scaleDown, child: Text('Güncelle ve Gönder')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    // Çıkış sonrası ekranı AuthGate belirler (oturum yok -> Karşılama ekranı).
    // Yeni bir route ile yığını sıfırlamak AuthGate'i kaldırıyordu.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final pConsent = data?['parentConsent'] as Map<String, dynamic>?;
          final updatedEmail = pConsent?['parentEmail'] ?? _currentEmail;
          if (updatedEmail != _currentEmail) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _currentEmail = updatedEmail);
            });
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            // Ana içerik küçük ekranlarda kaydırılabilir, büyük ekranlarda ise ortalanmış kalması için
            // CustomScrollView ve SliverFillRemaining kullanıldı. Bu, Spacer() kullanımını bozmadan taşmayı önler.
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),

                        // Icon Banner
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppColors.anaMavi.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mark_email_unread_rounded,
                            size: 48,
                            color: AppColors.anaMavi,
                          ),
                        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                        const SizedBox(height: 24),

                        const Text(
                          "Ebeveyn Onayı Bekleniyor 👨‍👩‍👧",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          "Kahraman macerana başlamak için ebeveyninin gönderdiğimiz e-postadaki onay düğmesine basması gerekiyor.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Email Container
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x05000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.mail_outline_rounded, color: AppColors.anaMavi, size: 20),
                              const SizedBox(width: 12),
                              // Buradaki Expanded ve TextOverflow.ellipsis halihazırda duyarlıydı, korundu.
                              Expanded(
                                child: Text(
                                  _currentEmail.isEmpty ? "Ebeveyn e-posta adresini ekleyin" : _currentEmail,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                tooltip: "E-postayı Değiştir",
                                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                                onPressed: _showChangeEmailDialog,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Resend Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.anaMavi,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            onPressed: (_resending || _currentEmail.isEmpty) ? null : _resendEmail,
                            icon: _resending
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.send_rounded, size: 18),
                            // Dar ekranlarda uzun buton metninin sağdan soldan kesilmesini önlemek için FittedBox eklendi
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _resending
                                    ? "Gönderiliyor..."
                                    : (_currentEmail.isEmpty ? "ÖNCE E-POSTA ADRESİ EKLE" : "E-POSTAYI TEKRAR GÖNDER ✉️"),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const GizlilikPolitikasiEkrani()),
                            );
                          },
                          // Dar ekranlar için FittedBox
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Gizlilik Politikasını İncele",
                              style: TextStyle(color: AppColors.anaMavi, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Sign out button
                        TextButton.icon(
                          onPressed: _signOut,
                          icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                          // Dar ekranlar için FittedBox
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Çıkış Yap / Başka Hesapla Giriş Yap",
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
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
}