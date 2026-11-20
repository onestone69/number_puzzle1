import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:number_puzzle1/ad_ids.dart';

class AppOpenAdManager {
  static final AppOpenAdManager _instance = AppOpenAdManager._internal();
  factory AppOpenAdManager() => _instance;
  AppOpenAdManager._internal();

  AppOpenAd? _appOpenAd;
  bool _isAdAvailable = false;
  bool _isShowingAd = false;

  final String adUnitId = AdIds.appOpen;

  /// 앱 열기 광고 로드
  void loadAd() {
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAdAvailable = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint("앱 열기 광고 로드 실패: $error");
        },
      ),
    );
  }

  /// 광고 표시
  void showAdIfAvailable() {
    if (!_isAdAvailable || _isShowingAd) {
      loadAd(); // 다음 광고를 위해 로드
      return;
    }

    _appOpenAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _isAdAvailable = false;
        _isShowingAd = false;
        loadAd(); // 다음 광고 로드
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isAdAvailable = false;
        _isShowingAd = false;
        ad.dispose();
        loadAd();
      },
    );

    _isShowingAd = true;
    _appOpenAd?.show();
  }
}
