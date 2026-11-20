import 'dart:io' show Platform;

/// 플랫폼별 AdMob 광고 단위 ID.
///
/// 앱 ID는 Android는 AndroidManifest.xml, iOS는 ios/Runner/Info.plist의
/// GADApplicationIdentifier에 있다.
class AdIds {
  AdIds._();

  // Android (실제 광고 ID)
  static const _androidBanner = 'ca-app-pub-3270520208232118/9254919355';
  static const _androidAppOpen = 'ca-app-pub-3270520208232118/3407195293';

  // iOS
  static const _iosBanner = 'ca-app-pub-3270520208232118/8232553009';
  static const _iosAppOpen = 'ca-app-pub-3270520208232118/8363967830';

  static String get banner => Platform.isIOS ? _iosBanner : _androidBanner;
  static String get appOpen => Platform.isIOS ? _iosAppOpen : _androidAppOpen;
}
