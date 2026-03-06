import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/price_service.dart';

class SourceDetailPage extends StatefulWidget {
  final String sourceKey;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const SourceDetailPage({
    super.key,
    required this.sourceKey,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  State<SourceDetailPage> createState() => _SourceDetailPageState();
}

class _SourceDetailPageState extends State<SourceDetailPage> {
  bool _isUpdating = false;
  Map<String, dynamic> _status = {};
  Map<String, dynamic>? _sourceData;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _isLoadingData = true);

    final service = Provider.of<PriceService>(context, listen: false);

    try {
      final statusMap = await service.fetchSourcesStatus();
      final publicSources = await service.fetchPublicSourcePrices();

      // Find data for THIS source
      final mySourceData = publicSources.firstWhere(
        (s) => s['source'] == widget.sourceKey,
        orElse: () => null,
      );

      // Fetch settings
      await service.fetchSettings();

      if (mounted) {
        setState(() {
          _status = statusMap[widget.sourceKey] ?? {};
          _sourceData = mySourceData != null ? mySourceData['data'] : null;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _triggerManualUpdate() async {
    setState(() => _isUpdating = true);
    final service = Provider.of<PriceService>(context, listen: false);
    final status = await service.refreshPrices(source: widget.sourceKey);

    await Future.delayed(const Duration(seconds: 2));
    await _refresh();

    if (mounted) {
      setState(() => _isUpdating = false);
      final isSuccess = status == RefreshStatus.success;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              isSuccess ? 'تم تحديث البيانات بنجاح' : 'تعذر التحديث حالياً'),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status['status'] ?? 'unknown';
    final isOnline = status == 'online';

    String timeStr = 'غير محدد';
    if (_status['lastUpdate'] != null) {
      final date = DateTime.tryParse(_status['lastUpdate']);
      if (date != null) {
        timeStr = DateFormat('HH:mm:ss').format(date.toLocal());
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title,
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.white)),
        backgroundColor: AppColors.darkGreen,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.gold,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Source Information Card
              _buildModernCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child:
                              Icon(widget.icon, color: widget.color, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.title,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.darkGreen)),
                              Text(widget.subtitle,
                                  style: const TextStyle(
                                      color: AppColors.mutedText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildStatusChip(isOnline),
                            const SizedBox(height: 4),
                            Text(timeStr,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.mutedText)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Extracted Data Section (The Real Information)
              _buildSectionTitle('الأسعار الحالية من هذا المصدر'),
              const SizedBox(height: 12),
              _isLoadingData
                  ? _buildShimmerLoading()
                  : _sourceData == null || _sourceData!.isEmpty
                      ? _buildEmptyState()
                      : _buildDataGrid(),

              const SizedBox(height: 32),

              // 3. Operational Logic Section
              _buildSectionTitle('تحديث البيانات'),
              const SizedBox(height: 12),
              _buildModernCard(
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _isUpdating ? null : _triggerManualUpdate,
                        icon: _isUpdating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.gold))
                            : const Icon(Icons.refresh_rounded,
                                color: AppColors.gold, size: 24),
                        label: Text(
                            _isUpdating
                                ? 'جاري السحب...'
                                : 'تحديث البيانات الآن',
                            style: const TextStyle(
                                color: AppColors.darkGreen,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          backgroundColor:
                              AppColors.gold.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'سيقوم النظام بسحب آخر الأسعار من الموقع الرسمي فوراً',
                      style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataGrid() {
    final usd = _sourceData?['usd'];
    final eur = _sourceData?['eur'];
    final tryc = _sourceData?['try'];
    final sar = _sourceData?['sar'];
    final aed = _sourceData?['aed'];
    final gold21 = _sourceData?['gold21'];
    final ounce = _sourceData?['ounce'];
    dynamic gold21Sell;
    dynamic gold21Buy;

    if (gold21 != null) {
      if (gold21 is Map) {
        gold21Buy = gold21['buy'];
        gold21Sell = gold21['sell'];
      } else {
        gold21Buy = gold21;
        gold21Sell = gold21 * 1.01;
      }
    }

    return Column(
      children: [
        if (usd != null && usd['buy'] != 0)
          _buildSourcePriceRow(
              'الدولار الأمريكي', usd['buy'], usd['sell'], 'SYP'),
        if (eur != null && eur['buy'] != 0)
          _buildSourcePriceRow('اليورو', eur['buy'], eur['sell'], 'SYP'),
        if (sar != null && sar['buy'] != 0)
          _buildSourcePriceRow(
              'الريال السعودي', sar['buy'], sar['sell'], 'SYP'),
        if (aed != null && aed['buy'] != 0)
          _buildSourcePriceRow(
              'الدرهم الإماراتي', aed['buy'], aed['sell'], 'SYP'),
        if (tryc != null && tryc['buy'] != 0)
          _buildSourcePriceRow(
              'الليرة التركية', tryc['buy'], tryc['sell'], 'SYP'),
        if (gold21Buy != null && gold21Buy != 0)
          _buildSourcePriceRow('ذهب عيار 21', gold21Buy, gold21Sell, 'SYP'),
        if (ounce != null && ounce != 0)
          _buildSourcePriceRow('أونصة الذهب', ounce, ounce, 'USD'),
      ],
    );
  }

  Widget _buildSourcePriceRow(
      String label, dynamic buy, dynamic sell, String currency) {
    final formatter = NumberFormat('#,###', 'ar_SA');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('شراء: ${formatter.format(buy)} $currency',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.priceUp,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace')),
              const SizedBox(height: 2),
              Text('مبيع: ${formatter.format(sell)} $currency',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.priceDown,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool online) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (online ? AppColors.priceUp : AppColors.priceDown)
            .withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        online ? 'Online' : 'Error',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: online ? AppColors.priceUp : AppColors.priceDown,
        ),
      ),
    );
  }

  Widget _buildModernCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.darkGreen));
  }

  Widget _buildShimmerLoading() {
    return Column(
      children: List.generate(
          3,
          (index) => Container(
                height: 70,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
              )),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: Colors.grey.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            const Text('لا توجد بيانات متاحة لهذا المصدر حالياً',
                style: TextStyle(color: AppColors.mutedText)),
          ],
        ),
      ),
    );
  }
}
