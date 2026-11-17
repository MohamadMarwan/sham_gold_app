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

  // Verified fallback ad unit IDs from production dashboard
  static const String fallbackInterstitialId = 'ca-app-pub-4487814270090643/3678329046';
  static const String fallbackBannerId = 'ca-app-pub-1767098791247433/2351852934';
  static const String fallbackAppOpenId = 'ca-app-pub-4487814270090643/9724607423';

  String? _bannerId;
  String? _interstitialId;
  String? _rewardedId;
  String? _appOpenId;
  String? _nativeId;
  bool _isEnabled = true;
  int _appOpenTimeoutSeconds = 3;
  int get appOpenTimeoutSeconds => _appOpenTimeoutSeconds;
  
  bool _showAppOpenOnStartup = true;
  bool _showAppOpenOnResume = true;
  int _appOpenResumeTimeoutSeconds = 30;
  bool get showAppOpenOnStartup => _showAppOpenOnStartup;
  bool get showAppOpenOnResume => _showAppOpenOnResume;
  int get appOpenResumeTimeoutSeconds => _appOpenResumeTimeoutSeconds;

  bool _showOnPageChange = true;
  bool _isInterstitialEnabled = true;
  int _interstitialInterval = 2;
  int _pageChangeCount = 0;
  int _interstitialRetryAttempts = 0;
  int _rewardedRetryAttempts = 0;
  static const int _maxRetryAttempts = 5;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;
  bool _isLoadingInterstitial = false;
  DateTime? _lastInterstitialShowTime;
  static const Duration _minInterstitialCooldown = Duration(seconds: 20);

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;
  AppOpenAd? _appOpenAd;
  bool _isAppOpenAdLoaded = false;
  bool _isShowingAd = false;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Reward State
  DateTime? _rewardExpiration;

  bool get isEnabled => _isEnabled && !isRewardActive;
  bool get isInterstitialEnabled => _isInterstitialEnabled;
  String? get bannerId => _bannerId;
  String? get interstitialId => _interstitialId;
  String? get rewardedId => _rewardedId;
  String? get appOpenId => _appOpenId;
  String? get nativeId => _nativeId;
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

  /// Request App Tracking Transparency authorization and initialize ad SDKs.
  /// When on iOS and tracking status is notDetermined, this presents an
  /// explanatory dialog followed by the native iOS ATT dialog BEFORE any ads are loaded.
  Future<void> requestTrackingAndInitialize({BuildContext? context}) async {
    if (kIsWeb) return;
    if (_isInitialized) return;
    await _loadRewardState();

    try {
      // 1. Handle App Tracking Transparency for iOS before loading any ads
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final status = await AppTrackingTransparency.trackingAuthorizationStatus
            .timeout(const Duration(milliseconds: 1000), onTimeout: () => TrackingStatus.notDetermined);
        if (status == TrackingStatus.notDetermined) {
          // Present native iOS ATT dialog directly without any manipulative custom pre-prompt
          final requestedStatus = await AppTrackingTransparency.requestTrackingAuthorization()
              .timeout(const Duration(seconds: 2), onTimeout: () => TrackingStatus.notDetermined);
          debugPrint('📱 iOS ATT Requested Result: $requestedStatus');
        }

        final finalStatus = await AppTrackingTransparency.trackingAuthorizationStatus
            .timeout(const Duration(milliseconds: 800), onTimeout: () => TrackingStatus.notDetermined);
        final bool isTrackingEnabled = (finalStatus == TrackingStatus.authorized);

        // Notify Facebook SDK about tracking status
        await FacebookAudienceNetwork.init(
          iOSAdvertiserTrackingEnabled: isTrackingEnabled,
        ).timeout(const Duration(seconds: 2), onTimeout: () => false);
        debugPrint('📱 iOS ATT Status sent to Meta: $isTrackingEnabled (ATT: $finalStatus)');
      } else {
        // Android Initialization
        await FacebookAudienceNetwork.init()
            .timeout(const Duration(seconds: 2), onTimeout: () => false);
      }

      // 2. Initialize Google Mobile Ads
      try {
        await MobileAds.instance.initialize().timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('⚠️ Google Mobile Ads initialization error or timed out: $e');
      }
      _isInitialized = true;
      debugPrint('✅ All Ad SDKs Initialized');

      // 3. Pre-load Ads immediately from cache or defaults if enabled
      final prefs = await SharedPreferences.getInstance();
      final bool cachedEnabled = prefs.getBool('cached_ads_enabled') ?? true;
      final bool cachedStartup = prefs.getBool('cached_app_open_on_startup') ?? true;
      final String? cachedAppOpenId = prefs.getString('cached_app_open_id');
      final String? cachedInterstitialId = prefs.getString('cached_interstitial_id');
      final bool cachedInterstitialEnabled = prefs.getBool('cached_interstitial_enabled') ?? true;
      final int cachedInterval = prefs.getInt('cached_interstitial_interval') ?? 2;
      final bool cachedShowOnPageChange = prefs.getBool('cached_show_on_page_change') ?? true;

      _isEnabled = cachedEnabled;
      _showAppOpenOnStartup = cachedStartup;
      _isInterstitialEnabled = cachedInterstitialEnabled;
      _interstitialInterval = cachedInterval > 0 ? cachedInterval : 2;
      _showOnPageChange = cachedShowOnPageChange;

      _appOpenId = (cachedAppOpenId != null && cachedAppOpenId.isNotEmpty)
          ? cachedAppOpenId
          : fallbackAppOpenId;

      _interstitialId = (cachedInterstitialId != null && cachedInterstitialId.isNotEmpty)
          ? cachedInterstitialId
          : fallbackInterstitialId;

      if (_isEnabled && _showAppOpenOnStartup && _appOpenId != null && _appOpenId!.isNotEmpty) {
        _loadAppOpenAdBypass();
      } else {
        debugPrint('🚫 App Open Ad is disabled in cache or startup is disabled.');
      }

      if (_isEnabled && _isInterstitialEnabled) {
        debugPrint('📢 Preloading Interstitial Ad on startup: $_interstitialId');
        loadInterstitialAd();
      }
    } catch (e) {
      debugPrint('❌ Ads Init Error: $e');
    }
  }

  /// Backwards-compatible initialize method
  Future<void> initialize({BuildContext? context}) async {
    await requestTrackingAndInitialize(context: context);
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
          _bannerId = adSettings['android']?['bannerUnitId']?.toString().trim();
          
          final dbInterstitial = adSettings['android']?['interstitialUnitId']?.toString().trim();
          newInterstitialId = (dbInterstitial != null && dbInterstitial.isNotEmpty) ? dbInterstitial : null;
              
          newRewardedId = adSettings['android']?['rewardedInterstitialUnitId']?.toString().trim();
          _appOpenId = adSettings['android']?['appOpenUnitId']?.toString().trim();
          _nativeId = adSettings['android']?['nativeUnitId']?.toString().trim();
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          _bannerId = adSettings['ios']?['bannerUnitId']?.toString().trim();
          
          final dbInterstitial = adSettings['ios']?['interstitialUnitId']?.toString().trim();
          newInterstitialId = (dbInterstitial != null && dbInterstitial.isNotEmpty) ? dbInterstitial : null;
              
          newRewardedId = adSettings['ios']?['rewardedInterstitialUnitId']?.toString().trim();
          _appOpenId = adSettings['ios']?['appOpenUnitId']?.toString().trim();
          _nativeId = adSettings['ios']?['nativeUnitId']?.toString().trim();
        }
      }

      // Detect if the ad unit IDs changed → force reload
      final interstitialIdChanged = newInterstitialId != null && newInterstitialId != _interstitialId;
      final rewardedIdChanged = newRewardedId != null && newRewardedId != _rewardedId;
      if (newInterstitialId != null && newInterstitialId.isNotEmpty) {
        _interstitialId = newInterstitialId.trim();
      } else if (_interstitialId == null || _interstitialId!.isEmpty) {
        _interstitialId = fallbackInterstitialId;
      }
      _rewardedId = newRewardedId;

      final interSettings = adSettings['interstitialSettings'];
      if (interSettings != null) {
        _isInterstitialEnabled = interSettings['enabled'] ?? true;
        _showOnPageChange = interSettings['showOnPageChange'] ?? true;
        final rawInterval = interSettings['interval'];
        if (rawInterval != null && rawInterval is num && rawInterval > 0) {
          _interstitialInterval = rawInterval.toInt();
        }
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

      if (_isEnabled && _isInterstitialEnabled) {
        // Load interstitial if: not loaded yet, OR the ad unit ID changed
        if (!_isInterstitialAdLoaded || interstitialIdChanged) {
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
        debugPrint('⚠️ AdService: ads or interstitials disabled from settings');
      }

      // Cache settings so that next startup knows what to do before the API responds
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('cached_ads_enabled', _isEnabled);
        prefs.setBool('cached_app_open_on_startup', _showAppOpenOnStartup);
        prefs.setBool('cached_interstitial_enabled', _isInterstitialEnabled);
        prefs.setBool('cached_show_on_page_change', _showOnPageChange);
        prefs.setInt('cached_interstitial_interval', _interstitialInterval);
        if (_appOpenId != null && _appOpenId!.isNotEmpty) {
          prefs.setString('cached_app_open_id', _appOpenId!);
        }
        if (_interstitialId != null && _interstitialId!.isNotEmpty) {
          prefs.setString('cached_interstitial_id', _interstitialId!);
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
    if (kIsWeb) return;
    if (!_isEnabled || !_isInterstitialEnabled) {
      debugPrint('⚠️ loadInterstitialAd() skipped: enabled=$_isEnabled, interEnabled=$_isInterstitialEnabled');
      return;
    }
    if (_isInterstitialAdLoaded || _isLoadingInterstitial) {
      debugPrint('📡 loadInterstitialAd() skipped: already loaded or loading');
      return;
    }

    final effectiveId = (_interstitialId != null && _interstitialId!.trim().isNotEmpty)
        ? _interstitialId!.trim()
        : fallbackInterstitialId;

    _isLoadingInterstitial = true;
    debugPrint('📡 Loading Interstitial Ad: $effectiveId (Platform: $defaultTargetPlatform)');

    InterstitialAd.load(
      adUnitId: effectiveId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          _isLoadingInterstitial = false;
          _interstitialRetryAttempts = 0;
          debugPrint('✅ Interstitial Ad Loaded successfully');
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Interstitial Ad Failed to Load: ${error.message} (code: ${error.code})');
          if (error.code == 3) {
            debugPrint('💡 [AdMob Hint] Code 3 (ERROR_CODE_NO_FILL): AdMob has no ads to serve. Possible causes: unverified AdMob account, app not yet published/approved on Google Play, or testing with real ad units instead of Google Test IDs.');
          } else if (error.code == 0) {
            debugPrint('💡 [AdMob Hint] Code 0 (INTERNAL_ERROR): Likely mismatched App ID in AndroidManifest.xml / Info.plist with this Ad Unit account.');
          }
          _isInterstitialAdLoaded = false;
          _isLoadingInterstitial = false;
          _interstitialAd = null;

          if (_interstitialRetryAttempts < _maxRetryAttempts) {
            _interstitialRetryAttempts++;
            int delay = _interstitialRetryAttempts * 10;
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
    if (!_isEnabled || !_isInterstitialEnabled) return;
    if (isRewardActive && !force) return;
    
    if (_isShowingAd) return;

    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          _isShowingAd = true;
          _lastInterstitialShowTime = DateTime.now();
          debugPrint('✅ Interstitial Ad showing full screen');
        },
        onAdDismissedFullScreenContent: (ad) {
          _isShowingAd = false;
          _lastInterstitialShowTime = DateTime.now();
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
          loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
    }
  }

  void showInterstitialOnNavigation({bool force = false}) {
    debugPrint(
        '🧭 showInterstitialOnNavigation → enabled=$_isEnabled | interstitialEnabled=$_isInterstitialEnabled | '
        'showOnPageChange=$_showOnPageChange | loaded=$_isInterstitialAdLoaded | isShowing=$_isShowingAd | '
        'rewardActive=$isRewardActive | pageCount=$_pageChangeCount / $_interstitialInterval | force=$force');

    if (kIsWeb) {
      debugPrint('⛔ Web platform — skip');
      return;
    }
    if (!_isEnabled || !_isInterstitialEnabled) {
      debugPrint('⛔ Ads or Interstitials globally disabled');
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
        debugPrint('⛔ showOnPageChange is disabled');
        return;
      }

      _pageChangeCount++;
      debugPrint('📊 Navigation Count: $_pageChangeCount / $_interstitialInterval');

      if (_pageChangeCount < _interstitialInterval) {
        if (!_isInterstitialAdLoaded && !_isLoadingInterstitial) {
          loadInterstitialAd();
        }
        return;
      }

      // Minimum cooldown (20 seconds) between full-screen interstitial ads
      if (_lastInterstitialShowTime != null) {
        final elapsed = DateTime.now().difference(_lastInterstitialShowTime!);
        if (elapsed < _minInterstitialCooldown) {
          debugPrint('⏳ Cooldown active (${elapsed.inSeconds}s < ${_minInterstitialCooldown.inSeconds}s) — skipping ad to protect UX');
          return;
        }
      }
    }

    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      if (!force) {
        _pageChangeCount = 0; // Only reset when we actually show the ad!
      }
      showInterstitialAd(force: force);
    } else {
      debugPrint('⚠️ Interstitial not ready — preloading now (counter kept ready at $_pageChangeCount)');
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
  Future<void> showStartupAppOpenAd({Function? onAdDismissed}) async {
    if (!_isEnabled || !_showAppOpenOnStartup || isRewardActive || kIsWeb) {
      debugPrint('⚠️ Startup App Open Ad skipped (enabled: $_isEnabled, startup: $_showAppOpenOnStartup)');
      onAdDismissed?.call();
      return;
    }

    if (_isShowingAd) {
      onAdDismissed?.call();
      return;
    }

    // If ad is already loaded, show it immediately
    if (_isAppOpenAdLoaded && _appOpenAd != null) {
      debugPrint('✅ App Open Ad already loaded, showing on startup');
      showAppOpenAd(onAdDismissed: onAdDismissed);
      return;
    }

    // If timeout is 0 or ad unit ID is empty, proceed immediately
    if (_appOpenTimeoutSeconds <= 0 || _appOpenId == null || _appOpenId!.isEmpty) {
      onAdDismissed?.call();
      return;
    }

    debugPrint('⏳ Waiting up to ${_appOpenTimeoutSeconds}s for App Open Ad to load on startup...');
    loadAppOpenAd();

    final startTime = DateTime.now();
    while (!_isAppOpenAdLoaded && DateTime.now().difference(startTime).inSeconds < _appOpenTimeoutSeconds) {
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (_isAppOpenAdLoaded && _appOpenAd != null) {
      debugPrint('✅ App Open Ad loaded within timeout, showing now');
      showAppOpenAd(onAdDismissed: onAdDismissed);
    } else {
      debugPrint('⚠️ App Open Ad did not load within ${_appOpenTimeoutSeconds}s timeout, continuing to app');
      onAdDismissed?.call();
    }
  }
}
