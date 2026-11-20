import 'package:material_ui/material_ui.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // 테스트 광고 ID (실제 앱 배포 시 실제 광고 ID로 교체)
  final String _adUnitId = 'ca-app-pub-3270520208232118/9254919355';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadAd() {
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
          debugPrint('광고 로드 실패: ${error.message}');
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: Colors.grey[200],
      child:
          _isLoaded
              ? AdWidget(ad: _bannerAd!)
              : const Center(
                child: Text(
                  'AdMob 배너 로드 중...',
                  style: TextStyle(fontFamily: 'HiMelody', color: Colors.grey),
                ),
              ),
    );
  }
}
