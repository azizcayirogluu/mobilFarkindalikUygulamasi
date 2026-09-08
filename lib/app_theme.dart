import 'package:flutter/material.dart';

//Uygulama genelinde kullanılan renkler
class AppColors {
  // Soft-canlı Mavi tonları (Daha modern ve tatlı görünüm)
  static const Color anaMavi = Color(0xFF6C63FF);
  static const Color accentMavi = Color(0xFF38EF7D);
  static const Color yaziRengi = Color(0xFF2D3142);

  // Başarı, uyarı ve farklı modlar için canlı fakat yumuşak pastel tonlar
  static const Color basariYesili = Color(0xFF00A896);
  static const Color uyariTuruncusu = Color(0xFFFF8A3D);
  static const Color eglencePembesi = Color(0xFFFF6584);
  static const Color oyunSarisi = Color(0xFFFFC045);
  static const Color yumusakMor = Color(0xFF9E77ED);
  static const Color softPurple = Color(0xFFE8DEF8);
  static const Color softPink = Color(0xFFFFE5EC);

  // Arkaplan Rengi: Tamamen göz yormayan premium soft pastel zemin
  static const Color zemin = Color(0xFFF6F8FF);

  // Yumuşak geçişli modern gradyanlar
  static const Gradient anaGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF8178FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient altinGradient = LinearGradient(
    colors: [Color(0xFFFFC045), Color(0xFFFF8A3D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// UYGULAMA TEMA YAPILANDIRMASI
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.zemin,
    primaryColor: AppColors.anaMavi,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.anaMavi,
      primary: AppColors.anaMavi,
      secondary: AppColors.basariYesili,
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(fontWeight: FontWeight.w900, color: AppColors.yaziRengi),
      titleLarge: TextStyle(fontWeight: FontWeight.w900, color: AppColors.yaziRengi),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 5,
        shadowColor: AppColors.anaMavi.withOpacity(0.3),
      ),
    ),
  );
}