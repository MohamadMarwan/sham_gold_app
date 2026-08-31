import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/web_stubs/ads_wrapper.dart';
import '../utils/web_stubs/fb_ads_wrapper.dart';
import '../utils/web_stubs/att_wrapper.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';


class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // ─── App Open Ad unit ID (hardcoded for startup — loaded before backend settings arrive) ───
  static const String _kAppOpenAdUnitId = 'ca-app-pub-4487814270090643/1749829422';


  String? _bannerId;
  String? _interstitialId;
  String? _rewardedId;
  String? _appOpenId;
  bool _isEnabled = false;
  int _appOpenTimeoutSeconds = 3;
  int get appOpenTimeoutSeconds => _appOpenTimeoutSeconds;
  
  bool _showAppOpenOnStartup = true;
  bool _showAppOpenOnResume = true;
  int _appOpenResumeTimeoutSeconds = 30;
  bool get showAppOpenOnStartup => _showAppOpenOnStartup;
  bool get showAppOpenOnResume => _showAppOpenOnResume;
  int get appOpenResumeTimeoutSeconds => _appOpenResumeTimeoutSeconds;

  bool _showOnPageChange = true;
  int _interstitialInterval = 1;
  int _pageChangeCount = 0;
  int _interstitialRetryAttempts = 0;
  int _rewardedRetryAttempts = 0;
  static const int _maxRetryAttempts = 5;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;
  AppOpenAd? _appOpenAd;
  bool _isAppOpenAdLoaded = false;
  bool _isShowingAd = false;

  // Reward State
  DateTime? _rewardExpiration;

  bool get isEnabled => _isEnabled && !isRewardActive;
  String? get bannerId => _bannerId;
  String? get interstitialId => _interstitialId;
  String? get rewardedId => _rewardedId;
  String? get appOpenId => _appOpenId;
  bool get isAppOpenAdLoaded => _isAppOpenAdLoaded;
  bool get isShowingAd => _isShowingAd;

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
      // 1. Handle App Tracking Transparency for iOS (Fixes Meta Error #17)
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
        
        final finalStatus = await AppTrackingTransparency.trackingAuthorizationStatus;
        bool isTrackingEnabled = finalStatus == TrackingStatus.authorized;
        
        // Notify Facebook about tracking status
        await FacebookAudienceNetwork.init(
          iOSAdvertiserTrackingEnabled: isTrackingEnabled,
        );
        debugPrint('📱 iOS ATE Status sent to Meta: $isTrackingEnabled');
      } else {
        // Android Initialization
        await FacebookAudienceNetwork.init();
      }

      // 2. Initialize Google Mobile Ads
      await MobileAds.instance.initialize();
      debugPrint('✅ All Ad SDKs Initialized');

      // 3. Pre-load App Open Ad immediately. Check cache first.
      //    (backend settings may not be fetched yet at this point)
      final prefs = await SharedPreferences.getInstance();
      final bool cachedEnabled = prefs.getBool('cached_ads_enabled') ?? true;
      final bool cachedStartup = prefs.getBool('cached_app_open_on_startup') ?? true;
      final String? cachedAppOpenId = prefs.getString('cached_app_open_id');
      
      if (cachedEnabled && cachedStartup) {
        _appOpenId = (cachedAppOpenId != null && cachedAppOpenId.isNotEmpty) ? cachedAppOpenId : _kAppOpenAdUnitId;
        _loadAppOpenAdBypass(); // ← bypass _isEnabled check for startup
      } else {
        debugPrint('🚫 App Open Ad is disabled in cache or startup is disabled.');
      }
    } catch (e) {
      debugPrint('❌ Ads Init Error: $e');
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
      final wasEnabled = _isEnabled;
      _isEnabled = adSettings['isEnabled'] ?? false;
      _appOpenTimeoutSeconds = adSettings['appOpenTimeoutSeconds'] ?? 3;

      String? newInterstitialId;
      String? newRewardedId;

      if (!kIsWeb) {
        if (defaultTargetPlatform == TargetPlatform.android) {
          _bannerId = adSettings['android']?['bannerUnitId'];
          
          final dbInterstitial = adSettings['android']?['interstitialUnitId'];
          newInterstitialId = (dbInterstitial != null && dbInterstitial.toString().trim().isNotEmpty) 
              ? dbInterstitial 
              : 'ca-app-pub-4487814270090643/9895234137';
              
          newRewardedId = adSettings['android']?['rewardedInterstitialUnitId'];
          _appOpenId = adSettings['android']?['appOpenUnitId'];
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          _bannerId = adSettings['ios']?['bannerUnitId'];
          
          final dbInterstitial = adSettings['ios']?['interstitialUnitId'];
          newInterstitialId = (dbInterstitial != null && dbInterstitial.toString().trim().isNotEmpty) 
              ? dbInterstitial 
              : 'ca-app-pub-4487814270090643/9895234137';
              
          newRewardedId = adSettings['ios']?['rewardedInterstitialUnitId'];
          _appOpenId = adSettings['ios']?['appOpenUnitId'];
        }
      }

      // Detect if the ad unit IDs changed → force reload
      final interstitialIdChanged = newInterstitialId != _interstitialId;
      final rewardedIdChanged = newRewardedId != _rewardedId;
      _interstitialId = newInterstitialId;
      _rewardedId = newRewardedId;

      final interSettings = adSettings['interstitialSettings'];
      if (interSettings != null) {
        _showOnPageChange = interSettings['showOnPageChange'] ?? true;
        _interstitialInterval = interSettings['interval'] ?? 1;
      }

      final appOpenSettings = adSettings['appOpenSettings'];
      if (appOpenSettings != null) {
        _showAppOpenOnStartup = appOpenSettings['showOnStartup'] ?? true;
        _showAppOpenOnResume = appOpenSettings['showOnResume'] ?? true;
        _appOpenResumeTimeoutSeconds = appOpenSettings['resumeTimeoutSeconds'] ?? 30;
      }

      debugPrint(
          '🔄 AdService Updated: Enabled=$_isEnabled, Interstitial=$_interstitialId, '
          'showOnPageChange=$_showOnPageChange, interval=$_interstitialInterval, '
          'wasEnabled=$wasEnabled, idChanged=$interstitialIdChanged');

      if (_isEnabled) {
        // Load interstitial if: not loaded yet, OR the ad unit ID changed
        if (_interstitialId != null && (!_isInterstitialAdLoaded || interstitialIdChanged)) {
          debugPrint('📢 Triggering loadInterstitialAd() from updateFromSettings');
          loadInterstitialAd();
        }
        if (_rewardedId != null && (!_isRewardedAdLoaded || rewardedIdChanged)) {
          loadRewardedAd();
        }
        if (_appOpenId != null && !_isAppOpenAdLoaded) {
          loadAppOpenAd();
        }
      } else {
        debugPrint('⚠️ AdService: _isEnabled=false → no ads will load or show');
      }

      // Cache settings so that next startup knows what to do before the API responds
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('cached_ads_enabled', _isEnabled);
        prefs.setBool('cached_app_open_on_startup', _showAppOpenOnStartup);
        if (_appOpenId != null && _appOpenId!.isNotEmpty) {
          prefs.setString('cached_app_open_id', _appOpenId!);
        }
      });
    }
  }

  Future<AdSize> getAdaptiveBannerSize(BuildContext context) async {
    if (kIsWeb) return AdSize.banner;
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.of(context).size.width.truncate(),
    );
    return size ?? AdSize.banner;
  }

  // Method to fetch dynamic IDs (Call this from a Provider/Controller)
  Future<void> fetchAdSettings(String baseUrl) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/settings'),
        headers: {'x-api-key': AppConfig.apiAccessKey},
      );
      if (response.statusCode == 200) {
        updateFromSettings(json.decode(response.body));
      }
    } catch (e) {
      debugPrint('⚠️ Failed to fetch ad settings: $e');
    }
  }

  void loadInterstitialAd() {
    if (_interstitialId == null || _interstitialId!.trim().isEmpty || !_isEnabled || kIsWeb) {
      debugPrint('⚠️ loadInterstitialAd() skipped: id=$_interstitialId, enabled=$_isEnabled, web=$kIsWeb');
      return;
    }
    debugPrint('📡 Loading Interstitial Ad: $_interstitialId');

    InterstitialAd.load(
      adUnitId: _interstitialId!,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          _interstitialRetryAttempts = 0;
          debugPrint('✅ Interstitial Ad Loaded successfully');
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Interstitial Ad Failed to Load: ${error.message} (code: ${error.code})');
          _isInterstitialAdLoaded = false;
          _interstitialAd = null;

          if (_interstitialRetryAttempts < _maxRetryAttempts) {
            _interstitialRetryAttempts++;
            int delay = _interstitialRetryAttempts * 30;
            Future.delayed(Duration(seconds: delay), () => loadInterstitialAd());
            debugPrint('🔄 Retrying Interstitial Ad in $delay seconds (attempt $_interstitialRetryAttempts)...');
          } else {
            debugPrint('🚫 Max retry attempts reached for Interstitial Ad');
          }
        },
      ),
    );
  }

  void loadRewardedAd() {
    if (_rewardedId == null || _rewardedId!.trim().isEmpty || !_isEnabled || kIsWeb) return;

    RewardedAd.load(
      adUnitId: _rewardedId!,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          _rewardedRetryAttempts = 0; // Reset on success
          debugPrint('✅ Rewarded Ad Loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Rewarded Ad Failed to Load: $error');
          _isRewardedAdLoaded = false;
          _rewardedAd = null;

          if (_rewardedRetryAttempts < _maxRetryAttempts) {
            _rewardedRetryAttempts++;
            int delay = _rewardedRetryAttempts * 30;
            Future.delayed(Duration(seconds: delay), () => loadRewardedAd());
            debugPrint('🔄 Retrying Rewarded Ad in $delay seconds...');
          } else {
            debugPrint('🚫 Max retry attempts reached for Rewarded Ad');
          }
        },
      ),
    );
  }

  void showRewardedAd({required VoidCallback onRewardEarned, required VoidCallback onAdFailed}) {
    if (!_isEnabled || kIsWeb) {
      onAdFailed();
      return;
    }

    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      debugPrint('⚠️ Rewarded Ad not ready');
      onAdFailed();
      loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        debugPrint('✅ Rewarded Ad showing');
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _isRewardedAdLoaded = false;
        _rewardedAd = null;
        loadRewardedAd(); // Load next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _isRewardedAdLoaded = false;
        _rewardedAd = null;
        debugPrint('❌ Rewarded Ad failed to show: $error');
        onAdFailed();
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      debugPrint('🏆 User earned reward: ${reward.amount} ${reward.type}');
      onRewardEarned();
    });
  }

  void showInterstitialAd({bool force = false}) {
    if (kIsWeb) return;
    if (!_isEnabled && !force) return;
    if (isRewardActive && !force) return;
    
    if (_isShowingAd) return;

    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          _isShowingAd = true;
        },
        onAdDismissedFullScreenContent: (ad) {
          _isShowingAd = false;
          ad.dispose();
          _isInterstitialAdLoaded = false;
          _interstitialAd = null;
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          _isShowingAd = false;
          ad.dispose();
          _isInterstitialAdLoaded = false;
          _interstitialAd = null;
        },
      );
      _interstitialAd!.show();
    }
  }

  void showInterstitialOnNavigation({bool force = false}) {
    debugPrint('🧭 showInterstitialOnNavigation → enabled=$_isEnabled | showOnPageChange=$_showOnPageChange | loaded=$_isInterstitialAdLoaded | isShowing=$_isShowingAd | rewardActive=$isRewardActive | force=$force');
    if (kIsWeb) {
      debugPrint('⛔ Web platform — skip');
      return;
    }
    if (!_isEnabled && !force) {
      debugPrint('⛔ Ads disabled');
      return;
    }
    if (isRewardActive && !force) {
      debugPrint('⛔ Reward is active');
      return;
    }
    if (_isShowingAd) {
      debugPrint('⛔ Another ad is already showing');
      return;
    }

    if (!force) {
      if (!_showOnPageChange) {
        debugPrint('⛔ showOnPageChange=false');
        return;
      }

      _pageChangeCount++;
      debugPrint('📊 Navigation Count: $_pageChangeCount / $_interstitialInterval');

      if (_pageChangeCount < _interstitialInterval) {
        return;
      }
      _pageChangeCount = 0;
    }

    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      showInterstitialAd(force: force);
    } else {
      debugPrint('⚠️ Interstitial not ready — requesting load for next time');
      loadInterstitialAd();
    }
  }

  void loadAppOpenAd() {
    if (_appOpenId == null || _appOpenId!.trim().isEmpty || !_isEnabled || kIsWeb) return;
    _loadAppOpenAdBypass();
  }

  void _loadAppOpenAdBypass() {
    if (_appOpenId == null || _appOpenId!.trim().isEmpty || kIsWeb) return;
    debugPrint('📡 Loading App Open Ad: $_appOpenId');

    AppOpenAd.load(
      adUnitId: _appOpenId!,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAppOpenAdLoaded = true;
          debugPrint('✅ App Open Ad Loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ App Open Ad Failed to Load: ${error.message} (code: ${error.code})');
          _isAppOpenAdLoaded = false;
          _appOpenAd = null;
        },
      ),
    );
  }

  void showAppOpenAd({Function? onAdDismissed}) {
    if (!_isEnabled || isRewardActive || kIsWeb) {
      onAdDismissed?.call();
      return;
    }

    if (_isShowingAd) {
      debugPrint('⚠️ Another ad is already showing');
      onAdDismissed?.call();
      return;
    }

    if (!_isAppOpenAdLoaded || _appOpenAd == null) {
      debugPrint('⚠️ App Open Ad not loaded yet');
      onAdDismissed?.call();
      loadAppOpenAd(); // Load for next time
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        debugPrint('✅ App Open Ad showing full screen');
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _isAppOpenAdLoaded = false;
        _appOpenAd = null;
        loadAppOpenAd(); // Preload next
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _isAppOpenAdLoaded = false;
        _appOpenAd = null;
        loadAppOpenAd();
        onAdDismissed?.call();
      },
    );

    _appOpenAd!.show();
  }

  void showOnResumeAppOpenAd(Duration pausedDuration, {Function? onAdDismissed}) {
    if (!_isEnabled || isRewardActive || kIsWeb) {
      onAdDismissed?.call();
      return;
    }

    if (!_showAppOpenOnResume) {
      debugPrint('⚠️ App Open Ad on Resume is disabled from dashboard');
      onAdDismissed?.call();
      return;
    }

    if (pausedDuration.inSeconds < _appOpenResumeTimeoutSeconds) {
      debugPrint('⚠️ App Open Ad skipped (paused for ${pausedDuration.inSeconds}s, requires $_appOpenResumeTimeoutSeconds s)');
      onAdDismissed?.call();
      return;
    }

    showAppOpenAd(onAdDismissed: onAdDismissed);
  }

  /// Shows the App Open Ad on cold start.
  /// Unlike [showAppOpenAd], this does NOT require the backend [isEnabled] flag,
  /// so it works reliably before backend settings are fetched.
  void showStartupAppOpenAd({Function? onAdDismissed}) {
    if (isRewardActive || kIsWeb) {
      onAdDismissed?.call();
      return;
    }

    if (_isShowingAd) {
      onAdDismissed?.call();
      return;
    }

    if (!_isAppOpenAdLoaded || _appOpenAd == null) {
      debugPrint('⚠️ Startup App Open Ad not loaded — skipping');
      onAdDismissed?.call();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        debugPrint('✅ Startup App Open Ad showing');
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _isAppOpenAdLoaded = false;
        _appOpenAd = null;
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _isAppOpenAdLoaded = false;
        _appOpenAd = null;
        debugPrint('❌ Startup App Open Ad failed to show: $error');
        onAdDismissed?.call();
      },
    );

    _appOpenAd!.show();
  }
}
