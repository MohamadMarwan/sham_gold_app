import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../core/services/ad_service.dart';
import 'home_page.dart';
import '../../../../shared/widgets/premium_logo.dart';

class SplashPage extends StatefulWidget {
  final bool fromResume;
  const SplashPage({super.key, this.fromResume = false});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );

    _controller.forward();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final priceService = Provider.of<PriceService>(context, listen: false);
    final adService = AdService();

    if (widget.fromResume) {
      priceService.refreshPrices();
    }

    // Wait for BOTH prices and the App Open Ad in parallel.
    // Maximum wait: 3 seconds total.
    // We break early as soon as the ad is ready (no point waiting longer).
    int waitCount = 0;
    const int maxWait = 30; // 30 × 100ms = 3 seconds

    while (waitCount < maxWait) {
      await Future.delayed(const Duration(milliseconds: 100));
      waitCount++;

      // Break as soon as the ad is loaded — it's ready to show
      if (adService.isAppOpenAdLoaded) break;

      // If prices are loaded and we've waited at least 1 s, don't keep waiting
      // just for the ad — let the user into the app
      if (priceService.currentPrices.isNotEmpty && waitCount >= 10) break;
    }

    // Show App Open Ad if it finished loading in time
    if (adService.isAppOpenAdLoaded && mounted) {
      adService.showStartupAppOpenAd(onAdDismissed: _navigateToHome);
      return; // Navigation happens after the ad is dismissed
    }

    _navigateToHome();
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomePage(),
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
    final priceService = Provider.of<PriceService>(context);

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
                final appName = settings?['appName'] as String? ?? 'غولد شام';

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3), // Add top spacing
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: PremiumLogo(
                          size: 190,
                          logoUrl: logoUrl,
                        ),
                      ),
                    ),
                    const Spacer(
                        flex: 1), // Dynamic spacing instead of fixed 60
                    FadeTransition(
                      opacity: _fadeAnimation,
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
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              'دليلك الأول لأسعار الذهب والعملات',
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
                      opacity: _fadeAnimation,
                      child: const Column(
                        children: [
                          SizedBox(
                            width: 35,
                            height: 35,
                            child: CircularProgressIndicator(
                              color: AppColors.gold,
                              strokeWidth: 3,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'جاري تحديث البيانات اللحظية...',
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
