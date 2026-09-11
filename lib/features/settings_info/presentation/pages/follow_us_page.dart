import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../shared/widgets/premium_logo.dart';
import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../shared/widgets/premium_card.dart';
import '../../../../shared/widgets/section_header.dart';
class FollowUsPage extends ConsumerStatefulWidget {
  const FollowUsPage({super.key});

  @override
  ConsumerState<FollowUsPage> createState() => _FollowUsPageState();
}

class _FollowUsPageState extends ConsumerState<FollowUsPage> {
  @override
  Widget build(BuildContext context) {
    final priceService = ref.watch(priceServiceProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<Map<String, dynamic>>(
        stream: priceService.settingsStream,
        initialData: priceService.currentSettings,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return _buildLoadingState();
          }

          final settings = snapshot.data!;
          final dynamicLinksRaw = settings['dynamicSocialLinks'];
          final linksRaw = settings['socialLinks'];
          
          final List<dynamic> socialLinksList = (dynamicLinksRaw is List) ? dynamicLinksRaw : ((linksRaw is List) ? linksRaw : []);
          
          // Legacy support or fallback if needed
          final Map<String, dynamic> legacyLinks = (linksRaw is Map) ? Map<String, dynamic>.from(linksRaw) : {};

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildPremiumHeader(settings),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 160),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader('our_channels'.tr()),
                    const SizedBox(height: 20),
                    
                    // Dynamic Social Links from Backend
                    ...socialLinksList.where((item) => item['isEnabled'] != false).map((item) {
                      return _buildSocialCard(
                        item['title'] ?? '',
                        item['subtitle'] ?? '',
                        _getIconData(item['iconName']),
                        _parseColor(item['color']),
                        item['url'],
                      );
                    }),

                    // Fallback for legacy data structure if list is empty
                    if (socialLinksList.isEmpty && legacyLinks.isNotEmpty) ...[
                      _buildSocialCard(
                        'auto_str_342'.tr(),
                        'auto_str_058'.tr(),
                        Icons.facebook_rounded,
                        const Color(0xFF1877F2),
                        legacyLinks['facebook'],
                      ),
                      _buildSocialCard(
                        'auto_str_191'.tr(),
                        'auto_str_069'.tr(),
                        Icons.campaign_rounded,
                        const Color(0xFF25D366),
                        legacyLinks['whatsapp_channel'] ?? legacyLinks['whatsapp'],
                      ),
                      _buildSocialCard(
                        'auto_str_317'.tr(),
                        'auto_str_057'.tr(),
                        Icons.send_rounded,
                        const Color(0xFF0088CC),
                        legacyLinks['telegram'],
                      ),
                      _buildSocialCard(
                        'auto_str_315'.tr(),
                        'auto_str_077'.tr(),
                        Icons.camera_alt_rounded,
                        const Color(0xFFE1306C),
                        legacyLinks['instagram'],
                      ),
                      _buildSocialCard(
                        'auto_str_334'.tr(),
                        'auto_str_078'.tr(),
                        Icons.video_library_rounded,
                        const Color(0xFF000000),
                        legacyLinks['tiktok'],
                      ),
                      _buildSocialCard(
                        'auto_str_184'.tr(),
                        'auto_str_066'.tr(),
                        Icons.language_rounded,
                        AppColors.darkGreen,
                        legacyLinks['website'],
                      ),
                    ],
                    const SizedBox(height: 30),
                    _buildSettingsSection(context),
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
                        'version'.tr(args: ['2.5.0']),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.gold, strokeWidth: 3),
          const SizedBox(height: 20),
          Text('loading_settings'.tr(),
              style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.darkGreen, fontWeight: FontWeight.bold)),
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
                  const SizedBox(height: 10),
                  _buildLogo(settings),
                  const SizedBox(height: 16),
                  Text(
                    (settings['appName'] != null &&
                            settings['appName'].toString().trim().isNotEmpty &&
                            settings['appName'].toString().trim() != 'غولد شام' &&
                            settings['appName'].toString().trim() != 'شام غولد')
                        ? settings['appName'].toString()
                        : 'auto_str_320'.tr(),
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
                    child: Text(
                      'connect_via_platforms'.tr(),
                      style: const TextStyle(
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
    return SectionHeader(
      title: title,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
    );
  }

  Widget _buildSocialCard(
      String title, String subtitle, IconData icon, Color color, String? url) {
    if (url == null || url.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.zero,
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('auto_str_053'.tr())),
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
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.darkGreen),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : AppColors.mutedText,
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
    );
  }

  Widget _buildSupportInfo() {
    final priceService = ref.read(priceServiceProvider);

    if (!priceService.shouldShow('showSupportSection')) {
      return const SizedBox.shrink();
    }

    final rawTitle = priceService.getDisplaySetting('supportTitle') as String?;
    const defaultArTitle = 'دعم فني وتواصل';
    final isDefaultTitle = rawTitle == null ||
        rawTitle.trim().isEmpty ||
        rawTitle.trim() == defaultArTitle ||
        rawTitle.trim() == 'الدعم الفني';
    final title = isDefaultTitle ? 'support_title_default'.tr() : rawTitle.trim();

    final rawSubtitle = priceService.getDisplaySetting('supportSubtitle') as String?;
    const defaultArSubtitle = 'فريقنا متاح للرد على استفساراتكم وملاحظاتكم على مدار الساعة.';
    final isDefaultSubtitle = rawSubtitle == null ||
        rawSubtitle.trim().isEmpty ||
        rawSubtitle.trim() == defaultArSubtitle ||
        rawSubtitle.trim().contains('فريقنا متاح للرد على استفساراتكم') ||
        rawSubtitle.trim() == 'تواصل معنا';
    final subtitle = isDefaultSubtitle ? 'support_subtitle_default'.tr() : rawSubtitle.trim();
    String supportWhatsapp =
        priceService.getDisplaySetting('supportWhatsapp') ?? '';
    if (supportWhatsapp.trim().isEmpty) {
      supportWhatsapp = priceService.currentSettings?['socialLinks']
              ?['whatsapp'] ??
          'https://wa.me/905524685639';
    }
    final whatsappUrl = supportWhatsapp;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PremiumCard(
      padding: const EdgeInsets.all(24),
      margin: EdgeInsets.zero,
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
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.darkGreen,
                          fontFamily: 'Cairo',
                          fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : AppColors.secondaryText,
                          fontFamily: 'Cairo',
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
                    SnackBar(
                        content: Text('cannot_open_whatsapp'.tr())),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.message_rounded,
                      color: Color(0xFF25D366), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'contact_whatsapp'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Divider(color: isDark ? Colors.white24 : Colors.black12, height: 1),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegalLinkItem('privacy_policy'.tr(), () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
              );
            }),
            Container(
              height: 14,
              width: 1.5,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            _buildLegalLinkItem('terms_of_service'.tr(), () {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          title,
          style: TextStyle(
            color: isDark ? AppColors.gold : AppColors.darkGreen,
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
            children: [
              TextSpan(text: '${'developed_by'.tr()} '),
              const TextSpan(
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
        _buildSectionHeader('support_and_share'.tr()),
        const SizedBox(height: 20),
        Row(
          children: [
            // Rate Us Button
            Expanded(
              child: _buildPromoButton(
                title: 'rate_us'.tr(),
                subtitle: 'on_play_store'.tr(),
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
                title: 'share_app'.tr(),
                subtitle: 'with_friends'.tr(),
                icon: Icons.share_rounded,
                color: Colors.blue.shade600,
                onTap: () {
                  Share.share(
                    '${'share_app_text'.tr()} \n$playStoreUrl',
                    subject: 'share_app_subject'.tr(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.darkBorder : color.withValues(alpha: 0.1),
          width: 1.5,
        ),
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
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.darkGreen,
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

  IconData _getIconData(String? name) {
    switch (name) {
      case 'facebook':
        return Icons.facebook_rounded;
      case 'campaign':
        return Icons.campaign_rounded;
      case 'send':
        return Icons.send_rounded;
      case 'camera_alt':
        return Icons.camera_alt_rounded;
      case 'video_library':
        return Icons.video_library_rounded;
      case 'language':
        return Icons.language_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return Colors.black;
    try {
      String hex = hexColor.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.black;
    }
  }

  Widget _buildSettingsSection(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = settings.themeMode == ThemeMode.dark ||
        (settings.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Column(
      children: [
        _buildSectionHeader('settings'.tr()),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: AppColors.gold,
                ),
                title: Text(
                  'dark_mode'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Switch(
                  value: isDark,
                  activeThumbColor: AppColors.gold,
                  onChanged: (val) {
                    settings.setThemeMode(
                        val ? ThemeMode.dark : ThemeMode.light);
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.text_fields_rounded, color: AppColors.gold),
                title: Text(
                  'font_size'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: DropdownButton<double>(
                  value: settings.fontSizeScale,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.gold),
                  items: [
                    DropdownMenuItem(value: 1.0, child: Text('font_normal'.tr())),
                    DropdownMenuItem(value: 1.15, child: Text('font_large'.tr())),
                    DropdownMenuItem(value: 1.3, child: Text('font_xlarge'.tr())),
                  ],
                  onChanged: (double? newValue) {
                    if (newValue != null) {
                      settings.setFontSizeScale(newValue);
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  settings.isGridLayout ? Icons.grid_view_rounded : Icons.view_agenda_rounded,
                  color: AppColors.gold,
                ),
                title: Text(
                  'price_layout_mode'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: DropdownButton<bool>(
                  value: settings.isGridLayout,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.gold),
                  items: [
                    DropdownMenuItem(value: true, child: Text('layout_grid'.tr())),
                    DropdownMenuItem(value: false, child: Text('layout_list'.tr())),
                  ],
                  onChanged: (bool? newValue) {
                    if (newValue != null) {
                      settings.setIsGridLayout(newValue);
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.language_rounded, color: AppColors.gold),
                title: Text(
                  'language'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: DropdownButton<String>(
                  value: context.locale.languageCode,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.gold),
                  items: [
                    DropdownMenuItem(value: 'ar', child: Text('auto_str_330'.tr())),
                    const DropdownMenuItem(value: 'en', child: Text('English')),
                    const DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      context.setLocale(Locale(newValue));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
