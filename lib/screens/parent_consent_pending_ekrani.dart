import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';
import 'package:zorbalik_uygulamasi/screens/gizlilik_politikasi_ekrani.dart';
import 'package:zorbalik_uygulamasi/services/storage_service.dart';
import 'package:zorbalik_uygulamasi/utils/app_logger.dart';

class ParentConsentPendingEkrani extends StatefulWidget {
  final String? uid;
  final String? requestId;
  final String parentEmail;

  const ParentConsentPendingEkrani({
    super.key,
    this.uid,
    this.requestId,
    required this.parentEmail,
  });

  @override
  State<ParentConsentPendingEkrani> createState() => _ParentConsentPendingEkraniState();
}

class _ParentConsentPendingEkraniState extends State<ParentConsentPendingEkrani> {
  bool _resending = false;
  bool _checkingStatus = false;
  late String _currentEmail;
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    _currentEmail = widget.parentEmail;
    if (widget.requestId != null && widget.requestId!.isNotEmpty) {
      _startStatusPolling();
    }
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _startStatusPolling() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        _checkPreAuthConsentStatus(silent: true);
      }
    });
  }

  Future<void> _checkPreAuthConsentStatus({bool silent = false}) async {
    final reqId = widget.requestId;
    if (reqId == null || reqId.isEmpty || _checkingStatus) return;

    if (!silent) setState(() => _checkingStatus = true);

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('checkPendingRegistrationStatus');
      final response = await callable.call({'requestId': reqId});
      final data = response.data as Map?;
      final status = (data?['status'] ?? '').toString();

      if (status == 'approved') {
        _statusCheckTimer?.cancel();
        await _finalizePreAuthRegistration(reqId);
      } else if (status == 'expired') {
        _statusCheckTimer?.cancel();
        await StorageService().clearPendingRequestId();
        if (mounted && !silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Onay süresi doldu. Lütfen yeniden kayıt olun."),
              backgroundColor: Colors.orangeAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ebeveyniniz henüz onay vermedi. Onaylandığında otomatik giriş yapacaksınız. ✉️"),
            backgroundColor: AppColors.anaMavi,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      AppLogger.error("checkPendingRegistrationStatus error", e);
    } finally {
      if (mounted && !silent) setState(() => _checkingStatus = false);
    }
  }

  Future<void> _finalizePreAuthRegistration(String reqId) async {
    if (_checkingStatus) return;
    setState(() => _checkingStatus = true);

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('finalize612Registration');
      final response = await callable.call({'requestId': reqId});
      final data = response.data as Map?;
      final email = (data?['canonicalEmail'] ?? '').toString();
      final pin = (data?['pin'] ?? '').toString();

      if (email.isNotEmpty && pin.isNotEmpty) {
        await StorageService().clearPendingRequestId();
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: pin,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Ebeveyniniz onay verdi! Kahraman dünyasına hoş geldin! 🎉"),
              backgroundColor: AppColors.basariYesili,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error("finalize612Registration error", e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? "Kayıt tamamlanamadı."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      AppLogger.error("finalize612Registration beklenmeyen hata", e);
    } finally {
      if (mounted) setState(() => _checkingStatus = false);
    }
  }

  Future<void> _resendEmail() async {
    if (_resending) return;
    setState(() => _resending = true);

    try {
      if (widget.requestId != null && widget.requestId!.isNotEmpty) {
        final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('resend612ParentConsent');
        await callable.call({'requestId': widget.requestId});
      } else {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) await user.getIdToken();

        final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('requestParentConsent');
        await callable.call({'parentEmail': _currentEmail});
      }

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
                      if (widget.requestId != null && widget.requestId!.isNotEmpty) {
                        final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
                            .httpsCallable('update612ParentEmail');
                        await callable.call({
                          'requestId': widget.requestId,
                          'newParentEmail': newEmail,
                        });
                      } else {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) await user.getIdToken();

                        final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
                            .httpsCallable('updateParentEmail');
                        await callable.call({'newParentEmail': newEmail});
                      }

                      await StorageService().savePendingParentEmail(newEmail);

                      if (mounted) {
                        setState(() => _currentEmail = newEmail);
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ebeveyn e-postası güncellendi ve yeni onay linki gönderildi! ✉️'),
                              backgroundColor: AppColors.basariYesili,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      AppLogger.error("Ebeveyn e-posta güncelleme hatası", e);
                      if (mounted && context.mounted) {
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

  Future<void> _cancelAndClearPending() async {
    _statusCheckTimer?.cancel();
    await StorageService().clearPendingRequestId();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: (uid != null && uid.isNotEmpty)
          ? FirebaseFirestore.instance.collection('users').doc(uid).snapshots()
          : const Stream.empty(),
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

                        const SizedBox(height: 24),

                        // Check status button (manual trigger)
                        if (widget.requestId != null && widget.requestId!.isNotEmpty) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.anaMavi,
                                side: const BorderSide(color: AppColors.anaMavi, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: _checkingStatus ? null : () => _checkPreAuthConsentStatus(silent: false),
                              icon: _checkingStatus
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.refresh_rounded, size: 20),
                              label: const Text("ONAYI KONTROL ET", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

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
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Gizlilik Politikasını İncele",
                              style: TextStyle(color: AppColors.anaMavi, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Sign out / Cancel button
                        TextButton.icon(
                          onPressed: _cancelAndClearPending,
                          icon: const Icon(Icons.close_rounded, size: 18, color: Colors.redAccent),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "İptal Et / Başka Hesapla Giriş Yap",
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
