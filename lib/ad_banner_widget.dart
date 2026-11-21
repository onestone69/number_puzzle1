import 'package:material_ui/material_ui.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:number_puzzle1/ad_ids.dart';
import 'package:number_puzzle1/ad_policy.dart';
import 'package:number_puzzle1/consent_manager.dart';

/// 게임 화면 하단 배너.
///
/// 첫 실행에는 표시하지 않고([AdPolicy.bannersEnabled]),
/// 로드되는 동안에는 화면이 흔들리지 않도록 빈 공간만 잡아 두며,
/// 로드에 실패하면 영역 자체를 접는다.
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _failed = false;
  late final bool _enabled = AdPolicy.instance.bannersEnabled;
  VoidCallback? _cancelAdsWait;

  final String _adUnitId = AdIds.banner;

  @override
  void initState() {
    super.initState();
    // 광고 동의·SDK 초기화가 끝난 뒤에 로드
    if (_enabled) {
      _cancelAdsWait = ConsentManager.instance.whenAdsAllowed(_loadAd);
    }
  }

  @override
  void dispose() {
    _cancelAdsWait?.call();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadAd() {
    if (!mounted) return;
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
          debugPrint('광고 로드 실패: ${error.message}');
          if (!mounted) return;
          setState(() {
            _failed = true;
          });
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled || _failed) return const SizedBox.shrink();
    final ad = _bannerAd;
    return SizedBox(
      height: AdSize.banner.height.toDouble(),
      width: double.infinity,
      child:
          _isLoaded && ad != null
              ? Center(
                child: SizedBox(
                  width: AdSize.banner.width.toDouble(),
                  child: AdWidget(ad: ad),
                ),
              )
              : null,
    );
  }
}
