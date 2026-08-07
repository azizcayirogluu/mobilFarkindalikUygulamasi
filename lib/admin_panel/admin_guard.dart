import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class AdminGuard extends StatelessWidget {
  final Widget child;

  const AdminGuard({super.key, required this.child});

  Future<bool> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      // 1. Önce Token'a bak (Hızlı kontrol)
      final idTokenResult = await user.getIdTokenResult(true);
      if (idTokenResult.claims?['admin'] == true || idTokenResult.claims?['isAdmin'] == true) {
        return true;
      }

      // 2. Token'da yoksa senin yaptığın Firestore ayarına bak (Kesin çözüm)
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return doc.data()?['isAdmin'] == true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAdminStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData && snapshot.data == true) {
          return child;
        }

        // Yetkisiz erişim durumunda ana sayfaya yönlendir ve uyarı ver
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pop(); // Admin sayfasına girişi iptal et
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Erişim Reddedildi: Yönetici yetkiniz bulunmuyor."),
              backgroundColor: Colors.red,
            ),
          );
        });

        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }
}
