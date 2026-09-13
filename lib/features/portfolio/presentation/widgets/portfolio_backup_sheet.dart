import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/portfolio_provider.dart';

class PortfolioBackupSheet extends StatefulWidget {
  final PortfolioProvider portfolio;

  const PortfolioBackupSheet({
    super.key,
    required this.portfolio,
  });

  static Future<void> show(BuildContext context, {required PortfolioProvider portfolio}) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PortfolioBackupSheet(portfolio: portfolio),
    );
  }

  @override
  State<PortfolioBackupSheet> createState() => _PortfolioBackupSheetState();
}

class _PortfolioBackupSheetState extends State<PortfolioBackupSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _restoreController = TextEditingController();
  bool _replaceEntire = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _restoreController.dispose();
    super.dispose();
  }

  Future<void> _shareBackupFile() async {
    HapticFeedback.mediumImpact();
    final jsonStr = widget.portfolio.exportBackupJson();
    final bytes = utf8.encode(jsonStr);
    final fileName = 'sham_gold_portfolio_backup_${DateTime.now().millisecondsSinceEpoch}.json';

    await Share.shareXFiles(
      [
        XFile.fromData(
          Uint8List.fromList(bytes),
          mimeType: 'application/json',
          name: fileName,
        ),
      ],
      text: 'نسخة احتياطية لمحفظة الذهب - تطبيق شام جولد\n${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
      subject: 'portfolio_backup_title'.tr(),
    );
  }

  void _copyBackupCode() {
    HapticFeedback.selectionClick();
    final jsonStr = widget.portfolio.exportBackupJson();
    Clipboard.setData(ClipboardData(text: jsonStr));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('portfolio_backup_code_copied'.tr(), style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppColors.liveGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    HapticFeedback.selectionClick();
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _restoreController.text = data.text!;
      });
    }
  }

  Future<void> _executeRestore() async {
    final text = _restoreController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final count = await widget.portfolio.importBackupJson(text, replace: _replaceEntire);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${'portfolio_backup_restore_success'.tr()} ($count ${'auto_str_081'.tr()})',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.liveGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('portfolio_backup_invalid_code'.tr(), style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final portfolio = widget.portfolio;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceRaised : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: isDark ? 0.2 : 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.cloud_sync_rounded, color: AppColors.gold, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'portfolio_backup_title'.tr(),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark ? Colors.white70 : const Color(0xFF64748B),
                  labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 13),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: [
                    Tab(text: 'portfolio_backup_export_tab'.tr()),
                    Tab(text: 'portfolio_backup_restore_tab'.tr()),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Tab Content
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Export
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'portfolio_backup_desc'.tr(),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Backup Stats Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    portfolio.items.length.toString(),
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    'portfolio_statement_total_items'.tr(),
                                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.mutedText),
                                  ),
                                ],
                              ),
                              Container(width: 1, height: 36, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                              Column(
                                children: [
                                  Text(
                                    '${portfolio.totalPureWeightGrams.toStringAsFixed(1)} g',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                  Text(
                                    'portfolio_pure_gold_weight'.tr(),
                                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.mutedText),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Action 1: Share JSON File
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: portfolio.items.isEmpty ? null : _shareBackupFile,
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: Text(
                              'portfolio_backup_share_file'.tr(),
                              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Action 2: Copy Code
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: portfolio.items.isEmpty ? null : _copyBackupCode,
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: Text(
                              'portfolio_backup_copy_code'.tr(),
                              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
                              side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // Tab 2: Restore
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'portfolio_backup_paste_hint'.tr(),
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _pasteFromClipboard,
                              icon: const Icon(Icons.paste_rounded, size: 15),
                              label: const Text('لصق من الحافظة', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        TextField(
                          controller: _restoreController,
                          maxLines: 4,
                          style: const TextStyle(fontFamily: 'Courier', fontSize: 11),
                          decoration: InputDecoration(
                            hintText: '{"app": "Gold Sham", "items": [...]}',
                            hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5), fontSize: 11),
                            filled: true,
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Restore Options (Merge vs Replace)
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _replaceEntire = false);
                                },
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      Icon(
                                        !_replaceEntire ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                                        color: !_replaceEntire ? AppColors.gold : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'portfolio_backup_restore_merge'.tr(),
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 12,
                                            fontWeight: !_replaceEntire ? FontWeight.bold : FontWeight.w600,
                                            color: !_replaceEntire
                                                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                                : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                              InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _replaceEntire = true);
                                },
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _replaceEntire ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                                        color: _replaceEntire ? AppColors.gold : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'portfolio_backup_restore_replace'.tr(),
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 12,
                                            fontWeight: _replaceEntire ? FontWeight.bold : FontWeight.w600,
                                            color: _replaceEntire
                                                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                                : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _executeRestore,
                            icon: _isLoading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.cloud_download_rounded, size: 18),
                            label: Text(
                              'portfolio_backup_restore_btn'.tr(),
                              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
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
}
