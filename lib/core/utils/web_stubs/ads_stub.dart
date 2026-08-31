import 'package:flutter/material.dart';

class AdSize {
  final int width;
  final int height;
  static const AdSize banner = AdSize(width: 320, height: 50);
  static const AdSize largeBanner = AdSize(width: 320, height: 100);
  static const AdSize mediumRectangle = AdSize(width: 300, height: 250);
  const AdSize({this.width = 0, this.height = 0});
  static Future<AdSize?> getCurrentOrientationAnchoredAdaptiveBannerAdSize(int width) async => banner;
}

class AdRequest {
  const AdRequest();
}

class BannerAdListener {
  final Function(dynamic)? onAdLoaded;
  final Function(dynamic, dynamic)? onAdFailedToLoad;
  const BannerAdListener({this.onAdLoaded, this.onAdFailedToLoad});
}

class BannerAd {
  final String adUnitId;
  final AdSize size;
  final AdRequest request;
  final BannerAdListener listener;
  BannerAd({required this.adUnitId, required this.size, required this.request, required this.listener});
  Future<void> load() async {
    listener.onAdFailedToLoad?.call(this, 'Web unsupported');
  }
  void dispose() {}
}

class AdWidget extends StatelessWidget {
  final dynamic ad;
  const AdWidget({Key? key, required this.ad}) : super(key: key);
  @override Widget build(BuildContext context) => const SizedBox.shrink();
}

class InterstitialAd {
  static Future<void> load({
    required String adUnitId,
    required AdRequest request,
    required InterstitialAdLoadCallback adLoadCallback,
  }) async {
    adLoadCallback.onAdFailedToLoad(const LoadAdError(0, 'web', 'web unsupported', null));
  }
  dynamic fullScreenContentCallback;
  void show() {}
  void dispose() {}
}

class RewardedAd {
  static Future<void> load({
    required String adUnitId,
    required AdRequest request,
    required RewardedAdLoadCallback rewardedAdLoadCallback,
  }) async {
    rewardedAdLoadCallback.onAdFailedToLoad(const LoadAdError(0, 'web', 'web unsupported', null));
  }
  dynamic fullScreenContentCallback;
  void show({required Function(AdWithoutView, RewardItem) onUserEarnedReward}) {}
  void dispose() {}
}

class AppOpenAd {
  static Future<void> load({
    required String adUnitId,
    required AdRequest request,
    required AppOpenAdLoadCallback adLoadCallback,
  }) async {
    adLoadCallback.onAdFailedToLoad(const LoadAdError(0, 'web', 'web unsupported', null));
  }
  dynamic fullScreenContentCallback;
  void show() {}
  void dispose() {}
}

class MobileAds {
  static MobileAds instance = MobileAds();
  Future<void> initialize() async {}
}

class InterstitialAdLoadCallback {
  final Function(InterstitialAd) onAdLoaded;
  final Function(LoadAdError) onAdFailedToLoad;
  const InterstitialAdLoadCallback({required this.onAdLoaded, required this.onAdFailedToLoad});
}

class RewardedAdLoadCallback {
  final Function(RewardedAd) onAdLoaded;
  final Function(LoadAdError) onAdFailedToLoad;
  const RewardedAdLoadCallback({required this.onAdLoaded, required this.onAdFailedToLoad});
}

class AppOpenAdLoadCallback {
  final Function(AppOpenAd) onAdLoaded;
  final Function(LoadAdError) onAdFailedToLoad;
  const AppOpenAdLoadCallback({required this.onAdLoaded, required this.onAdFailedToLoad});
}

class LoadAdError {
  final int code;
  final String domain;
  final String message;
  final dynamic responseInfo;
  const LoadAdError(this.code, this.domain, this.message, this.responseInfo);
  @override
  String toString() => '$domain: $message';
}

class AdWithoutView {}
class RewardItem {
  final num amount = 0;
  final String type = '';
}

class FullScreenContentCallback {
  final Function(dynamic)? onAdShowedFullScreenContent;
  final Function(dynamic)? onAdDismissedFullScreenContent;
  final Function(dynamic, dynamic)? onAdFailedToShowFullScreenContent;
  const FullScreenContentCallback({
    this.onAdShowedFullScreenContent,
    this.onAdDismissedFullScreenContent,
    this.onAdFailedToShowFullScreenContent,
  });
}
