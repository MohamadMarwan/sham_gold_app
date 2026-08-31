import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gold_sham/core/constants/app_colors.dart';
import 'package:gold_sham/features/home/presentation/pages/home_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: "أسعار بلمسة واحدة",
      description: "اضغط على أيقونة الحاسبة بجانب أي عملة لمعرفة القيمة الفورية بدون الحاجة لمغادرة الصفحة.",
      icon: Icons.calculate_rounded,
      color: AppColors.gold,
    ),
    OnboardingContent(
      title: "رتب ما يهمك أولاً",
      description: "في قسم المفضلة، اضغط مطولاً واسحب العملات أو عيارات الذهب لترتيبها حسب اهتمامك.",
      icon: Icons.touch_app_rounded,
      color: Colors.greenAccent,
    ),
    OnboardingContent(
      title: "سوقك المحلي بذكاء",
      description: "يقوم التطبيق أوتوماتيكياً بعرض أسعار الذهب والعملات بناءً على تسعيرة السوق المحلي لبلدك بدقة واحترافية.",
      icon: Icons.public_rounded,
      color: Colors.blueAccent,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF071F19) : Colors.white,
      body: Stack(
        children: [
          // Background Gradient
          if (isDark)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.darkGreen, Color(0xFF051310)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          
          SafeArea(
            child: Column(
              children: [
                // Top Skip Button
                Align(
                  alignment: Alignment.topLeft,
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'تخطي',
                      style: GoogleFonts.cairo(
                        color: isDark ? Colors.white54 : AppColors.mutedText,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                      HapticFeedback.selectionClick();
                    },
                    itemCount: _contents.length,
                    itemBuilder: (context, index) {
                      return _buildPageContent(_contents[index], isDark);
                    },
                  ),
                ),

                // Bottom Indicators and Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Indicators
                      Row(
                        children: List.generate(
                          _contents.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 6),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? AppColors.gold
                                  : (isDark ? Colors.white24 : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      // Next/Done Button
                      InkWell(
                        onTap: () {
                          if (_currentPage == _contents.length - 1) {
                            _completeOnboarding();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: EdgeInsets.symmetric(
                            horizontal: _currentPage == _contents.length - 1 ? 32 : 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.gold, Color(0xFFE5B05C)],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentPage == _contents.length - 1 ? 'ابدأ الآن' : 'التالي',
                                style: GoogleFonts.cairo(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              if (_currentPage != _contents.length - 1) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, color: Colors.black87, size: 20),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(OnboardingContent content, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Box
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: content.color.withValues(alpha: 0.1),
              border: Border.all(color: content.color.withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(content.icon, size: 80, color: content.color),
          ),
          const SizedBox(height: 60),
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.darkGreen,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            content.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppColors.mutedText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingContent {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
