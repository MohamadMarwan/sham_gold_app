import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:gold_sham/core/services/ad_service.dart';

import 'package:gold_sham/shared/services/price_service.dart';
import 'package:provider/provider.dart';

class AdBannerWidget extends StatefulWidget {
  final AdSize size;
  final String? adUnitId;

  const AdBannerWidget({
    super.key,
    this.size = AdSize.banner,
    this.adUnitId,
  });

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  String? _currentAdUnitId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Watch PriceService to reload when settings (ad enablement) update
    Provider.of<PriceService>(context);
    _checkAndLoadAd();
  }

  @override
  void didUpdateWidget(AdBannerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.adUnitId != oldWidget.adUnitId ||
        widget.size != oldWidget.size) {
      _checkAndLoadAd();
    }
  }

  void _checkAndLoadAd() {
    if (kIsWeb) return;

    final adService = AdService();
    final bool isEnabled = adService.isEnabled;
    String? adUnitId = widget.adUnitId ?? adService.bannerId;

    // If settings changed or first load
    if (isEnabled &&
        adUnitId != null &&
        (adUnitId != _currentAdUnitId || _bannerAd == null)) {
      _currentAdUnitId = adUnitId;
      _loadAd(adUnitId);
    } else if (!isEnabled) {
      _bannerAd?.dispose();
      _bannerAd = null;
      _isLoaded = false;
      _currentAdUnitId = null;
      if (mounted) setState(() {});
    }
  }

  void _loadAd(String adUnitId) {
    _bannerAd?.dispose();
    _isLoaded = false;

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: widget.size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ AdMob Banner Loaded: $adUnitId');
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ AdMob Banner Failed to Load: $error for $adUnitId');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isLoaded = false;
              _bannerAd = null;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb ||
        !_isLoaded ||
        _bannerAd == null ||
        AdService().isRewardActive) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      width: widget.size.width.toDouble(),
      height: widget.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
