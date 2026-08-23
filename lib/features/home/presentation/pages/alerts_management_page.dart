import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../shared/widgets/premium_empty_state.dart';

class AlertsManagementPage extends ConsumerStatefulWidget {
  const AlertsManagementPage({super.key});

  @override
  ConsumerState<AlertsManagementPage> createState() => _AlertsManagementPageState();
}

class _AlertsManagementPageState extends ConsumerState<AlertsManagementPage> {
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final service = ref.read(priceServiceProvider);
    final token = await service.getDeviceToken();
    final alerts = await service.fetchAlerts(token);
    if (mounted) {
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAlert(String id) async {
    HapticFeedback.mediumImpact();
    final service = ref.read(priceServiceProvider);
    final success = await service.deleteAlert(id);
    if (success) {
      _loadAlerts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('auto_str_206'.tr(),
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: AppColors.darkGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold))
          : _alerts.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    final alert = _alerts[index];
                    return _buildAlertCard(alert);
                  },
                ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final conditionText = alert['condition'] == 'above' ? 'auto_str_326'.tr() : 'auto_str_337'.tr();
    final targetPrice = alert['targetPrice'];
    final priceId = alert['priceId'];
    final date = DateTime.parse(alert['createdAt']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.notifications_active, color: AppColors.gold),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تنبيه على $priceId',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'عندما يكون $conditionText $targetPrice',
                  style:
                      const TextStyle(color: AppColors.mutedText, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  DateFormat('yyyy/MM/dd HH:mm').format(date.toLocal()),
                  style: TextStyle(color: Colors.grey[400], fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteAlert(alert['_id']),
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
