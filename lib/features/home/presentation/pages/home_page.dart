import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/country_provider.dart';
import '../../../../shared/models/country_model.dart';
import 'gold_page.dart';
import 'currencies_page.dart';
import 'smart_calculators_page.dart';
import 'country_market_page.dart';
import 'follow_us_page.dart';
import '../../../../core/services/ad_service.dart';
import '../../../../core/providers/navigation_provider.dart';
import 'bullions_coins_page.dart';
import '../../../../shared/widgets/ticker_tape_widget.dart';
import '../../../../shared/widgets/country_flag_widget.dart';
import '../../../../core/services/permission_coordinator_service.dart';
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with WidgetsBindingObserver {
  late PageController _pageController;
  DateTime? _pausedTime;
  StreamSubscription? _alertSub;
  StreamSubscription? _notifSub;

  final GlobalKey _globalKey = GlobalKey();
  final GlobalKey _marketKey = GlobalKey();
  final GlobalKey _portfolioKey = GlobalKey();
  final GlobalKey _calcKey = GlobalKey();
  List<_NavTabItem> _activeTabs = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: ref.read(navigationIndexProvider));
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstRun();
      _setupAlertListener();
      PermissionCoordinatorService().checkAndPromptPermissions(context, ref);
    });
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    _notifSub?.cancel();
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
        AdService().showOnResumeAppOpenAd(duration, onAdDismissed: () {
          if (mounted) {
            ref.read(priceServiceProvider).refreshPrices(manual: true);
          }
        });
      } else {
        ref.read(priceServiceProvider).refreshPrices(manual: true);
      }
      _pausedTime = null;
    }
  }

  void _setupAlertListener() {
    final priceService = ref.read(priceServiceProvider);

    _alertSub = priceService.alertTriggeredStream.listen((data) {
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
              context.push(
                '/price-detail',
                extra: {'item': priceItem},
              );
            },
          ),
        );
      }
    });

    _notifSub = priceService.notificationStream.listen((data) {
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

    if (isFirstRun && mounted) {
      final priceService = ref.read(priceServiceProvider);
      final List<GlobalKey> activeKeys = [_globalKey];
      if (priceService.shouldShow('navShowCountryMarket', defaultValue: true)) {
        activeKeys.add(_marketKey);
      }
      if (priceService.shouldShow('navShowBullions', defaultValue: true)) {
        activeKeys.add(_portfolioKey);
      }
      if (priceService.shouldShow('navShowCalculator', defaultValue: true)) {
        activeKeys.add(_calcKey);
      }
      if (activeKeys.isNotEmpty) {
        ShowCaseWidget.of(context).startShowCase(activeKeys);
      }
      await prefs.setBool('first_run_tutorial', false);
    }
  }

  void _handleSmartNavigation(String destinationId, CountryModel country) {
    final targetIndex = _activeTabs.indexWhere((t) => t.id == destinationId);
    if (targetIndex != -1) {
      _onTabTapped(targetIndex);
    } else if (destinationId == 'country_market') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CountryMarketPage(forcedCountry: country)),
      );
    }
  }

  Widget _buildCountrySpecificMarketPage(CountryModel country) {
    return CountryMarketPage(forcedCountry: country);
  }

  Widget _buildActiveIcon(Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutBack,
      builder: (context, scale, childWidget) {
        return Transform.scale(
          scale: scale,
          child: Stack(
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
              childWidget!,
            ],
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceService = ref.watch(priceServiceProvider);
    final countryProviderInstance = ref.watch(countryProvider);
    final country = countryProviderInstance.selectedCountry;

    final List<_NavTabItem> allTabs = [
      _NavTabItem(
        id: 'home',
        showcaseKey: _globalKey,
        page: GoldPage(
          onNavigate: (index) {
            _handleSmartNavigation('country_market', country);
          },
        ),
        barItem: BottomNavigationBarItem(
          icon: Showcase(
            key: _globalKey,
            title: 'home'.tr(),
            description: 'showcase_home_desc'.tr(),
            child: const Icon(Icons.home_filled, size: 21),
          ),
          activeIcon: _buildActiveIcon(const Icon(Icons.home_filled, size: 24, color: AppColors.gold)),
          label: 'home'.tr(),
        ),
      ),
      if (priceService.shouldShow('navShowCountryMarket', defaultValue: true))
        _NavTabItem(
          id: 'country_market',
          showcaseKey: _marketKey,
          page: _buildCountrySpecificMarketPage(country),
          barItem: BottomNavigationBarItem(
            icon: Showcase(
              key: _marketKey,
              title: country.localizedName,
              description: 'showcase_market_desc'.tr(),
              child: CountryFlagWidget(countryCode: country.code, flagEmoji: country.flag, size: 18),
            ),
            activeIcon: _buildActiveIcon(CountryFlagWidget(countryCode: country.code, flagEmoji: country.flag, size: 22)),
            label: country.localizedName,
          ),
        ),
      if (priceService.shouldShow('navShowCurrencies', defaultValue: true))
        _NavTabItem(
          id: 'currencies',
          page: const CurrenciesPage(),
          barItem: BottomNavigationBarItem(
            icon: const Icon(Icons.currency_exchange_rounded, size: 21),
            activeIcon: _buildActiveIcon(const Icon(Icons.currency_exchange_rounded, size: 24, color: AppColors.gold)),
            label: 'currencies'.tr(),
          ),
        ),
      if (priceService.shouldShow('navShowBullions', defaultValue: true))
        _NavTabItem(
          id: 'bullions',
          showcaseKey: _portfolioKey,
          page: const BullionsCoinsPage(),
          barItem: BottomNavigationBarItem(
            icon: Showcase(
              key: _portfolioKey,
              title: 'bullions_and_coins'.tr(),
              description: 'showcase_bullions_desc'.tr(),
              child: const Icon(Icons.diamond_outlined, size: 21),
            ),
            activeIcon: _buildActiveIcon(const Icon(Icons.diamond_rounded, size: 24, color: AppColors.gold)),
            label: 'bullions'.tr(),
          ),
        ),
      if (priceService.shouldShow('navShowCalculator', defaultValue: true))
        _NavTabItem(
          id: 'calculator',
          showcaseKey: _calcKey,
          page: const SmartCalculatorsPage(),
          barItem: BottomNavigationBarItem(
            icon: Showcase(
              key: _calcKey,
              title: 'calculator'.tr(),
              description: 'showcase_calc_desc'.tr(),
              child: const Icon(Icons.calculate_outlined, size: 21),
            ),
            activeIcon: _buildActiveIcon(const Icon(Icons.calculate_rounded, size: 24, color: AppColors.gold)),
            label: 'calculator'.tr(),
          ),
        ),
      if (priceService.shouldShow('navShowMore', defaultValue: true))
        _NavTabItem(
          id: 'more',
          page: const FollowUsPage(),
          barItem: BottomNavigationBarItem(
            icon: const Icon(Icons.more_horiz_rounded, size: 21),
            activeIcon: _buildActiveIcon(const Icon(Icons.more_horiz_rounded, size: 26, color: AppColors.gold)),
            label: 'more'.tr(),
          ),
        ),
    ];

    _activeTabs = allTabs;
    final pages = allTabs.map((t) => t.page).toList();

    // Guard safe index in case an active tab was hidden by admin
    final rawIndex = ref.watch(navigationIndexProvider);
    final safeIndex = rawIndex >= allTabs.length ? 0 : rawIndex;
    if (rawIndex != safeIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(navigationIndexProvider.notifier).state = safeIndex;
          if (_pageController.hasClients) {
            _pageController.jumpToPage(safeIndex);
          }
        }
      });
    }

    return PopScope(
      canPop: safeIndex == 0,
      onPopInvokedWithResult: (didPop, dynamic result) {
        if (didPop) return;
        if (safeIndex != 0) {
          _onTabTapped(0);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBody: true,
        body: Column(
          children: [
            if (priceService.shouldShow('homeShowTickerTape', defaultValue: true))
              const TickerTapeWidget(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  ref.read(navigationIndexProvider.notifier).state = index;
                },
                children: pages,
              ),
            ),
          ],
        ),
        bottomNavigationBar: allTabs.length >= 2
            ? Container(
                height: 85,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 25),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceRaised.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(38),
                  border: Border.all(
                    color: isDark ? AppColors.gold.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.6),
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
                      currentIndex: safeIndex,
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
                      items: allTabs.map((t) => t.barItem).toList(),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  void _onTabTapped(int index) {
    if (ref.read(navigationIndexProvider) != index) {
      ref.read(navigationIndexProvider.notifier).state = index;
      HapticFeedback.selectionClick();
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutQuad,
      );
    }
  }
}

class _NavTabItem {
  final String id;
  final Widget page;
  final BottomNavigationBarItem barItem;
  final GlobalKey? showcaseKey;

  const _NavTabItem({
    required this.id,
    required this.page,
    required this.barItem,
    this.showcaseKey,
  });
}

