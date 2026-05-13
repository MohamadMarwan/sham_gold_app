import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../core/constants/app_colors.dart';
import 'gold_page.dart';
import 'syria_market_page.dart';
import 'currencies_page.dart';
import 'turkish_gold_page_enhanced.dart';
import 'calculator_page.dart'; // Re-import calculator
import 'follow_us_page.dart';
import 'price_detail_page.dart';
import '../../../../shared/widgets/syrian_flag.dart';
import 'splash_page.dart';
import '../../../../core/services/ad_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  DateTime? _pausedTime;

  final GlobalKey _globalKey = GlobalKey();
  final GlobalKey _syriaKey = GlobalKey();
  final GlobalKey _calcKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstRun();
      _setupAlertListener();
    });
  }

  @override
  void dispose() {
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
        // If the app was in the background for more than 5 minutes
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

    // 1. Listen for Price Alerts (Specific to device)
    priceService.alertTriggeredStream.listen((data) {
      if (mounted) {
        HapticFeedback.vibrate();
        _showProfessionalSnack(
          title: data['title'] ?? 'تنبيه السعر',
          body: data['body'] ?? '',
          icon: Icons.notifications_active,
          action: SnackBarAction(
            label: 'رؤية',
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

    // 2. Listen for General Broadcast Notifications
    priceService.notificationStream.listen((data) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        _showProfessionalSnack(
          title: data['title'] ?? 'إشعار غولد شام',
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
                          color: Colors.white)),
                  Text(body,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.2),
                          fontWeight: FontWeight.w600)),
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
            .startShowCase([_globalKey, _syriaKey, _calcKey]);
        await prefs.setBool('first_run_tutorial', false);
      }
    }
  }

  // Dynamic page builder based on settings
  Widget _buildFourthPage(String mode) {
    if (mode == 'calculator') {
      return const CalculatorPage();
    }
    return const TurkishGoldPageEnhanced(); // premium enhanced design
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceService = Provider.of<PriceService>(context);
    final settings = priceService.currentSettings;
    final fourthPageMode =
        settings?['displaySettings']?['fourthPageMode'] ?? 'turkish_gold';

    final pages = [
      GoldPage(
        onNavigate: (index) {
          if (_currentIndex != index) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = index);
          }
        },
      ),
      const SyriaMarketPage(),
      const CurrenciesPage(),
      _buildFourthPage(fourthPageMode),
      const FollowUsPage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: pages[_currentIndex],
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterFloat,
      bottomNavigationBar: Container(
        height: 85,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkGreen.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, 15),
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                if (_currentIndex != index) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentIndex = index);
                  // إظهار إعلان بيني عند التنقل (بناءً على إعدادات الباكند)
                  AdService().showInterstitialOnNavigation();
                }
              },
              selectedItemColor: AppColors.darkGreen,
              unselectedItemColor:
                  isDark ? Colors.white38 : AppColors.mutedText,
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w900, height: 1.8),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w700, height: 1.8),
              items: [
                BottomNavigationBarItem(
                  icon: Showcase(
                    key: _globalKey,
                    title: 'الذهب العالمي',
                    description:
                        'تابع أسعار الذهب العالمية بالدولار لحظة بلحظة',
                    child: const Icon(Icons.public_rounded, size: 22),
                  ),
                  activeIcon: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.public_rounded, size: 26),
                      const SizedBox(height: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  label: 'العالمي',
                ),
                BottomNavigationBarItem(
                  icon: Showcase(
                    key: _syriaKey,
                    title: 'أسواق سوريا',
                    description:
                        'أسعار الذهب والعملات في السوق المحلي (الحقيقي)',
                    child: const SyrianFlag(width: 24, height: 14),
                  ),
                  activeIcon: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SyrianFlag(width: 28, height: 18),
                      const SizedBox(height: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  label: 'سوريا',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.currency_exchange_rounded, size: 22),
                  activeIcon: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.currency_exchange_rounded, size: 26),
                      const SizedBox(height: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  label: 'العملات',
                ),
                BottomNavigationBarItem(
                  icon: Showcase(
                    key: _calcKey,
                    title: fourthPageMode == 'calculator' ? 'الحاسبة' : 'تركيا',
                    description: fourthPageMode == 'calculator'
                        ? 'احسب قيمة مدخراتك بدقة'
                        : 'أسعار الذهب في تركيا (ليرة تركية)',
                    child: fourthPageMode == 'calculator'
                        ? const Icon(Icons.calculate_rounded, size: 22)
                        : const Text('🇹🇷', style: TextStyle(fontSize: 20)),
                  ),
                  activeIcon: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      fourthPageMode == 'calculator'
                          ? const Icon(Icons.calculate_rounded, size: 26)
                          : const Text('🇹🇷', style: TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  label: fourthPageMode == 'calculator' ? 'الحاسبة' : 'تركيا',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.contact_support_rounded, size: 22),
                  activeIcon: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.contact_support_rounded, size: 26),
                      const SizedBox(height: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  label: 'تواصل',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
