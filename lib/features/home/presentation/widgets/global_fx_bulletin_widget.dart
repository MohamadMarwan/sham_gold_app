import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gold_sham/core/constants/app_colors.dart';
import 'package:gold_sham/core/services/http_api_service.dart';
import 'package:gold_sham/shared/widgets/section_header.dart';
import 'package:gold_sham/shared/widgets/shimmer_loading.dart';
import 'package:intl/intl.dart';

class GlobalFxBulletinWidget extends StatefulWidget {
  const GlobalFxBulletinWidget({super.key});

  @override
  State<GlobalFxBulletinWidget> createState() => _GlobalFxBulletinWidgetState();
}

class _GlobalFxBulletinWidgetState extends State<GlobalFxBulletinWidget> {
  final HttpApiService _httpService = HttpApiService();
  Map<String, dynamic>? _rates;
  bool _isLoading = true;
  String? _error;

  // Selected important currencies to show in the bulletin
  final List<String> _targetCurrencies = [
    'EUR', 'TRY', 'SYP', 'SAR', 'AED', 'KWD', 'JOD', 'QAR', 'EGP', 'DZD', 'IQD', 'LBP'
  ];

  @override
  void initState() {
    super.initState();
    _fetchRates();
  }

  Future<void> _fetchRates() async {
    try {
      final response = await _httpService.get('/api/currencies/cross-rates');
      if (response is Map && response['rates'] != null) {
        if (mounted) {
          setState(() {
            _rates = response['rates'] as Map<String, dynamic>;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Invalid data format');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getCurrencyName(String code) {
    switch (code) {
      case 'EUR': return 'يورو أوروبي';
      case 'TRY': return 'ليرة تركية';
      case 'SYP': return 'ليرة سورية';
      case 'SAR': return 'ريال سعودي';
      case 'AED': return 'درهم إماراتي';
      case 'KWD': return 'دينار كويتي';
      case 'JOD': return 'دينار أردني';
      case 'QAR': return 'ريال قطري';
      case 'EGP': return 'جنيه مصري';
      case 'DZD': return 'دينار جزائري';
      case 'IQD': return 'دينار عراقي';
      case 'LBP': return 'ليرة لبنانية';
      default: return code;
    }
  }

  String _getFlagEmoji(String code) {
    switch (code) {
      case 'EUR': return '🇪🇺';
      case 'TRY': return '🇹🇷';
      case 'SYP': return '🇸🇾';
      case 'SAR': return '🇸🇦';
      case 'AED': return '🇦🇪';
      case 'KWD': return '🇰🇼';
      case 'JOD': return '🇯🇴';
      case 'QAR': return '🇶🇦';
      case 'EGP': return '🇪🇬';
      case 'DZD': return '🇩🇿';
      case 'IQD': return '🇮🇶';
      case 'LBP': return '🇱🇧';
      case 'USD': return '🇺🇸';
      default: return '🏳️';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'نشرة أسعار الصرف العالمية',
          icon: Icons.public_rounded,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text('🇺🇸', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          'الأساس: 1 دولار أمريكي (USD)',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (_isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                    )
                  else
                    InkWell(
                      onTap: _fetchRates,
                      child: Icon(Icons.refresh_rounded, size: 20, color: AppColors.gold.withValues(alpha: 0.7)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('عذراً، فشل تحميل النشرة', style: TextStyle(color: Colors.red[300])),
                  ),
                )
              else if (_isLoading && _rates == null)
                Column(
                  children: List.generate(4, (index) => const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: PremiumCardShimmer(),
                  )),
                )
              else if (_rates != null)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _targetCurrencies.length,
                  separatorBuilder: (context, index) => Divider(color: Colors.grey.withValues(alpha: 0.1), height: 1),
                  itemBuilder: (context, index) {
                    final code = _targetCurrencies[index];
                    final rate = _rates![code];
                    
                    if (rate == null) return const SizedBox.shrink();

                    final formatter = NumberFormat("#,##0.####", "en_US");
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        children: [
                          Text(_getFlagEmoji(code), style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getCurrencyName(code),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 14,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                Text(
                                  code,
                                  style: TextStyle(
                                    color: AppColors.mutedText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatter.format(rate),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.gold,
                              fontSize: 16,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
