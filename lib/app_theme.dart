import 'package:flutter/material.dart';


class AppColors {
  static const Color anaMavi = Color(0xFF4A90E2); 
  static const Color accentMavi = Color(0xFF00D2FF);
  static const Color yaziRengi = Color(0xFF2C3E50);
  
  static const Color basariYesili = Color(0xFF7ED321);
  static const Color uyariTuruncusu = Color(0xFFF5A623);
  static const Color eglencePembesi = Color(0xFFFF4081);
  static const Color oyunSarisi = Color(0xFFFFD700);
  static const Color yumusakMor = Color(0xFF9B59B6);
  static const Color softPurple = Color(0xFFE1BEE7);
  static const Color softPink = Color(0xFFFFD1DC);
  
  static const Color zemin = Color(0xFFF0F7FF); 

  static const Gradient anaGradient = LinearGradient(
    colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static const Gradient altinGradient = LinearGradient(
    colors: [Color(0xFFFAD961), Color(0xFFF76B1C)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
}

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
        shadowColor: AppColors.anaMavi.withOpacity(0.4),
      ),
    ),
  );
}
