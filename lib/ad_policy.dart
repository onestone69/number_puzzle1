import 'package:shared_preferences/shared_preferences.dart';

/// 광고 노출 빈도 규칙.
///
/// 간단한 퍼즐 게임이라 광고가 플레이를 방해하지 않도록 다음 원칙을 따른다.
/// - 앱 열기 광고: [appOpenMinLaunch]번째 실행부터, 한 번 본 뒤
///   [appOpenCooldown] 동안은 다시 보여주지 않는다.
/// - 배너: 첫 실행에는 숨기고 [bannerMinLaunch]번째 실행부터 게임 화면에만 표시한다.
class AdPolicy {
  AdPolicy();

  static final AdPolicy instance = AdPolicy();

  static const appOpenMinLaunch = 5;
  static const appOpenCooldown = Duration(hours: 4);
  static const bannerMinLaunch = 2;

  static const _launchCountKey = 'ads_launch_count';
  static const _lastAppOpenKey = 'ads_last_app_open_shown';

  int _launchCount = 0;
  DateTime? _lastAppOpenShown;

  /// 지금까지 앱을 실행한 횟수 (이번 실행 포함)
  int get launchCount => _launchCount;

  /// 앱이 새로 실행될 때 한 번 호출한다.
  Future<void> recordLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    _launchCount = (prefs.getInt(_launchCountKey) ?? 0) + 1;
    await prefs.setInt(_launchCountKey, _launchCount);
    final lastMs = prefs.getInt(_lastAppOpenKey);
    _lastAppOpenShown =
        lastMs == null ? null : DateTime.fromMillisecondsSinceEpoch(lastMs);
  }

  /// 게임 화면에 배너를 보여도 되는지
  bool get bannersEnabled => _launchCount >= bannerMinLaunch;

  /// 지금 앱 열기 광고를 보여도 되는지
  bool canShowAppOpen(DateTime now) {
    if (_launchCount < appOpenMinLaunch) return false;
    final last = _lastAppOpenShown;
    return last == null || now.difference(last) >= appOpenCooldown;
  }

  /// 앱 열기 광고가 실제로 노출되었을 때 호출한다.
  Future<void> markAppOpenShown(DateTime now) async {
    _lastAppOpenShown = now;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastAppOpenKey, now.millisecondsSinceEpoch);
  }
}
