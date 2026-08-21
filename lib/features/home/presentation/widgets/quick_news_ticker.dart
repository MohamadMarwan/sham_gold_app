import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gold_sham/shared/services/price_service.dart';
import 'package:gold_sham/core/constants/app_colors.dart';
import 'dart:async';

class QuickNewsTicker extends ConsumerStatefulWidget {
  const QuickNewsTicker({super.key});

  @override
  ConsumerState<QuickNewsTicker> createState() => _QuickNewsTickerState();
}

class _QuickNewsTickerState extends ConsumerState<QuickNewsTicker> {
  late ScrollController _scrollController;
  Timer? _timer;
  double _scrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_scrollController.hasClients) {
        _scrollPosition += 1.0;
        if (_scrollPosition >= _scrollController.position.maxScrollExtent) {
          _scrollPosition = 0;
          _scrollController.jumpTo(0);
        } else {
          _scrollController.jumpTo(_scrollPosition);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final priceService = ref.watch(priceServiceProvider);
    if (!priceService.shouldShow('homeShowNewsTicker')) {
      return const SizedBox.shrink();
    }
    final isConnected = priceService.isConnected;

    // Get the array of news items from settings
    final List<dynamic>? items =
        priceService.currentSettings?['displaySettings']?['newsTickerItems'];

    String news = '';
    if (items != null && items.isNotEmpty) {
      // Filter out empty items and join with separator
      final joinedNews =
          items.where((item) => item.toString().trim().isNotEmpty).join(' • ');
      news = '$joinedNews •';
    }

    // Fallback if no specific news, show market status
    if (news.isEmpty || news == ' •') {
      news = priceService.getDisplaySetting('newsTickerText',
          defaultValue: isConnected
              ? 'auto_str_003'.tr()
              : 'auto_str_018'.tr());
    }

    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.darkGreen.withValues(alpha: 0.05),
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            color: AppColors.gold.withValues(alpha: 0.9),
            alignment: Alignment.center,
            child: const Text(
              'auto_str_345'.tr(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 1,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: Text(
                      news,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkGreen,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
