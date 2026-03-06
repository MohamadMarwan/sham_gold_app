import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../shared/widgets/premium_logo.dart';
import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';

class FollowUsPage extends StatefulWidget {
  const FollowUsPage({super.key});

  @override
  State<FollowUsPage> createState() => _FollowUsPageState();
}

class _FollowUsPageState extends State<FollowUsPage> {
  @override
  Widget build(BuildContext context) {
    final priceService = Provider.of<PriceService>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<Map<String, dynamic>>(
        stream: priceService.settingsStream,
        initialData: priceService.currentSettings,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return _buildLoadingState();
          }

          final settings = snapshot.data!;
          final links = settings['socialLinks'] as Map<String, dynamic>? ?? {};

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildPremiumHeader(settings),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 160),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader('قنواتنا الرسمية'),
                    const SizedBox(height: 20),
                    _buildSocialCard(
                      'فيسبوك',
                      'تابع آخر الأخبار والمنشورات الرسمية',
                      Icons.facebook_rounded,
                      const Color(0xFF1877F2),
                      links['facebook'],
                    ),
                    _buildSocialCard(
                      'قناتنا على واتساب',
                      'اشترك ليصلك كل جديد عبر الواتساب',
                      Icons.campaign_rounded,
                      const Color(0xFF25D366),
                      links['whatsapp_channel'] ?? links['whatsapp'],
                    ),
                    _buildSocialCard(
                      'تيليجرام',
                      'اشترك في القناة ليصلك كل جديد فوراً',
                      Icons.send_rounded,
                      const Color(0xFF0088CC),
                      links['telegram'],
                    ),
                    _buildSocialCard(
                      'انستغرام',
                      'شاهد صور وجولات حصرية لمنتجاتنا',
                      Icons.camera_alt_rounded,
                      const Color(0xFFE1306C),
                      links['instagram'],
                    ),
                    _buildSocialCard(
                      'الموقع الإلكتروني',
                      'زر موقعنا الرسمي لمزيد من الخدمات',
                      Icons.language_rounded,
                      AppColors.darkGreen,
                      links['website'],
                    ),
                    const SizedBox(height: 30),
                    _buildSupportInfo(),
                    const SizedBox(height: 30),
                    _buildPromotionSection(),
                    const SizedBox(height: 40),
                    _buildLegalLinks(),
                    const SizedBox(height: 40),
                    _buildDeveloperInfo(),
                    const SizedBox(height: 30),
                    Center(
                      child: Text(
                        'إصدار النسخة 2.5.0',
                        style: TextStyle(
                            color: AppColors.mutedText.withValues(alpha: 0.2),
                            fontSize: 9,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.gold, strokeWidth: 3),
          SizedBox(height: 20),
          Text('جاري تحميل الإعدادات والروابط...',
              style: TextStyle(
                  color: AppColors.darkGreen, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(Map<String, dynamic> settings) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.darkGreen,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.darkGreen, Color(0xFF0D2B22)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: -40,
                top: -40,
                child: CircleAvatar(
                  radius: 120,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              Positioned(
                right: 20,
                bottom: 40,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  _buildLogo(settings),
                  const SizedBox(height: 16),
                  Text(
                    settings['appName'] ?? 'غولد شام',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        shadows: [
                          Shadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4))
                        ]),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: const Text(
                      'تواصل معنا عبر منصاتنا الرسمية',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(Map<String, dynamic> settings) {
    return Hero(
      tag: 'app_logo',
      child: PremiumLogo(
        size: 110,
        logoUrl: settings['logoUrl'],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 25,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.darkGreen,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialCard(
      String title, String subtitle, IconData icon, Color color, String? url) {
    if (url == null || url.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('عذراً، لا يمكن فتح هذا الرابط حالياً')),
                );
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.darkGreen),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedText,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.mutedText, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupportInfo() {
    final priceService = Provider.of<PriceService>(context, listen: false);

    if (!priceService.shouldShow('showSupportSection')) {
      return const SizedBox.shrink();
    }

    final title = priceService.getDisplaySetting('supportTitle',
        defaultValue: 'دعم فني وتواصل');
    final subtitle = priceService.getDisplaySetting('supportSubtitle',
        defaultValue:
            'فريقنا متاح للرد على استفساراتكم وملاحظاتكم على مدار الساعة.');
    String supportWhatsapp =
        priceService.getDisplaySetting('supportWhatsapp') ?? '';
    if (supportWhatsapp.trim().isEmpty) {
      supportWhatsapp = priceService.currentSettings?['socialLinks']
              ?['whatsapp'] ??
          'https://wa.me/905524685639';
    }
    final whatsappUrl = supportWhatsapp;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.gold,
                radius: 24,
                child:
                    Icon(Icons.security_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkGreen,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.darkGreen,
                          height: 1.4,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final uri = Uri.parse(whatsappUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('عذراً، لا يمكن فتح واتساب حالياً')),
                  );
                }
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF25D366), width: 1),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.message_rounded,
                      color: Color(0xFF25D366), size: 20),
                  SizedBox(width: 10),
                  Text(
                    'تواصل عبر واتساب',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF25D366),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalLinks() {
    return Column(
      children: [
        const Divider(color: Colors.black12, height: 1),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegalLinkItem('سياسة الخصوصية', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
              );
            }),
            Container(
              height: 14,
              width: 1.5,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.black12,
            ),
            _buildLegalLinkItem('اتفاقية الاستخدام', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildLegalLinkItem(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.darkGreen,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildDeveloperInfo() {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse('https://dev.toiall.com');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Center(
        child: Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.mutedText.withValues(alpha: 0.2),
            ),
            children: const [
              TextSpan(text: 'برمجة وتطوير '),
              TextSpan(
                text: 'toiall',
                style: TextStyle(
                  color: Color(0xFF2196F3),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPromotionSection() {
    const playStoreUrl =
        'https://play.google.com/store/apps/details?id=com.toiall.gold_sham&hl=ar';

    return Column(
      children: [
        _buildSectionHeader('ادعمنا وشاركه'),
        const SizedBox(height: 20),
        Row(
          children: [
            // Rate Us Button
            Expanded(
              child: _buildPromoButton(
                title: 'قيمنا الآن',
                subtitle: 'على متجر Google Play',
                icon: Icons.star_rounded,
                color: Colors.amber.shade700,
                onTap: () async {
                  final uri = Uri.parse(playStoreUrl);
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    debugPrint('Launch error: $e');
                  }
                },
              ),
            ),
            const SizedBox(width: 15),
            // Share App Button
            Expanded(
              child: _buildPromoButton(
                title: 'شارك التطبيق',
                subtitle: 'مع الأصدقاء والعائلة',
                icon: Icons.share_rounded,
                color: Colors.blue.shade600,
                onTap: () {
                  Share.share(
                    'تابع أسعار الذهب والعملات لحظة بلحظة مع تطبيق غولد شام. حمله الآن من متجر بلاي: \n$playStoreUrl',
                    subject: 'تطبيق غولد شام للذهب والعملات',
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPromoButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.mutedText.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
