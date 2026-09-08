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
      // SEC-06: Sadece Custom Claims (admin) üzerinden yetki kontrolü yapılır.
      // Firestore'daki isAdmin alanı artık tek başına yetki vermez (Security Rules'a uygun).
      final idTokenResult = await user.getIdTokenResult(true);
      return idTokenResult.claims?['admin'] == true;
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
