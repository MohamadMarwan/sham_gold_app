import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../core/services/ad_service.dart';
import 'home_page.dart';
import 'onboarding_page.dart';
import '../../../../shared/widgets/premium_logo.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
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

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final priceService = ref.read(priceServiceProvider);
    final adService = AdService();

    if (widget.fromResume) {
      priceService.refreshPrices();
    }

    // Wait for the App Open Ad to load, up to the dynamically configured timeout limit.
    // We check the timeout on each iteration to adapt reactively to settings loaded from cache.
    // Wait for a minimum of 1200ms to allow splash animations and cache loading to complete
    final startTime = DateTime.now();
    
    int waitCount = 0;

    while (waitCount < (adService.appOpenTimeoutSeconds * 10)) {
      if (adService.appOpenTimeoutSeconds <= 0) break;

      await Future.delayed(const Duration(milliseconds: 100));
      waitCount++;

      // Break as soon as the ad is loaded — it's ready to show
      if (adService.isAppOpenAdLoaded) break;
    }

    // Show App Open Ad if it finished loading within the configured window and is enabled (timeout > 0)
    if (adService.appOpenTimeoutSeconds > 0 && adService.isAppOpenAdLoaded && mounted) {
      adService.showStartupAppOpenAd(onAdDismissed: _navigateToHome);
      return; // Navigation happens after the ad is dismissed
    }

    final elapsedTime = DateTime.now().difference(startTime).inMilliseconds;
    if (elapsedTime < 1500) {
      await Future.delayed(Duration(milliseconds: 1500 - elapsedTime));
    }

    _navigateToHome();
  }

  void _navigateToHome() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) =>
              hasSeenOnboarding ? const HomePage() : const OnboardingPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
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
          // Main Content
          Center(
            child: StreamBuilder<Map<String, dynamic>>(
              stream: priceService.settingsStream,
              builder: (context, snapshot) {
                final settings = snapshot.data;
                final logoUrl = settings?['logoUrl'] as String?;
                final appName = settings?['appName'] as String? ?? 'auto_str_320'.tr();

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3), // Add top spacing
                    ScaleTransition(
                      scale: _logoScaleAnimation,
                      child: FadeTransition(
                        opacity: _logoFadeAnimation,
                        child: PremiumLogo(
                          size: 190,
                          logoUrl: logoUrl,
                        ),
                      ),
                    ),
                    const Spacer(
                        flex: 1), // Dynamic spacing instead of fixed 60
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
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 20,
                                  offset: Offset(0, 5),
                                )
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'app_tagline'.tr(),
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.gold,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(
                        flex: 2), // Dynamic spacing instead of fixed 120
                    // Elegant loading indicator
                    FadeTransition(
                      opacity: _loadingFadeAnimation,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 35,
                            height: 35,
                            child: const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'loading_data'.tr(),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 1), // Add bottom spacing
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
