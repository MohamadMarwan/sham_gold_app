import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isEnabled = false;
  String? _bannerId;
  String? _interstitialId;
  String? _rewardedId;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  // Reward State
  DateTime? _rewardExpiration;

  bool get isEnabled => _isEnabled && !isRewardActive;
  String? get bannerId => _bannerId;
  String? get interstitialId => _interstitialId;
  String? get rewardedId => _rewardedId;

  bool get isRewardActive {
    if (_rewardExpiration == null) return false;
    return DateTime.now().isBefore(_rewardExpiration!);
  }

  String get remainingRewardTime {
    if (!isRewardActive) return "";
    final diff = _rewardExpiration!.difference(DateTime.now());
    final minutes = diff.inMinutes;
    final seconds = diff.inSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  Future<void> initialize() async {
    if (kIsWeb) return;
    await _loadRewardState();
    try {
      await MobileAds.instance.initialize();
      debugPrint('✅ Google Mobile Ads Initialized');
    } catch (e) {
      debugPrint('❌ AdMob Init Error: $e');
    }
  }

  Future<void> _loadRewardState() async {
    final prefs = await SharedPreferences.getInstance();
    final expireStr = prefs.getString('ad_reward_expiration');
    if (expireStr != null) {
      _rewardExpiration = DateTime.tryParse(expireStr);
    }
  }

  Future<void> activateReward(int minutes) async {
    _rewardExpiration = DateTime.now().add(Duration(minutes: minutes));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'ad_reward_expiration', _rewardExpiration!.toIso8601String());
    debugPrint('🎁 No-Ads Reward Activated until: $_rewardExpiration');
  }

  // Method to update locally from settings Map (Sync with PriceService)
  void updateFromSettings(Map<String, dynamic> settings) {
    final adSettings = settings['admobSettings'];
    if (adSettings != null) {
      _isEnabled = adSettings['isEnabled'] ?? false;
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          _bannerId = adSettings['android']?['bannerUnitId'];
          _interstitialId = adSettings['android']?['interstitialUnitId'];
          _rewardedId = adSettings['android']?['rewardedInterstitialUnitId'];
        } else if (Platform.isIOS) {
          _bannerId = adSettings['ios']?['bannerUnitId'];
          _interstitialId = adSettings['ios']?['interstitialUnitId'];
          _rewardedId = adSettings['ios']?['rewardedInterstitialUnitId'];
        }
      }
      debugPrint(
          '🔄 AdService Updated from Settings: Enabled=$_isEnabled, Banner=$_bannerId');

      if (_isEnabled) {
        if (_interstitialId != null && !_isInterstitialAdLoaded) {
          loadInterstitialAd();
        }
        if (_rewardedId != null && !_isRewardedAdLoaded) {
          loadRewardedAd();
        }
      }
    }
  }

  // Method to fetch dynamic IDs (Call this from a Provider/Controller)
  Future<void> fetchAdSettings(String baseUrl) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/settings'));
      if (response.statusCode == 200) {
        updateFromSettings(json.decode(response.body));
      }
    } catch (e) {
      debugPrint('⚠️ Failed to fetch ad settings: $e');
    }
  }

  void loadInterstitialAd() {
    if (_interstitialId == null || !_isEnabled || kIsWeb) return;

    InterstitialAd.load(
      adUnitId: _interstitialId!,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          debugPrint('✅ Interstitial Ad Loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Interstitial Ad Failed to Load: $error');
          _isInterstitialAdLoaded = false;
        },
      ),
    );
  }

  void loadRewardedAd() {
    if (_rewardedId == null || !_isEnabled || kIsWeb) return;

    RewardedAd.load(
      adUnitId: _rewardedId!,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          debugPrint('✅ Rewarded Ad Loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Rewarded Ad Failed to Load: $error');
          _isRewardedAdLoaded = false;
        },
      ),
    );
  }

  void showInterstitialAd(
      {Function? onAdDismissed, bool ignoreReward = false}) {
    // Suppress ads if reward is active, unless explicitly ignored (e.g., clicking the reward button itself)
    if (isRewardActive && !ignoreReward) {
      onAdDismissed?.call();
      return;
    }

    if (!_isInterstitialAdLoaded || _interstitialAd == null) {
      onAdDismissed?.call();
      loadInterstitialAd(); // Try for next time
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isInterstitialAdLoaded = false;
        loadInterstitialAd(); // Preload next
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isInterstitialAdLoaded = false;
        loadInterstitialAd();
        onAdDismissed?.call();
      },
    );

    _interstitialAd!.show();
  }

  void showRewardedAd(
      {required Function onRewardEarned,
      Function? onAdDismissed,
      Function? onAdFailed}) {
    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      // إن لم يتوفر إعلان مكافأة، نحاول عرض إعلان بيني كبديل
      if (_isInterstitialAdLoaded && _interstitialAd != null) {
        showInterstitialAd(
          ignoreReward: true,
          onAdDismissed: () {
            onRewardEarned();
            onAdDismissed?.call();
          },
        );
      } else {
        // لا يوجد إعلان مكافأة ولا إعلان بيني جاهز
        onAdFailed?.call();
      }
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isRewardedAdLoaded = false;
        loadRewardedAd();
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isRewardedAdLoaded = false;
        loadRewardedAd();
        onAdDismissed?.call();
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
      onRewardEarned();
    });
  }
}
