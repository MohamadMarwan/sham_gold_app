import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/country_provider.dart';
import '../../../../shared/models/country_model.dart';
import 'gold_page.dart';
import 'currencies_page.dart';
import 'portfolio_page.dart';
import 'smart_calculators_page.dart';
import 'country_market_page.dart';
import 'follow_us_page.dart';
import 'price_detail_page.dart';
import 'splash_page.dart';
import '../../../../core/services/ad_service.dart';
import 'bullions_coins_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late PageController _pageController;
  DateTime? _pausedTime;

  final GlobalKey _globalKey = GlobalKey();
  final GlobalKey _marketKey = GlobalKey();
  final GlobalKey _portfolioKey = GlobalKey();
  final GlobalKey _calcKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstRun();
      _setupAlertListener();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedTime != null) {
        final duration = DateTime.now().difference(_pausedTime!);
        if (duration.inMinutes >= 5) {
          _navigateToSplash();
        }
      }
      _pausedTime = null;
    }
  }

  void _navigateToSplash() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashPage(fromResume: true)),
        (route) => false,
      );
    }
  }

  void _setupAlertListener() {
    final priceService = Provider.of<PriceService>(context, listen: false);

    priceService.alertTriggeredStream.listen((data) {
      if (mounted) {
        HapticFeedback.vibrate();
        _showProfessionalSnack(
          title: data['title'] ?? 'alert_title'.tr(),
          body: data['body'] ?? '',
          icon: Icons.notifications_active,
          action: SnackBarAction(
            label: 'view'.tr(),
            textColor: AppColors.gold,
            onPressed: () {
              final priceItem = priceService.currentPrices.firstWhere(
                (p) => p.id == data['priceId'],
                orElse: () => priceService.currentPrices.first,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PriceDetailPage(priceItem: priceItem),
                ),
              );
            },
          ),
        );
      }
    });

    priceService.notificationStream.listen((data) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        _showProfessionalSnack(
          title: data['title'] ?? 'alert_notification'.tr(),
          body: data['body'] ?? '',
          icon: Icons.campaign_rounded,
          isBroadcast: true,
        );
      }
    });
  }

  void _showProfessionalSnack({
    required String title,
    required String body,
    required IconData icon,
    SnackBarAction? action,
    bool isBroadcast = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Colors.white,
                          fontFamily: 'Cairo')),
                  Text(body,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Cairo')),
                ],
              ),
            ),
          ],
        ),
        backgroundColor:
            isBroadcast ? const Color(0xFF1B5E20) : AppColors.darkGreen,
        behavior: SnackBarBehavior.floating,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.fromLTRB(15, 0, 15, 120),
        duration: Duration(seconds: isBroadcast ? 10 : 5),
        action: action,
      ),
    );
  }

  void _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('first_run_tutorial') ?? true;

    if (isFirstRun) {
      if (mounted) {
        ShowCaseWidget.of(context)
            .startShowCase([_globalKey, _marketKey, _portfolioKey, _calcKey]);
        await prefs.setBool('first_run_tutorial', false);
      }
    }
  }

  Widget _buildCountrySpecificMarketPage(CountryModel country) {
    return CountryMarketPage(forcedCountry: country);
  }

  Widget _buildActiveIcon(Widget child) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.gold.withValues(alpha: 0.25),
                Colors.transparent,
              ],
              radius: 0.8,
            ),
          ),
        ),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countryProvider = Provider.of<CountryProvider>(context);
    final country = countryProvider.selectedCountry;

    final pages = [
      GoldPage(
        onNavigate: (index) {
          if (_currentIndex != index) {
            _onTabTapped(index);
          }
        },
      ),
      _buildCountrySpecificMarketPage(country),
      const BullionsCoinsPage(),
      const SmartCalculatorsPage(),
      const CurrenciesPage(),
      const FollowUsPage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: pages,
      ),
      bottomNavigationBar: Container(
        height: 85,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 25),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(38),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.white.withValues(alpha: 0.6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 30,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(38),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              selectedItemColor: AppColors.gold,
              unselectedItemColor: isDark ? Colors.white38 : AppColors.mutedText,
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              selectedFontSize: 10.5,
              unselectedFontSize: 10.5,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'Cairo', height: 1.6),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', height: 1.6),
              items: [
                BottomNavigationBarItem(
                  icon: Showcase(
                    key: _globalKey,
                    title: 'home'.tr(),
                    description: 'showcase_home_desc'.tr(),
                    child: const Icon(Icons.home_filled, size: 21),
                  ),
                  activeIcon: _buildActiveIcon(const Icon(Icons.home_filled, size: 24, color: AppColors.gold)),
                  label: 'home'.tr(),
                ),
                BottomNavigationBarItem(
                  icon: Showcase(
                    key: _marketKey,
                    title: country.name.tr(),
                    description: 'showcase_market_desc'.tr(),
                    child: Text(country.flag, style: const TextStyle(fontSize: 18)),
                  ),
                  activeIcon: _buildActiveIcon(Text(country.flag, style: const TextStyle(fontSize: 22))),
                  label: country.name.tr().length > 8 ? country.name.tr().substring(0, 7) : country.name.tr(),
                ),
                BottomNavigationBarItem(
                  icon: Showcase(
                    key: _portfolioKey,
                    title: 'bullions_and_coins'.tr(),
                    description: 'showcase_bullions_desc'.tr(),
                    child: const Icon(Icons.diamond_outlined, size: 21),
                  ),
                  activeIcon: _buildActiveIcon(const Icon(Icons.diamond_rounded, size: 24, color: AppColors.gold)),
                  label: 'bullions'.tr(),
                ),
                BottomNavigationBarItem(
                  icon: Showcase(
                    key: _calcKey,
                    title: 'calculator'.tr(),
                    description: 'showcase_calc_desc'.tr(),
                    child: const Icon(Icons.calculate_outlined, size: 21),
                  ),
                  activeIcon: _buildActiveIcon(const Icon(Icons.calculate_rounded, size: 24, color: AppColors.gold)),
                  label: 'calculator'.tr(),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.currency_exchange_rounded, size: 21),
                  activeIcon: _buildActiveIcon(const Icon(Icons.currency_exchange_rounded, size: 24, color: AppColors.gold)),
                  label: 'currencies'.tr(),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.more_horiz_rounded, size: 21),
                  activeIcon: _buildActiveIcon(const Icon(Icons.more_horiz_rounded, size: 26, color: AppColors.gold)),
                  label: 'more'.tr(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      HapticFeedback.selectionClick();
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) AdService().showInterstitialOnNavigation();
      });
    }
  }
}

