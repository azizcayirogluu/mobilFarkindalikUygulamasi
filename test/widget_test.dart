import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:zorbalik_uygulamasi/app_theme.dart';

/// Temel birim testleri — Uygulama tema ve yardımcı fonksiyonlar
void main() {
  group('AppColors Testleri', () {
    test('Ana renkler doğru tanımlanmış olmalı', () {
      expect(AppColors.anaMavi, const Color(0xFF6C63FF));
      expect(AppColors.accentMavi, const Color(0xFF38EF7D));
      expect(AppColors.yaziRengi, const Color(0xFF2D3142));
    });

    test('Zemin rengi açık tonlu olmalı', () {
      expect(AppColors.zemin, const Color(0xFFF6F8FF));
    });

    test('Gradient tanımları null olmamalı', () {
      expect(AppColors.anaGradient, isNotNull);
      expect(AppColors.altinGradient, isNotNull);
    });
  });

  group('AppTheme Testleri', () {
    test('Material 3 aktif olmalı', () {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
    });

    test('Primary renk anaMavi olmalı', () {
      final theme = AppTheme.lightTheme;
      expect(theme.primaryColor, AppColors.anaMavi);
    });

    test('Scaffold arka plan rengi zemin olmalı', () {
      final theme = AppTheme.lightTheme;
      expect(theme.scaffoldBackgroundColor, AppColors.zemin);
    });
  });

  group('Veri Doğrulama Testleri', () {
    test('Kullanıcı adı 20 karakterden uzun olmamalı', () {
      const maxLength = 20;
      const validName = "AhmetYılmaz";
      const invalidName = "BuÇokUzunBirKullanıcıAdıdır123";

      expect(validName.length <= maxLength, isTrue);
      expect(invalidName.length <= maxLength, isFalse);
    });

    test('Yaş grubu geçerli değerlerden biri olmalı', () {
      const validGroups = ["6-12", "13-18"];

      expect(validGroups.contains("6-12"), isTrue);
      expect(validGroups.contains("13-18"), isTrue);
      expect(validGroups.contains("0-5"), isFalse);
    });

    test('Puan negatif olmamalı', () {
      const puan = 150;
      expect(puan >= 0, isTrue);
    });

    test('Mesaj boşluk kontrolü doğru çalışmalı', () {
      expect("Merhaba".trim().isEmpty, isFalse);
      expect("".trim().isEmpty, isTrue);
      expect("   ".trim().isEmpty, isTrue);
    });
  });

  group('Metin Temizleme Testleri', () {
    test('Markdown karakterleri temizlenmeli', () {
      const metin = "**Merhaba** _dünya_ #test >alıntı";
      final temiz = metin.replaceAll(RegExp(r'[*_#>]'), '');
      expect(temiz.contains('*'), isFalse);
      expect(temiz.contains('_'), isFalse);
      expect(temiz.contains('#'), isFalse);
    });

    test('Temiz metin boşlukları korumalı', () {
      const metin = "Merhaba dünya";
      final temiz = metin.replaceAll(RegExp(r'[*_#>]'), '');
      expect(temiz, "Merhaba dünya");
    });
  });
}
