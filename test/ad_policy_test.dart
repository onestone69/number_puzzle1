import 'package:flutter_test/flutter_test.dart';
import 'package:number_puzzle1/ad_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final now = DateTime(2026, 11, 21, 12);

  test('앱 열기 광고는 5번째 실행부터 노출', () async {
    final policy = AdPolicy();
    for (var launch = 1; launch <= 4; launch++) {
      await policy.recordLaunch();
      expect(policy.canShowAppOpen(now), isFalse, reason: '$launch번째 실행');
    }
    await policy.recordLaunch();
    expect(policy.launchCount, 5);
    expect(policy.canShowAppOpen(now), isTrue);
  });

  test('앱 열기 광고는 노출 후 4시간 동안 다시 나오지 않음', () async {
    SharedPreferences.setMockInitialValues({'ads_launch_count': 9});
    final policy = AdPolicy();
    await policy.recordLaunch();
    expect(policy.canShowAppOpen(now), isTrue);

    await policy.markAppOpenShown(now);
    expect(policy.canShowAppOpen(now.add(const Duration(hours: 1))), isFalse);
    expect(
      policy.canShowAppOpen(now.add(const Duration(hours: 3, minutes: 59))),
      isFalse,
    );
    expect(policy.canShowAppOpen(now.add(const Duration(hours: 4))), isTrue);
  });

  test('마지막 노출 시각은 앱을 다시 켜도 유지됨', () async {
    SharedPreferences.setMockInitialValues({'ads_launch_count': 9});
    await AdPolicy().markAppOpenShown(now);

    final restarted = AdPolicy();
    await restarted.recordLaunch();
    expect(restarted.launchCount, 10);
    expect(
      restarted.canShowAppOpen(now.add(const Duration(minutes: 30))),
      isFalse,
    );
  });

  test('배너는 첫 실행에는 숨기고 2번째 실행부터 표시', () async {
    final policy = AdPolicy();
    await policy.recordLaunch();
    expect(policy.bannersEnabled, isFalse);
    await policy.recordLaunch();
    expect(policy.bannersEnabled, isTrue);
  });
}
