import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminGuard extends StatelessWidget {
  final Widget child;

  const AdminGuard({super.key, required this.child});

  Future<bool> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
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

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pop();
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
