class CredentialValidator {
  static const Set<String> predictablePins = {
    '123456',
    '000000',
    '111111',
    '123123',
    '654321',
    'password',
    'qwerty',
  };

  static bool isPredictable(String input) {
    return predictablePins.contains(input.trim().toLowerCase());
  }

  static String? validateRegistrationCredential({
    required String rawInput,
    required String ageGroup,
  }) {
    final input = rawInput.trim();
    if (input.isEmpty) {
      return ageGroup == '6-12' ? 'Lütfen 6 haneli PIN yaz.' : 'Lütfen bir şifre yaz.';
    }

    if (ageGroup == '6-12') {
      if (!RegExp(r'^\d{6}$').hasMatch(input)) {
        return 'PIN tam olarak 6 rakamdan oluşmalı 🔐';
      }
      if (isPredictable(input)) {
        return 'Bu PIN çok kolay tahmin edilebilir! Daha güvenli bir PIN seç. 🔐';
      }
    } else {
      if (input.length < 6) {
        return 'Şifren en az 6 karakterden oluşmalı 🔐';
      }
      if (isPredictable(input)) {
        return 'Bu şifre çok kolay tahmin edilebilir! Daha güvenli bir şifre seç. 🔐';
      }
    }

    return null;
  }

  static String? validatePasswordChange({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
    required String ageGroup,
  }) {
    if (oldPassword.trim().isEmpty) {
      return 'Mevcut şifrenizi veya PIN kodunuzu girin.';
    }
    if (newPassword.trim().isEmpty) {
      return 'Yeni şifrenizi veya PIN kodunuzu girin.';
    }
    if (newPassword.trim() != confirmPassword.trim()) {
      return 'Yeni şifreler birbirleriyle eşleşmiyor!';
    }
    if (oldPassword.trim() == newPassword.trim()) {
      return 'Yeni şifreniz mevcut şifrenizle aynı olamaz.';
    }

    return validateRegistrationCredential(
      rawInput: newPassword,
      ageGroup: ageGroup,
    );
  }
}
