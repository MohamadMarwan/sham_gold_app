import 'package:easy_localization/easy_localization.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gold_sham/core/constants/app_colors.dart';
import 'package:gold_sham/shared/models/price_item.dart';
import 'package:gold_sham/shared/services/price_service.dart';
import 'package:gold_sham/shared/widgets/shimmer_loading.dart';
import 'package:gold_sham/shared/widgets/sparkline_widget.dart';
import 'package:gold_sham/shared/widgets/price_alert_dialog.dart';
import 'package:gold_sham/shared/widgets/syrian_flag.dart';
import 'package:gold_sham/shared/widgets/favorite_toggle_button.dart';
import 'package:gold_sham/shared/widgets/premium_logo.dart';
import 'package:gold_sham/features/home/presentation/pages/price_detail_page.dart';
import 'package:gold_sham/features/home/presentation/widgets/live_indicator.dart';
import 'package:gold_sham/shared/widgets/dynamic_asset_icon_v2.dart';
import 'package:gold_sham/shared/widgets/last_update_ticker.dart';
import 'package:gold_sham/features/home/presentation/widgets/calculator_widget.dart';

class CurrenciesPage extends StatelessWidget {
  const CurrenciesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final priceService = Provider.of<PriceService>(context);
    final allPrices = priceService.currentPrices;

    DateTime? latestUpdate;
    if (allPrices.isNotEmpty) {
      final updates = allPrices.map((e) => e.lastUpdate).whereType<DateTime>();
      if (updates.isNotEmpty) {
        latestUpdate = updates.reduce((a, b) => a.isAfter(b) ? a : b);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<Map<String, dynamic>>(
        stream: priceService.settingsStream,
        initialData: priceService.currentSettings,
        builder: (context, settingsSnapshot) {
          final appName =
              settingsSnapshot.data?['appName'] as String? ?? 'auto_str_278'.tr();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.darkGreen,
                elevation: 0,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(bottom: 100),
                  title: Text(appName,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: 22,
                          shadows: [
                            Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 15,
                                offset: const Offset(0, 4))
                          ])),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.darkGreen, Color(0xFF0F2E25)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                    child: Stack(
                      children: [
                        const Positioned(
                          top: 40,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: PremiumLogo(
                              size: 140,
                              isBackground: true,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -30,
                          top: -30,
                          child: CircleAvatar(
                            radius: 100,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(80),
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        height: 80,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(40)),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LiveIndicator(
                                    animate: priceService.isConnected),
                                if (latestUpdate != null) ...[
                                  Container(
                                    height: 12,
                                    width: 1.5,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 14),
                                    color: Colors.white24,
                                  ),
                                  const Icon(Icons.speed_rounded,
                                      color: AppColors.gold, size: 14),
                                  const SizedBox(width: 8),
                                  LastUpdateTicker(
                                    lastUpdate: latestUpdate,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              StreamBuilder<List<PriceItem>>(
                stream: priceService.pricesStream,
                initialData: priceService.currentPrices,
                builder: (context, snapshot) {
                  final prices = snapshot.data ?? [];

                  if (prices.isEmpty) {
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 50),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, idx) => const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: PremiumCardShimmer()),
                          childCount: 6,
                        ),
                      ),
                    );
                  }

                  final syrianCurrencies =
                      prices.where((p) => p.id.startsWith('sy_')).toList();
                  final turkishCurrencies =
                      prices.where((p) => p.id.startsWith('tr_curr_')).toList();

                  // Sort Syrian
                  syrianCurrencies.sort((a, b) {
                    final priority = {
                      'sy_usd': 0,
                      'sy_eur': 1,
                      'sy_try': 2,
                      'sy_sar': 3,
                      'sy_aed': 4
                    };
                    return (priority[a.id] ?? 99)
                        .compareTo(priority[b.id] ?? 99);
                  });

                  // Sort Turkish
                  turkishCurrencies.sort((a, b) {
                    final priority = {
                      'tr_curr_usd': 0,
                      'tr_curr_eur': 1,
                      'tr_curr_gbp': 2,
                      'tr_curr_sar': 3,
                      'tr_curr_aed': 4
                    };
                    return (priority[a.id] ?? 99)
                        .compareTo(priority[b.id] ?? 99);
                  });

                  if (syrianCurrencies.isEmpty && turkishCurrencies.isEmpty) {
                    return _buildEmptyState();
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (priceService
                            .shouldShow('currencyShowSummaryWelcome')) ...[
                          _buildWelcomeCard(),
                          const SizedBox(height: 32),
                        ],
                        if (syrianCurrencies.isNotEmpty) ...[
                          _buildSectionHeader(
                              'auto_str_062'.tr(),
                              Icons.account_balance_rounded),
                          const SizedBox(height: 16),
                          ...syrianCurrencies.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildPremiumCurrencyCard(item, context),
                              )),
                        ],
                        if (turkishCurrencies.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildSectionHeader(
                              'auto_str_061'.tr(),
                              Icons.currency_lira_rounded),
                          const SizedBox(height: 16),
                          ...turkishCurrencies.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildPremiumCurrencyCard(item, context),
                              )),
                        ],
                        // 🧮 Calculator Section
                        if (priceService
                            .shouldShow('currencyShowCalculator')) ...[
                          const SizedBox(height: 24),
                          const CalculatorWidget(),
                          const SizedBox(height: 16),
                        ],
                      ]),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: 0.2),
            blurRadius: 35,
            offset: const Offset(0, 15),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.2),
                  AppColors.gold.withValues(alpha: 0.2)
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.currency_exchange_rounded,
                color: AppColors.gold, size: 36),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'auto_str_157'.tr(),
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkGreen,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'auto_str_030'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCurrencyCard(PriceItem item, BuildContext context) {
    final isUp = item.trend == Trend.up;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PriceDetailPage(priceItem: item)));
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // 1. Icon / Flag (RIGHT in RTL)
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ],
                      border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.05)),
                    ),
                    child: Center(child: _buildFlagIcon(item.id, item.title)),
                  ),
                  const SizedBox(width: 18),

                  // 2. Title & Subtitle (Middle)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _translateTitle(item.title),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.darkGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'auto_str_207'.tr(),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.mutedText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),

                  // 3. Price Side (LEFT in RTL)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPriceRow('auto_str_361'.tr(), item.buyPrice,
                          item.currency == 'TRY' ? '₺' : 'auto_str_381'.tr()),
                      const SizedBox(height: 6),
                      _buildPriceRow('auto_str_359'.tr(), item.sellPrice,
                          item.currency == 'TRY' ? '₺' : 'auto_str_381'.tr(),
                          isSell: true),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Bottom Row (Actions & Visuals)
              Row(
                children: [
                  FavoriteToggleButton(priceId: item.id),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => PriceAlertDialog(priceItem: item),
                      );
                    },
                    icon: const Icon(Icons.notifications_active_outlined,
                        size: 20, color: AppColors.gold),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  if (item.lastUpdate != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      'تحديث: ${DateFormat('hh:mm a', 'ar').format(item.lastUpdate!)}',
                      style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: 100,
                    height: 24,
                    child: SparklineWidget(
                      data: isUp
                          ? [10, 15, 12, 18, 22, 20, 25]
                          : [25, 20, 22, 18, 12, 15, 10],
                      color: isUp ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double price, String symbol,
      {bool isSell = false}) {
    final format = NumberFormat("#,##0.###", "ar");
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: isSell
                ? Colors.redAccent.withValues(alpha: 0.7)
                : Colors.green.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          format.format(price),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppColors.darkGreen,
            fontFamily: 'Roboto',
          ),
        ),
        const SizedBox(width: 4),
        Text(
          symbol,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppColors.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildFlagIcon(String id, String title) {
    final t = title.toLowerCase();
    final d = id.toLowerCase();

    // ✅ 1. Direct Emoji Mapping (Most Reliable)
    Widget? emojiWidget;

    if (t.contains('auto_str_352'.tr()) || d.contains('usd')) {
      emojiWidget = const Text('🇺🇸', style: TextStyle(fontSize: 32));
    } else if (t.contains('auto_str_368'.tr()) || d.contains('eur')) {
      emojiWidget = const Text('🇪🇺', style: TextStyle(fontSize: 32));
    } else if (t.contains('auto_str_354'.tr()) || d.contains('sar')) {
      emojiWidget = const Text('🇸🇦', style: TextStyle(fontSize: 32));
    } else if (t.contains('auto_str_328'.tr()) || d.contains('aed')) {
      emojiWidget = const Text('🇦🇪', style: TextStyle(fontSize: 32));
    } else if (t.contains('auto_str_312'.tr()) || d.contains('gbp')) {
      emojiWidget = const Text('🇬🇧', style: TextStyle(fontSize: 32));
    } else if (t.contains('auto_str_357'.tr()) || d.contains('kwd')) {
      emojiWidget = const Text('🇰🇼', style: TextStyle(fontSize: 32));
    } else if (t.contains('auto_str_346'.tr()) || d.contains('jod')) {
      emojiWidget = const Text('🇯🇴', style: TextStyle(fontSize: 32));
    } else if (t.contains('auto_str_364'.tr()) || d.contains('qar')) {
      emojiWidget = const Text('🇶🇦', style: TextStyle(fontSize: 32));
    } else if (t.contains('auto_str_340'.tr()) || d.contains('bhd')) {
      emojiWidget = const Text('🇧🇭', style: TextStyle(fontSize: 32));
    } else if (t.contains('auto_str_356'.tr()) || d.contains('omr')) {
      emojiWidget = const Text('🇴🇲', style: TextStyle(fontSize: 32));
    } else if (t.contains('auto_str_366'.tr()) || d.contains('egp')) {
      emojiWidget = const Text('🇪🇬', style: TextStyle(fontSize: 32));
    } else if (t.contains('auto_str_351'.tr()) || d.contains('try')) {
      emojiWidget = const Text('🇹🇷', style: TextStyle(fontSize: 32));
    }

    // ✅ 2. Return emoji immediately if found
    if (emojiWidget != null) {
      return emojiWidget;
    }

    // ✅ 3. Try DynamicAssetIcon (only if Backend has custom assets)
    String? assetKey;
    if (t.contains('auto_str_352'.tr())) {
      assetKey = 'currency_usd';
    } else if (t.contains('auto_str_368'.tr())) {
      assetKey = 'currency_eur';
    } else if (t.contains('auto_str_351'.tr())) {
      assetKey = 'currency_try';
    } else if (t.contains('auto_str_354'.tr())) {
      assetKey = 'currency_sar';
    } else if (t.contains('auto_str_328'.tr())) {
      assetKey = 'currency_aed';
    } else if (t.contains('auto_str_357'.tr())) {
      assetKey = 'currency_kwd';
    } else if (t.contains('auto_str_346'.tr())) {
      assetKey = 'currency_jod';
    }

    if (assetKey != null) {
      return DynamicAssetIcon(
        assetKey,
        size: 32,
        fallback: emojiWidget ?? _getEmojiFallback(t, d),
      );
    }

    // ✅ 4. Final fallback
    return _getEmojiFallback(t, d);
  }

  Widget _getEmojiFallback(String t, String id) {
    final d = id.toLowerCase();
    if (t.contains('auto_str_352'.tr()) || d.contains('usd')) {
      return const Text('🇺🇸', style: TextStyle(fontSize: 32));
    }
    if (t.contains('auto_str_368'.tr()) || d.contains('eur')) {
      return const Text('🇪🇺', style: TextStyle(fontSize: 32));
    }
    if (t.contains('auto_str_354'.tr()) || d.contains('sar')) {
      return const Text('🇸🇦', style: TextStyle(fontSize: 32));
    }
    if (t.contains('auto_str_328'.tr()) || d.contains('aed')) {
      return const Text('🇦🇪', style: TextStyle(fontSize: 32));
    }
    if (t.contains('auto_str_312'.tr()) || d.contains('gbp')) {
      return const Text('🇬🇧', style: TextStyle(fontSize: 32));
    }
    if (t.contains('auto_str_357'.tr()) || d.contains('kwd')) {
      return const Text('🇰🇼', style: TextStyle(fontSize: 32));
    }
    if (t.contains('auto_str_346'.tr()) || d.contains('jod')) {
      return const Text('🇯🇴', style: TextStyle(fontSize: 32));
    }
    if (t.contains('auto_str_364'.tr()) || d.contains('qar')) {
      return const Text('🇶🇦', style: TextStyle(fontSize: 32));
    }
    if (t.contains('auto_str_340'.tr()) || d.contains('bhd')) {
      return const Text('🇧🇭', style: TextStyle(fontSize: 32));
    }
    if (t.contains('auto_str_356'.tr()) || d.contains('omr')) {
      return const Text('🇴🇲', style: TextStyle(fontSize: 32));
    }
    if (t.contains('auto_str_366'.tr()) || d.contains('egp')) {
      return const Text('🇪🇬', style: TextStyle(fontSize: 32));
    }
    if (t.contains('auto_str_351'.tr()) || d.contains('try')) {
      return const Text('🇹🇷', style: TextStyle(fontSize: 32));
    }
    return const SyrianFlag(width: 40);
  }

  String _translateTitle(String original) {
    final t = original.toUpperCase();
    if (t == 'USDTRY') return 'auto_str_203'.tr();
    if (t == 'EURTRY') return 'auto_str_223'.tr();
    if (t == 'GBPTRY') return 'auto_str_181'.tr();
    if (t == 'SARTRY') return 'auto_str_233'.tr();
    if (t == 'AEDTRY') return 'auto_str_202'.tr();
    if (t == 'KWDTRY') return 'auto_str_220'.tr();
    if (t == 'JODTRY') return 'auto_str_219'.tr();
    if (t == 'QARTRY') return 'auto_str_251'.tr();
    if (t == 'BHDTRY') return 'auto_str_204'.tr();
    if (t == 'OMRTRY') return 'auto_str_221'.tr();
    return original;
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.gold, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.darkGreen,
          ),
        ),
        const Spacer(),
        Container(
          width: 40,
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.gold.withValues(alpha: 0.5),
                Colors.transparent
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.money_off_csred_rounded,
                size: 80, color: Colors.grey.withValues(alpha: 0.2)),
            const SizedBox(height: 20),
            const Text('auto_str_120'.tr(),
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.mutedText,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
