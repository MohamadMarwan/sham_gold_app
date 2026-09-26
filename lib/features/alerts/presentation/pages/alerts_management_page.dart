import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/premium_empty_state.dart';
import '../../../../shared/widgets/premium_card.dart';
import '../../../../shared/widgets/banner_placement_widget.dart';
import '../../../../core/services/smart_alert_service.dart';

class AlertsManagementPage extends ConsumerStatefulWidget {
  const AlertsManagementPage({super.key});

  @override
  ConsumerState<AlertsManagementPage> createState() => _AlertsManagementPageState();
}

class _AlertsManagementPageState extends ConsumerState<AlertsManagementPage> {
  final SmartAlertService _alertService = SmartAlertService();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _deleteAlert(String id) async {
    HapticFeedback.mediumImpact();
    await _alertService.removeRule(id);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('auto_str_206'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: isDark ? AppColors.darkScaffold : AppColors.darkGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimatedBuilder(
        animation: _alertService,
        builder: (context, _) {
          final rules = _alertService.rules;
          return Column(
            children: [
              const BannerPlacementWidget(
                location: 'alerts_top',
                fallbackLocations: ['home_top'],
                margin: EdgeInsets.fromLTRB(16, 12, 16, 8),
              ),
              Expanded(
                child: rules.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: rules.length,
                        itemBuilder: (context, index) {
                          final rule = rules[index];
                          return _buildRuleCard(rule, isDark);
                        },
                      ),
              ),
              const BannerPlacementWidget(
                location: 'alerts_bottom',
                fallbackLocations: ['home_bottom'],
                margin: EdgeInsets.fromLTRB(16, 8, 16, 16),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRuleCard(SmartAlertRule rule, bool isDark) {
    String conditionText = '';
    String displayValue = '';

    if (rule.type == AlertType.targetPrice) {
      conditionText = rule.isAbove ? 'auto_str_326'.tr() : 'auto_str_337'.tr();
      displayValue = rule.targetPrice.toString();
    } else if (rule.type == AlertType.volatility) {
      conditionText = 'auto_str_275'.tr();
      displayValue = '${rule.volatilityThresholdPercent}%';
    } else if (rule.type == AlertType.dipBuying) {
      conditionText = 'auto_str_248'.tr();
      displayValue = 'auto_str_273'.tr();
    }

    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              rule.type == AlertType.targetPrice ? Icons.gps_fixed_rounded : Icons.bolt_rounded,
              color: rule.isEnabled ? AppColors.gold : AppColors.mutedText,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16,
                      color: rule.isEnabled ? (isDark ? Colors.white : AppColors.primaryText) : AppColors.mutedText,
                  ),
                ),
                if (rule.type == AlertType.targetPrice)
                  Text(
                    'alert_condition_text'.tr(args: [conditionText, displayValue]),
                    style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
                  )
                else
                  Text(
                    displayValue,
                    style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
                  ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('yyyy/MM/dd HH:mm').format(rule.createdAt.toLocal()),
                  style: TextStyle(color: Colors.grey[400], fontSize: 10),
                ),
              ],
            ),
          ),
          Switch(
            value: rule.isEnabled,
            onChanged: (_) => _alertService.toggleRule(rule.id),
            activeTrackColor: AppColors.gold.withValues(alpha: 0.5),
            activeThumbColor: AppColors.gold,
          ),
          IconButton(
            onPressed: () => _deleteAlert(rule.id),
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return PremiumEmptyState(
      title: 'auto_str_100'.tr(),
      subtitle: 'auto_str_037'.tr(),
      icon: Icons.notifications_none_rounded,
    );
  }
}
