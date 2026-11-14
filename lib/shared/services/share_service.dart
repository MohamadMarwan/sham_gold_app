import 'package:easy_localization/easy_localization.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// خدمة مشاركة الشاشات للتطبيق
/// تتيح للمستخدم مشاركة الأسعار مع الأصدقاء والزملاء
class ShareService {
  static final ScreenshotController screenshotController =
      ScreenshotController();

  /// حساب منطقة الانطلاق المخصصة لـ iOS / iPad لمنع PlatformException
  /// عند انعدام أو فراغ إحداثيات نافذة المشاركة
  static Rect safeShareOrigin(BuildContext? context) {
    if (context != null && context.mounted) {
      try {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
          final origin = box.localToGlobal(Offset.zero) & box.size;
          if (origin.width > 0 && origin.height > 0) {
            return origin;
          }
        }
        final media = MediaQuery.maybeOf(context);
        if (media != null && media.size.width > 0 && media.size.height > 0) {
          return Rect.fromLTWH(0, media.size.height / 2, media.size.width, media.size.height / 2);
        }
      } catch (_) {}
    }
    return const Rect.fromLTWH(0, 100, 300, 300);
  }

  /// مشاركة screenshot مع إضافة نص مخصص
  static Future<void> shareScreenshot({
    required BuildContext context,
    String? customText,
  }) async {
    if (kIsWeb) {
      _showError(context, 'auto_str_041'.tr());
      return;
    }
    final origin = safeShareOrigin(context);
    try {
      // التقاط الصورة
      final Uint8List? imageBytes = await screenshotController.capture(
        pixelRatio: 3.0, // دقة عالية
      );

      if (imageBytes == null) {
        if (context.mounted) {
          _showError(context, 'auto_str_190'.tr());
        }
        return;
      }

      // النص المرافق للمشاركة
      final shareText = customText ??
          '${'auto_str_043'.tr()} ${'auto_str_036'.tr()}\n${DateTime.now().toString().split('.')[0]}';

      // مشاركة الصورة مع النص مع إحداثيات منبثقة آمنة لنظام iOS
      await Share.shareXFiles(
        [
          XFile.fromData(
            imageBytes,
            mimeType: 'image/png',
            name: 'gold_sham_prices_${DateTime.now().millisecondsSinceEpoch}.png'
          )
        ],
        text: shareText,
        subject: 'auto_str_073'.tr(),
        sharePositionOrigin: origin,
      );

      if (context.mounted) {
        _showSuccess(context, 'auto_str_173'.tr());
      }
    } catch (e) {
      debugPrint('ShareService.shareScreenshot error: $e');
      if (context.mounted) {
        _showError(context, 'share_error'.tr());
      }
    }
  }

  /// مشاركة ودجت محدد كصورة بناءً على GlobalKey
  static Future<void> shareWidgetAsImage({
    required BuildContext context,
    required GlobalKey widgetKey,
    String? customText,
  }) async {
    if (kIsWeb) {
      _showError(context, 'auto_str_041'.tr());
      return;
    }
    final origin = safeShareOrigin(context);
    try {
      final boundary = widgetKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (context.mounted) _showError(context, 'auto_str_190'.tr());
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List? imageBytes = byteData?.buffer.asUint8List();

      if (imageBytes == null) {
        if (context.mounted) _showError(context, 'auto_str_190'.tr());
        return;
      }

      final shareText = customText ??
          '${'auto_str_043'.tr()} ${'auto_str_036'.tr()}\n${DateTime.now().toString().split('.')[0]}';

      await Share.shareXFiles(
        [
          XFile.fromData(
            imageBytes,
            mimeType: 'image/png',
            name: 'gold_sham_prices_${DateTime.now().millisecondsSinceEpoch}.png'
          )
        ],
        text: shareText,
        subject: 'auto_str_073'.tr(),
        sharePositionOrigin: origin,
      );

      if (context.mounted) {
        _showSuccess(context, 'auto_str_173'.tr());
      }
    } catch (e) {
      debugPrint('ShareService.shareWidgetAsImage error: $e');
      if (context.mounted) {
        _showError(context, 'share_error'.tr());
      }
    }
  }

  /// مشاركة نص فقط (بدون صورة)
  static Future<void> shareText({
    required String text,
    String? subject,
    BuildContext? context,
  }) async {
    try {
      await Share.share(
        text,
        subject: subject ?? 'auto_str_193'.tr(),
        sharePositionOrigin: safeShareOrigin(context),
      );
    } catch (e) {
      debugPrint('خطأ في المشاركة: $e');
    }
  }

  /// مشاركة سعر محدد
  static Future<void> sharePriceItem({
    required BuildContext context,
    required String itemName,
    required double buyPrice,
    required double sellPrice,
    String? currency,
  }) async {
    final curr = currency ?? 'auto_str_381'.tr();
    final content = '''
$itemName
• ${'buy_price'.tr()}: ${buyPrice.toStringAsFixed(0)} $curr
• ${'sell_price'.tr()}: ${sellPrice.toStringAsFixed(0)} $curr

${DateTime.now().toString().split('.')[0]}''';

    await ShareService.shareText(text: content, context: context);

    if (context.mounted) {
      _showSuccess(context, 'auto_str_137'.tr());
    }
  }

  /// عرض رسالة نجاح
  static void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// عرض رسالة خطأ
  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// زر مشاركة عائم (Floating Action Button)
  static Widget buildShareFAB({
    required BuildContext context,
    required VoidCallback onPressed,
  }) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: const Color(0xFFD4AF37), // لون ذهبي
      icon: const Icon(Icons.share_rounded, color: Colors.white),
      label: Text(
        'auto_str_344'.tr(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevation: 6,
      heroTag: 'share_fab',
    );
  }

  /// زر مشاركة صغير (IconButton)
  static Widget buildShareIconButton({
    required VoidCallback onPressed,
    Color? color,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        Icons.share_rounded,
        color: color ?? const Color(0xFFD4AF37),
      ),
      tooltip: 'auto_str_344'.tr(),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      splashRadius: 24,
    );
  }
}
