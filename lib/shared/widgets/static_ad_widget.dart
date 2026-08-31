import 'package:flutter/material.dart';
import 'package:gold_sham/core/utils/web_stubs/ads_wrapper.dart';
import 'package:flutter/foundation.dart';

class StaticAdWidget extends StatefulWidget {
  final String adUnitId;
  final AdSize adSize;

  const StaticAdWidget({
    super.key,
    required this.adUnitId,
    this.adSize = AdSize.banner,
  });

  @override
  State<StaticAdWidget> createState() => _StaticAdWidgetState();
}

class _StaticAdWidgetState extends State<StaticAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (kIsWeb) return;
    
    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Ad failed to load: $error');
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
    if (kIsWeb || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
