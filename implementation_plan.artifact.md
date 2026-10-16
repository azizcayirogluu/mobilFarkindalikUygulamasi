# UX & Security Improvements - Implementation Plan

This document outlines the research findings and planned changes for UX and COPPA security improvements in Kahraman Dostum.

---

## 1. Privacy Policy Readability & Structure (`gizlilik_politikasi_ekrani.dart`)
- **Objective**: Simplify technical jargon into child-friendly, structured Turkish without altering any legal scope, terms, or obligations.
- **Planned Changes**:
  - Reorganize info cards under clear headings:
    - *Hangi Bilgileri Topluyoruz? 🎭* (Kahraman adın, yaş grubun, seçtiğin avatar, görev puanların)
    - *Bu Bilgileri Neden Kullanıyoruz? 🎯* (İlerlemeni kaydetmek, yaşına uygun içerik sunmak, güvenli sohbet sağlamak)
    - *Bilgilerini Kimlerle Paylaşıyoruz? 🔒* (Reklamcılarla veya 3. şahıslarla satılmaz/paylaşılmaz, sadece güvenli Firebase sunucularında tutulur)
    - *Çocuk Ve Aile Güvenliği ✨* (6-12 yaş ebeveyn onay süreci, kişisel bilgi paylaşmama kuralı)
    - *Hakların Nelerdir? 🗑️* (Profil ayarlarından istediğin an hesap silme ve iletişim bilgileri)

---

## 2. Energy System Clarity (`siber_asistan_ekrani.dart`)
- **Objective**: Explain the energy mechanics clearly to child users without altering the existing functionality or adding intrusive dialogs.
- **Planned Changes**:
  - Add an explanatory subtitle / tooltip in `_buildStatsBar()`: *"Her mesaj 1 Enerji tüketir. Enerjin bittiğinde video izleyerek +5 Enerji kazanabilirsin! ⚡"*
  - Ensure the reward confirmation SnackBar prominently displays `"+5 Enerji kazandın! ⚡"` upon successful ad view.

---

## 3. AdMob Child Ads / COPPA Configuration Audit (`main.dart`, `ad_manager.dart`)
- **Objective**: Ensure 100% compliance with Google Play Families & COPPA policy for child-directed apps and resolve deprecation warnings.
- **Audit Findings**:
  - App currently configures `MaxAdContentRating.g` (General Audience only).
  - Deprecated `TagForChildDirectedTreatment.yes` in `main.dart` will be updated to `AgeRestrictedTreatment.yes` and `TagForChildDirectedTreatment.yes` to conform to `google_mobile_ads` v9.1+ API standards.
  - Global `RequestConfiguration` applies child-directed and G-rated content policies to all AdRequests.

---

## 4. Points System Verification (`analytics_service.dart`, `functions/index.js`)
- **Audit Findings**:
  - Server-side verification via `completeTask` Cloud Function guarantees anti-cheat protection.
  - Points increment atomically (`FieldValue.increment(pointsAwarded)`) in Firestore `usersProgress/$uid`.
  - Stream listeners in `AnaSayfa` and `ProfilEkrani` automatically reflect updated points in real-time.
  - **Verdict**: Points system is functioning 100% correctly and securely. No code changes required.

---

## Proposed File Changes

### [gizlilik_politikasi_ekrani.dart](file:///C:/zorbalikApp-firebase/lib/screens/gizlilik_politikasi_ekrani.dart)
- Restructure privacy text into clear child-friendly bullet points under structured headings.

### [siber_asistan_ekrani.dart](file:///C:/zorbalikApp-firebase/lib/screens/siber_asistan_ekrani.dart)
- Add energy system explanation text under stats bar.

### [main.dart](file:///C:/zorbalikApp-firebase/lib/main.dart)
- Update AdMob `RequestConfiguration` to resolve deprecation warnings (`AgeRestrictedTreatment.yes`, `MaxAdContentRating.g`).

---

## Verification Plan

### Automated Tests
- `flutter analyze` — Verify zero errors.
- `flutter pub get` — Verify dependency resolution.
