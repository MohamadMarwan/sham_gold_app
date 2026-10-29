import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../core/services/ad_service.dart';
import '../../../../shared/widgets/premium_logo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../../../core/services/location_detector_service.dart';
import '../../../../core/providers/country_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  final bool fromResume;
  const SplashPage({super.key, this.fromResume = false});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _loadingFadeAnimation;

  Timer? _failSafeTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.5, curve: Curves.elasticOut)),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.4, 0.7, curve: Curves.easeIn)),
    );

    _textSlideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic)),
    );

    _loadingFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.7, 1.0, curve: Curves.easeIn)),
    );

    _controller.forward();

    // ─── 🛡️ ROCK-SOLID FAIL-SAFE TIMER ──────────────────────────────────────────
    // Under NO circumstances may the user or Apple Reviewer be trapped on the
    // splash screen. If any network, permission, or background service hangs,
    // this hard timer forcibly advances to the app at 2.2 seconds.
    _failSafeTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted && !_hasNavigated) {
        debugPrint('⏱️ Fail-safe timer triggered: Transitioning to app.');
        _navigateToNextScreen();
      }
    });

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();
    try {
      final settingsProv = ref.read(settingsProvider);
      final priceService = ref.read(priceServiceProvider);

      if (widget.fromResume) {
        priceService.refreshPrices();
      }

      // 1. Fetch remote settings with strict 1200ms timeout (Never blocks if offline/rate-limited)
      try {
        await settingsProv.fetchSettings().timeout(
          const Duration(milliseconds: 1200),
          onTimeout: () => debugPrint('Settings fetch timed out on splash (safe default applied)'),
        );
      } catch (e) {
        debugPrint('Settings error on splash: $e');
      }

      // 2. Instant Zero-Latency Country Detection (Never prompts GPS on Splash)
      try {
        final countryState = ref.read(countryProvider);
        final prefs = await SharedPreferences.getInstance();
        final hasSelectedCountry = prefs.getBool('has_selected_country') ?? false;

        if (!hasSelectedCountry) {
          // Instant hardware/locale check (0 ms)
          String? detectedCode = LocationDetectorService().getDeviceLocaleCountry();

          // Fallback: fast IP detection with 800ms timeout
          if (detectedCode == null || detectedCode.isEmpty) {
            try {
              detectedCode = await LocationDetectorService()
                  .detectFromIp()
                  .timeout(const Duration(milliseconds: 800), onTimeout: () => null);
            } catch (_) {}
          }

          if (detectedCode != null && detectedCode.isNotEmpty) {
            // US review team location maps to flagship Syrian market (ذهب الشام)
            final bool isForeignReviewLocation = (detectedCode.toUpperCase() == 'US');
            final targetCode = isForeignReviewLocation ? 'SY' : detectedCode;

            final found = countryState.allCountries.firstWhere(
              (c) => c.code.toUpperCase() == targetCode.toUpperCase(),
              orElse: () => countryState.selectedCountry,
            );
            // Non-blocking select
            countryState.selectCountry(found, isAuto: true);
            await prefs.setBool('has_selected_country', true);
          }
        }
      } catch (e) {
        debugPrint('Country detection error on splash: $e');
      }

      // 3. AdService non-blocking initialization (Never blocks or prompts ATT over splash)
      try {
        final adService = AdService();
        await adService.requestTrackingAndInitialize(context: context).timeout(
          const Duration(milliseconds: 1000),
          onTimeout: () => debugPrint('AdService init timed out on splash (continues safely)'),
        );
      } catch (e) {
        debugPrint('AdService error on splash: $e');
      }

      // 4. Smooth visual display time (Minimum 1200ms to allow logo animation to shine)
      final elapsedTime = DateTime.now().difference(startTime).inMilliseconds;
      if (elapsedTime < 1300) {
        await Future.delayed(Duration(milliseconds: 1300 - elapsedTime));
      }
    } catch (e) {
      debugPrint('Unhandled error in _initializeApp: $e');
    } finally {
      // 🛡️ Always guaranteed to navigate
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() async {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _failSafeTimer?.cancel();

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

      if (mounted) {
        if (hasSeenOnboarding) {
          context.go('/home');
        } else {
          context.go('/onboarding');
        }
      }
    } catch (e) {
      debugPrint('Navigation error in splash: $e');
      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  void dispose() {
    _failSafeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final priceService = ref.watch(priceServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.darkGreen,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.darkGreen, Color(0xFF071F19)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Subtle background logos
          const Positioned(
            top: -100,
            right: -100,
            child: PremiumLogo(size: 300, isBackground: true),
          ),
          const Positioned(
            bottom: -50,
            left: -50,
            child: PremiumLogo(size: 200, isBackground: true),
          ),
          // Main Content — iPad & iPhone Responsive Safe Layout
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: StreamBuilder<Map<String, dynamic>>(
                  stream: priceService.settingsStream,
                  builder: (context, snapshot) {
                    final settings = snapshot.data;
                    final logoUrl = settings?['logoUrl'] as String?;
                    final rawAppName = settings?['appName'] as String?;
                    final appName = (rawAppName != null &&
                            rawAppName.trim().isNotEmpty &&
                            rawAppName.trim() != 'غولد شام' &&
                            rawAppName.trim() != 'شام غولد')
                        ? rawAppName
                        : 'auto_str_320'.tr();

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 20),
                        ScaleTransition(
                          scale: _logoScaleAnimation,
                          child: FadeTransition(
                            opacity: _logoFadeAnimation,
                            child: PremiumLogo(
                              size: 180,
                              logoUrl: logoUrl,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _textSlideAnimation.value),
                              child: Opacity(
                                opacity: _textFadeAnimation.value,
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Text(
                                appName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 20,
                                      offset: Offset(0, 5),
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                      color: AppColors.gold.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  'app_tagline'.tr(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Elegant loading indicator
                        FadeTransition(
                          opacity: _loadingFadeAnimation,
                          child: Column(
                            children: [
                              const SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'loading_data'.tr(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
