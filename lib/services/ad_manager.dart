import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class AdManager {
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;

  // REKLAM BİRİMİ ID'LERİ
  final String rewardedAdUnitId = kDebugMode 
    ? 'ca-app-pub-3940256099942544/5224354917' // Android Test ID (Güvenli Test)
    : 'ca-app-pub-5213701530502851/5807572430'; // Senin Gerçek ID'n

  void loadRewardedAd({required Function onAdLoaded}) {
    if (_isAdLoading) return;
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
          debugPrint('Reklam yüklenemedi: $error');
        },
      ),
    );
  }

  void showRewardedAd({
    required Function onUserEarnedReward,
    required Function onAdClosed,
  }) {
    if (_rewardedAd == null) {
      onAdClosed(); // Reklam hazır değilse direkt kapat
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        onAdClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        onAdClosed();
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
      onUserEarnedReward();
    });
  }
}
