import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// خدمة مشاركة الشاشات للتطبيق
/// تتيح للمستخدم مشاركة الأسعار مع الأصدقاء والزملاء
class ShareService {
  static final ScreenshotController screenshotController =
      ScreenshotController();

  /// مشاركة screenshot مع إضافة نص مخصص
  static Future<void> shareScreenshot({
    required BuildContext context,
    String? customText,
  }) async {
    if (kIsWeb) {
      _showError(context, 'المشاركة كصورة غير مدعومة حالياً على المتصفح');
      return;
    }
    try {
      // التقاط الصورة
      final Uint8List? imageBytes = await screenshotController.capture(
        pixelRatio: 3.0, // دقة عالية
      );

      if (imageBytes == null) {
        if (context.mounted) {
          _showError(context, 'فشل التقاط الصورة');
        }
        return;
      }

      // حفظ الصورة في ملف مؤقت
      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/gold_sham_prices_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

      // النص المرافق للمشاركة
      final shareText = customText ??
          '💰 أسعار الذهب والعملات الحية من غولد شام\n'
              '📱 تطبيق غولد شام - أسعار دقيقة ومحدّثة لحظياً\n'
              '⏰ ${DateTime.now().toString().split('.')[0]}';

      // مشاركة الصورة مع النص
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: shareText,
        subject: 'أسعار الذهب والعملات - غولد شام',
      );

      // حذف الملف المؤقت بعد المشاركة
      await imageFile.delete();

      if (context.mounted) {
        _showSuccess(context, 'تم المشاركة بنجاح!');
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'حدث خطأ أثناء المشاركة: ${e.toString()}');
      }
    }
  }

  /// مشاركة نص فقط (بدون صورة)
  static Future<void> shareText({
    required String text,
    String? subject,
  }) async {
    try {
      await Share.share(
        text,
        subject: subject ?? 'من تطبيق غولد شام',
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
    final content = '''
🏆 $itemName
📊 سعر الشراء: ${buyPrice.toStringAsFixed(0)} ${currency ?? 'ل.س'}
💵 سعر المبيع: ${sellPrice.toStringAsFixed(0)} ${currency ?? 'ل.س'}

⏰ ${DateTime.now().toString().split('.')[0]}
📱 تطبيق غولد شام - أسعار دقيقة ومحدّثة
''';

    await ShareService.shareText(text: content);

    if (context.mounted) {
      _showSuccess(context, 'تم مشاركة السعر بنجاح!');
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
      label: const Text(
        'مشاركة',
        style: TextStyle(
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
      tooltip: 'مشاركة',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      splashRadius: 24,
    );
  }
}
