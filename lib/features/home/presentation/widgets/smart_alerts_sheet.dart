import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/smart_alert_service.dart';
import '../../../../shared/models/price_item.dart';

class SmartAlertsSheet extends StatefulWidget {
  final PriceItem? preselectedItem;
  const SmartAlertsSheet({super.key, this.preselectedItem});

  static void show(BuildContext context, {PriceItem? preselectedItem}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SmartAlertsSheet(preselectedItem: preselectedItem),
    );
  }

  @override
  State<SmartAlertsSheet> createState() => _SmartAlertsSheetState();
}

class _SmartAlertsSheetState extends State<SmartAlertsSheet> {
  final SmartAlertService _alertService = SmartAlertService();
  final TextEditingController _targetPriceController = TextEditingController();
  AlertType _selectedType = AlertType.targetPrice;
  bool _isAbove = true;
  double _volatilityPercent = 1.0;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedItem != null) {
      _targetPriceController.text =
          widget.preselectedItem!.buyPrice.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _targetPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = widget.preselectedItem;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                  child: const Icon(Icons.notifications_active_rounded,
                      color: AppColors.gold, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'التنبيهات السعرية الذكية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.primaryText,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        item != null
                            ? 'إعداد تنبيه خاص بـ: ${item.title}'
                            : 'تنبيهات فورية عند وصول السعر أو التذبذب',
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
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.mutedText),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: AnimatedBuilder(
              animation: _alertService,
              builder: (context, _) {
                final rules = _alertService.rules;

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    // New Alert Form Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.add_alert_rounded,
                                  color: AppColors.gold, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'إنشاء تنبيه جديد',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Type Selector
                          Row(
                            children: [
                              _buildTypeChip(
                                  AlertType.targetPrice, 'سعر مستهدف 🎯'),
                              const SizedBox(width: 8),
                              _buildTypeChip(
                                  AlertType.volatility, 'تذبذب حاد ⚡'),
                              const SizedBox(width: 8),
                              _buildTypeChip(
                                  AlertType.dipBuying, 'ارتداد وقاع 💎'),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Dynamic fields based on type
                          if (_selectedType == AlertType.targetPrice) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _targetPriceController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'السعر المستهدف',
                                      labelStyle: const TextStyle(
                                          fontFamily: 'Cairo', fontSize: 13),
                                      suffixText: item?.currency ?? 'USD',
                                      filled: true,
                                      fillColor: isDark
                                          ? Colors.white
                                              .withValues(alpha: 0.05)
                                          : Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SegmentedButton<bool>(
                                  segments: const [
                                    ButtonSegment(
                                        value: true, label: Text('أعلى ↗️')),
                                    ButtonSegment(
                                        value: false, label: Text('أدنى ↘️')),
                                  ],
                                  selected: {_isAbove},
                                  onSelectionChanged: (set) =>
                                      setState(() => _isAbove = set.first),
                                  style: ButtonStyle(
                                    textStyle: WidgetStateProperty.all(
                                      const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else if (_selectedType == AlertType.volatility) ...[
                            Text(
                              'نسبة التغير للتنبيه: ${_volatilityPercent.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                            Slider(
                              value: _volatilityPercent,
                              min: 0.5,
                              max: 5.0,
                              divisions: 9,
                              activeColor: AppColors.gold,
                              label:
                                  '${_volatilityPercent.toStringAsFixed(1)}%',
                              onChanged: (val) =>
                                  setState(() => _volatilityPercent = val),
                            ),
                          ] else ...[
                            const Text(
                              'سيتم رصد موجات الهبوط المتتالية وتنبيهك فور ظهور إشارة ارتداد وصعود لشراء القاع.',
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: AppColors.mutedText),
                            ),
                          ],

                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _addNewAlert,
                              icon: const Icon(Icons.check_circle_outline,
                                  color: Colors.white, size: 18),
                              label: const Text(
                                'تفعيل وحفظ التنبيه',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Cairo'),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.darkGreen,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'التنبيهات المفعلة الحالية',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo'),
                    ),
                    const SizedBox(height: 12),

                    if (rules.isEmpty) ...[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              Icon(Icons.notifications_off_outlined,
                                  size: 40,
                                  color:
                                      AppColors.mutedText.withValues(alpha: 0.5)),
                              const SizedBox(height: 8),
                              const Text(
                                'لا توجد تنبيهات مفعلة حالياً',
                                style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color: AppColors.mutedText,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      ...rules.map((rule) => _buildRuleItem(rule, isDark)),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(AlertType type, String label) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.gold : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              fontFamily: 'Cairo',
              color: isSelected ? Colors.white : AppColors.mutedText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(SmartAlertRule rule, bool isDark) {
    String typeLabel = 'سعر مستهدف';
    if (rule.type == AlertType.volatility) typeLabel = 'تذبذب > ${rule.volatilityThresholdPercent}%';
    if (rule.type == AlertType.dipBuying) typeLabel = 'ارتداد وقاع';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rule.isEnabled ? AppColors.gold.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            rule.type == AlertType.targetPrice ? Icons.gps_fixed_rounded : Icons.bolt_rounded,
            color: rule.isEnabled ? AppColors.gold : AppColors.mutedText,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    fontFamily: 'Cairo',
                    color: rule.isEnabled ? (isDark ? Colors.white : AppColors.primaryText) : AppColors.mutedText,
                  ),
                ),
                Text(
                  typeLabel,
                  style: const TextStyle(fontSize: 11, color: AppColors.mutedText, fontFamily: 'Cairo'),
                ),
              ],
            ),
          ),
          Switch(
            value: rule.isEnabled,
            onChanged: (_) => _alertService.toggleRule(rule.id),
            activeTrackColor: AppColors.gold.withOpacity(0.5),
            activeThumbColor: AppColors.gold,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
            onPressed: () => _alertService.removeRule(rule.id),
          ),
        ],
      ),
    );
  }

  void _addNewAlert() async {
    final item = widget.preselectedItem;
    final targetPrice = double.tryParse(_targetPriceController.text) ?? 0.0;

    final rule = SmartAlertRule(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      priceItemId: item?.id ?? 'xau_usd',
      title: item != null ? item.title : 'الذهب العالمي',
      type: _selectedType,
      targetPrice: targetPrice,
      isAbove: _isAbove,
      volatilityThresholdPercent: _volatilityPercent,
      isEnabled: true,
      createdAt: DateTime.now(),
    );

    HapticFeedback.mediumImpact();
    await _alertService.addRule(rule);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم تفعيل التنبيه الذكي بنجاح 🔔', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.darkGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}
