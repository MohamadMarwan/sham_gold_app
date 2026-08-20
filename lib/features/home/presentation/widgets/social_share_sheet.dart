import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/country_provider.dart';
import '../../../../shared/models/country_model.dart';
import 'social_share_card.dart';

class SocialShareSheet extends StatefulWidget {
  final CountryModel? forcedCountry;
  const SocialShareSheet({super.key, this.forcedCountry});

  static void show(BuildContext context, {CountryModel? forcedCountry}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SocialShareSheet(forcedCountry: forcedCountry),
    );
  }

  @override
  State<SocialShareSheet> createState() => _SocialShareSheetState();
}

class _SocialShareSheetState extends State<SocialShareSheet> {
  final ScreenshotController _screenshotController = ScreenshotController();
  ShareCardFormat _selectedFormat = ShareCardFormat.square;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countryProvider = Provider.of<CountryProvider>(context);
    final country = widget.forcedCountry ?? countryProvider.selectedCountry;
    final marketData = countryProvider.currentMarketData;

    final List<dynamic> items = (marketData != null && marketData['items'] != null)
        ? marketData['items']
        : [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 14, bottom: 8),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_rounded, color: AppColors.gold, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'auto_str_103'.tr(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.primaryText,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        'سوق ${country.name.tr()} • تصميم فاخر عالي الدقة',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.mutedText),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Format Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildFormatButton(
                    format: ShareCardFormat.square,
                    title: 'auto_str_215'.tr(),
                    subtitle: 'auto_str_111'.tr(),
                    icon: Icons.crop_square_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFormatButton(
                    format: ShareCardFormat.story,
                    title: 'auto_str_188'.tr(),
                    subtitle: 'auto_str_128'.tr(),
                    icon: Icons.stay_current_portrait_rounded,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 16),

          // Live Preview Area
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SocialShareCard(
                    country: country,
                    items: items,
                    format: _selectedFormat,
                  ),
                ),
              ),
            ),
          ),

          // Action Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : () => _shareCardAsImage(country, items),
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                label: Text(
                  _isExporting ? 'auto_str_090'.tr() : 'auto_str_102'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    fontFamily: 'Cairo',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatButton({
    required ShareCardFormat format,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedFormat == format;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFormat = format);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.gold : const Color(0xFFCBD5E1),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.gold : AppColors.mutedText, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: isSelected ? AppColors.gold : AppColors.primaryText,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 9.5,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareCardAsImage(CountryModel country, List<dynamic> items) async {
    setState(() => _isExporting = true);
    HapticFeedback.mediumImpact();

    try {
      final imageBytes = await _screenshotController.captureFromWidget(
        Material(
          color: Colors.transparent,
          child: SocialShareCard(
            country: country,
            items: items,
            format: _selectedFormat,
          ),
        ),
        pixelRatio: 3.0,
        delay: const Duration(milliseconds: 150),
      );

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final xFile = XFile.fromData(
        imageBytes,
        mimeType: 'image/png',
        name: 'gold_sham_bulletin_$timestamp.png',
      );

      if (mounted) {
        await Share.shareXFiles(
          [xFile],
          text: 'auto_str_020'.tr(),
        );
      }
    } catch (e) {
      debugPrint('Error sharing price card: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تصدير الصورة: $e', style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}
