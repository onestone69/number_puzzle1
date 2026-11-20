import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:number_puzzle1/ad_ids.dart';
import 'package:number_puzzle1/ad_policy.dart';

/// 앱 열기 광고 관리.
///
/// 노출 여부는 [AdPolicy]가 정하고, 여기서는 다음 상황에서만 보여준다.
/// - 앱을 새로 실행했을 때: 광고가 [_coldStartWindow] 안에 준비된 경우에만
///   (늦게 뜨면 이미 플레이 중일 수 있으므로 건너뜀)
/// - 앱으로 돌아왔을 때: [_minBackground] 이상 다른 앱에 있다가 돌아온 경우에만
class AppOpenAdManager {
  static final AppOpenAdManager _instance = AppOpenAdManager._internal();
  factory AppOpenAdManager() => _instance;
  AppOpenAdManager._internal();

  /// AdMob 앱 열기 광고는 로드 후 4시간이 지나면 만료된다.
  static const _adExpiry = Duration(hours: 4);
  static const _coldStartWindow = Duration(seconds: 5);
  static const _minBackground = Duration(minutes: 30);

  final String adUnitId = AdIds.appOpen;
  AdPolicy get _policy => AdPolicy.instance;

  AppOpenAd? _ad;
  DateTime? _loadedAt;
  bool _isLoading = false;
  bool _isShowing = false;
  DateTime? _pausedAt;

  bool get _hasValidAd =>
      _ad != null &&
      _loadedAt != null &&
      DateTime.now().difference(_loadedAt!) < _adExpiry;

  /// 앱이 새로 실행되었을 때 호출
  void onColdStart() {
    if (!_policy.canShowAppOpen(DateTime.now())) return;
    final startedAt = DateTime.now();
    _load(
      onLoaded: () {
        if (DateTime.now().difference(startedAt) <= _coldStartWindow) {
          _show();
        }
      },
    );
  }

  /// 앱이 백그라운드로 갔을 때 호출
  void onPaused() {
    _pausedAt ??= DateTime.now();
  }

  /// 앱이 다시 화면에 나왔을 때 호출
  void onResumed() {
    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt == null || _isShowing) return;
    // 잠깐 다른 앱에 다녀온 경우(광고를 닫고 돌아온 경우 포함)는 무시
    if (DateTime.now().difference(pausedAt) < _minBackground) return;
    if (!_policy.canShowAppOpen(DateTime.now())) return;

    if (_hasValidAd) {
      _show();
    } else {
      // 이미 앱을 쓰는 중이므로 지금 띄우지 않고 다음 기회를 위해 준비만 함
      _load();
    }
  }

  void _load({VoidCallback? onLoaded}) {
    if (_isLoading) return;
    if (_hasValidAd) {
      onLoaded?.call();
      return;
    }
    _ad?.dispose(); // 만료된 광고 정리
    _ad = null;
    _isLoading = true;

    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loadedAt = DateTime.now();
          _isLoading = false;
          onLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          debugPrint('앱 열기 광고 로드 실패: $error');
        },
      ),
    );
  }

  void _show() {
    final ad = _ad;
    if (ad == null || _isShowing || !_hasValidAd) return;
    _isShowing = true;
    _ad = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _policy.markAppOpenShown(DateTime.now());
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowing = false;
        _pausedAt = null;
        ad.dispose();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowing = false;
        ad.dispose();
        debugPrint('앱 열기 광고 표시 실패: $error');
      },
    );
    ad.show();
  }
}
