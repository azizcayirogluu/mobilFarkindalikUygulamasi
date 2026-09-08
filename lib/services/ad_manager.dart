import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdManager {
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;

  // ============================================================
  // ADMOB REWARDED AD UNIT
  // ============================================================

  // REWARDED TEST ID: ca-app-pub-3940256099942544/5224354917
  // GERÇEK ID: ca-app-pub-5213701530502851/5807572430
  final String rewardedAdUnitId = kDebugMode 
      ? 'ca-app-pub-3940256099942544/5224354917' 
      : 'ca-app-pub-5213701530502851/5807572430';

  // ============================================================
  // LOAD REWARDED AD
  // ============================================================

  void loadRewardedAd({
    required Function onAdLoaded,
  }) {
    if (_isAdLoading || _rewardedAd != null) {
      return;
    }

    _isAdLoading = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoading = false;

          onAdLoaded();
        },
        onAdFailedToLoad: (error) {
          _isAdLoading = false;

          debugPrint(
            'Reklam yüklenemedi: $error',
          );
        },
      ),
    );
  }

  // ============================================================
  // SHOW REWARDED AD
  // ============================================================

  void showRewardedAd({
    required Function onUserEarnedReward,
    required Function onAdClosed,
  }) {
    final ad = _rewardedAd;

    if (ad == null) {
      onAdClosed();
      return;
    }

    // ----------------------------------------------------------
    // GÜNCEL AUTH KULLANICISINI REKLAM GÖSTERİLMEDEN ÖNCE AL
    // ----------------------------------------------------------

    final currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      debugPrint(
        'AdMob ödülü: Kullanıcı oturumu bulunamadı.',
      );

      ad.dispose();
      _rewardedAd = null;

      onAdClosed();
      return;
    }

    // ----------------------------------------------------------
    // SERVER-SIDE VERIFICATION
    // ----------------------------------------------------------

    ad.setServerSideOptions(
      ServerSideVerificationOptions(
        userId: currentUser.uid,
      ),
    );

    // Artık reklam referansını temizliyoruz.
    // Aynı RewardedAd nesnesinin ikinci kez gösterilmesini
    // engelliyoruz.
    _rewardedAd = null;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();

            onAdClosed();
          },
          onAdFailedToShowFullScreenContent: (
              ad,
              error,
              ) {
            debugPrint(
              'Reklam gösterilemedi: $error',
            );

            ad.dispose();

            onAdClosed();
          },
        );

    // ----------------------------------------------------------
    // REWARD
    // ----------------------------------------------------------

    ad.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint(
          'AdMob ödül callback alındı: '
              '${reward.amount} ${reward.type}',
        );

        // Ödülü burada Firestore'a yazmıyoruz.
        //
        // Gerçek ödül:
        //
        // AdMob
        //   ↓
        // SSV
        //   ↓
        // Firebase Function
        //   ↓
        // signature doğrulama
        //   ↓
        // transaction kontrolü
        //   ↓
        // +5 Gemini hakkı
        //
        onUserEarnedReward();
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdLoading = false;
  }
}