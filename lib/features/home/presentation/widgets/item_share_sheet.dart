import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/country_provider.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/widgets/price_chart_widget.dart';
import 'luxury_item_card.dart';
import 'social_share_card.dart';

class ItemShareSheet extends ConsumerStatefulWidget {
  final PriceItem item;
  final List<PriceHistoryPoint> history;

  const ItemShareSheet({
    super.key,
    required this.item,
    this.history = const [],
  });

  static void show(
    BuildContext context, {
    required PriceItem item,
    List<PriceHistoryPoint> history = const [],
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ItemShareSheet(item: item, history: history),
    );
  }

  @override
  ConsumerState<ItemShareSheet> createState() => _ItemShareSheetState();
}

class _ItemShareSheetState extends ConsumerState<ItemShareSheet> {
  final ScreenshotController _screenshotController = ScreenshotController();
  ShareCardFormat _selectedFormat = ShareCardFormat.square;
  bool _isExporting = false;

  Future<void> _exportAndShare() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);
    HapticFeedback.mediumImpact();

    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        pixelRatio: 3.0,
        delay: const Duration(milliseconds: 150),
      );

      if (imageBytes == null) {
        throw Exception('Failed to capture card image');
      }

      if (kIsWeb) {
        await Share.shareXFiles(
          [
            XFile.fromData(
              imageBytes,
              mimeType: 'image/png',
              name: 'gold_sham_${widget.item.id}_${DateTime.now().millisecondsSinceEpoch}.png',
            )
          ],
          text: '${widget.item.translatedTitle} - ${'app_name'.tr()}',
        );
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = await File(
          '${tempDir.path}/gold_sham_${widget.item.id}_${DateTime.now().millisecondsSinceEpoch}.png',
        ).create();
        await file.writeAsBytes(imageBytes);

        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'image/png')],
          text: 'share_item_latest_price'.tr(args: [widget.item.translatedTitle]),
          subject: widget.item.translatedTitle,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
                const SizedBox(width: 10),
                Text(
                  'auto_str_173'.tr(), // تم المشاركة بنجاح!
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: AppColors.darkGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'share_error'.tr(args: [e.toString()]),
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countryState = ref.watch(countryProvider);
    final country = countryState.selectedCountry;

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
                  child: const Icon(Icons.image_outlined, color: AppColors.gold, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'export_price_card'.tr(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.primaryText,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        widget.item.translatedTitle,
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
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Format selector pills (Story vs Square)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: _buildFormatButton(
                    format: ShareCardFormat.square,
                    label: 'card_format_square'.tr(),
                    icon: Icons.crop_square_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFormatButton(
                    format: ShareCardFormat.story,
                    label: 'card_format_story'.tr(),
                    icon: Icons.stay_current_portrait_rounded,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Card Live Preview Area
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Screenshot(
                    controller: _screenshotController,
                    child: LuxuryItemCard(
                      item: widget.item,
                      country: country,
                      history: widget.history,
                      format: _selectedFormat,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : _exportAndShare,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.darkGreen,
                            ),
                          )
                        : const Icon(Icons.share_rounded, size: 20),
                    label: Text(
                      _isExporting ? 'preparing_image'.tr() : 'share_card'.tr(),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.darkGreen,
                      disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatButton({
    required ShareCardFormat format,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedFormat == format;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFormat = format);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withValues(alpha: 0.15)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.gold : AppColors.mutedText,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.darkGreen)
                    : AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
