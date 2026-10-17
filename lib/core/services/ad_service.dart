import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/web_stubs/ads_wrapper.dart';
import '../utils/web_stubs/fb_ads_wrapper.dart';
import '../utils/web_stubs/att_wrapper.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';


import '../constants/app_colors.dart';


class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Note: All ad unit IDs are dynamically loaded from the backend or cache.
  // There are no hardcoded ad IDs to ensure complete dashboard control.
  String? _bannerId;
  String? _interstitialId;
  String? _rewardedId;
  String? _appOpenId;
  String? _nativeId;
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
  bool _isInterstitialEnabled = true;
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
        final status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          // If a UI context is provided and active, show informative explanation dialog first
          if (context != null && context.mounted) {
            await _showTrackingExplanationDialog(context);
          }
          // Brief pause so the iOS window and modal dismissal fully settle
          await Future.delayed(const Duration(milliseconds: 300));
          final requestedStatus = await AppTrackingTransparency.requestTrackingAuthorization();
          debugPrint('📱 iOS ATT Requested Result: $requestedStatus');
        }

        final finalStatus = await AppTrackingTransparency.trackingAuthorizationStatus;
        final bool isTrackingEnabled = (finalStatus == TrackingStatus.authorized);

        // Notify Facebook SDK about tracking status
        await FacebookAudienceNetwork.init(
          iOSAdvertiserTrackingEnabled: isTrackingEnabled,
        );
        debugPrint('📱 iOS ATT Status sent to Meta: $isTrackingEnabled (ATT: $finalStatus)');
      } else {
        // Android Initialization
        await FacebookAudienceNetwork.init();
      }

      // 2. Initialize Google Mobile Ads
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('✅ All Ad SDKs Initialized');

      // 3. Pre-load App Open Ad immediately from cache if enabled
      final prefs = await SharedPreferences.getInstance();
      final bool cachedEnabled = prefs.getBool('cached_ads_enabled') ?? false;
      final bool cachedStartup = prefs.getBool('cached_app_open_on_startup') ?? true;
      final String? cachedAppOpenId = prefs.getString('cached_app_open_id');

      _isEnabled = cachedEnabled;
      _showAppOpenOnStartup = cachedStartup;

      if (cachedEnabled && cachedStartup && cachedAppOpenId != null && cachedAppOpenId.isNotEmpty) {
        _appOpenId = cachedAppOpenId;
        _loadAppOpenAdBypass();
      } else {
        debugPrint('🚫 App Open Ad is disabled in cache or startup is disabled.');
      }
    } catch (e) {
      debugPrint('❌ Ads Init Error: $e');
    }
  }

  /// Backwards-compatible initialize method
  Future<void> initialize({BuildContext? context}) async {
    await requestTrackingAndInitialize(context: context);
  }

  /// Displays an elegant, Apple-compliant explanatory dialog before triggering the native ATT prompt.
  Future<void> _showTrackingExplanationDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.gold.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            backgroundColor: isDark ? AppColors.darkSurfaceRaised : Colors.white,
            elevation: 16,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.gold.withValues(alpha: 0.2),
                          AppColors.gold.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.privacy_tip_outlined,
                      color: AppColors.gold,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isArabic ? 'خصوصيتك تهمنا' : 'Your Privacy Matters',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isArabic
                        ? 'في الخطوة التالية، ستطلب منك نافذة نظام iOS الإذن للتتبع. يساعد هذا الإذن في تقديم إعلانات مخصصة تناسب اهتماماتك وتدعم استمرار تقديم خدمات ومتابعة أسعار الذهب والعملات مجاناً.'
                        : 'On the next screen, iOS will ask for your tracking permission. This allows us to serve relevant personalized ads that support keeping our gold and currency tracking services completely free.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      height: 1.6,
                      color: isDark ? Colors.white70 : AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isArabic ? 'متابعة' : 'Continue',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
          newInterstitialId = (dbInterstitial != null && dbInterstitial.toString().trim().isNotEmpty) ? dbInterstitial : null;
              
          newRewardedId = adSettings['android']?['rewardedInterstitialUnitId'];
          _appOpenId = adSettings['android']?['appOpenUnitId'];
          _nativeId = adSettings['android']?['nativeUnitId'];
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          _bannerId = adSettings['ios']?['bannerUnitId'];
          
          final dbInterstitial = adSettings['ios']?['interstitialUnitId'];
          newInterstitialId = (dbInterstitial != null && dbInterstitial.toString().trim().isNotEmpty) ? dbInterstitial : null;
              
          newRewardedId = adSettings['ios']?['rewardedInterstitialUnitId'];
          _appOpenId = adSettings['ios']?['appOpenUnitId'];
          _nativeId = adSettings['ios']?['nativeUnitId'];
        }
      }

      // Detect if the ad unit IDs changed → force reload
      final interstitialIdChanged = newInterstitialId != _interstitialId;
      final rewardedIdChanged = newRewardedId != _rewardedId;
      _interstitialId = newInterstitialId;
      _rewardedId = newRewardedId;

      final interSettings = adSettings['interstitialSettings'];
      if (interSettings != null) {
        _isInterstitialEnabled = interSettings['enabled'] ?? true;
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
    if (!_isEnabled || !_isInterstitialEnabled) return;
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
    debugPrint('🧭 showInterstitialOnNavigation → enabled=$_isEnabled | interstitialEnabled=$_isInterstitialEnabled | showOnPageChange=$_showOnPageChange | loaded=$_isInterstitialAdLoaded | isShowing=$_isShowingAd | rewardActive=$isRewardActive | force=$force');
    if (kIsWeb) {
      debugPrint('⛔ Web platform — skip');
      return;
    }
    if (!_isEnabled || !_isInterstitialEnabled) {
      debugPrint('⛔ Ads or Interstitials disabled from dashboard');
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
    if (!_isEnabled || !_showAppOpenOnStartup || isRewardActive || kIsWeb) {
      debugPrint('⚠️ Startup App Open Ad disabled or reward active — skipping');
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
