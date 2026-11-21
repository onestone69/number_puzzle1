import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 광고 동의(Google UMP) 관리.
///
/// 유럽(EEA)·영국 등 동의가 필요한 지역에서는 AdMob 콘솔에 설정한 동의 창을
/// 보여주고, 동의 결과에 따라 광고를 요청해도 되는지 판단한다.
/// 동의가 필요 없는 지역에서는 창 없이 바로 광고가 허용된다.
/// 광고 SDK 초기화와 모든 광고 요청은 [adsAllowed]가 true가 된 뒤에만 한다.
class ConsentManager {
  ConsentManager._();

  static final ConsentManager instance = ConsentManager._();

  /// 광고를 요청해도 되는지 (동의 확인 + 광고 SDK 초기화 완료)
  final ValueNotifier<bool> adsAllowed = ValueNotifier(false);

  /// 설정 화면에 '개인정보 설정(광고 동의 변경)' 버튼이 필요한지
  bool privacyOptionsRequired = false;

  bool _started = false;

  /// 앱 시작 시 한 번 호출: 동의 정보 갱신 → 필요하면 동의 창 → 광고 SDK 초기화
  Future<void> gatherConsentAndInitAds() async {
    if (_started) return;
    _started = true;
    try {
      final done = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          await ConsentForm.loadAndShowConsentFormIfRequired((error) {
            if (error != null) debugPrint('동의 창 오류: ${error.message}');
            if (!done.isCompleted) done.complete();
          });
        },
        (error) {
          // 네트워크 오류 등: 이전 실행에서 받은 동의로 진행
          debugPrint('동의 정보 갱신 실패: ${error.message}');
          if (!done.isCompleted) done.complete();
        },
      );
      await done.future;
      await _refresh();
    } catch (e) {
      debugPrint('광고 동의 처리 실패: $e');
    }
  }

  /// 설정 화면에서: 광고 동의를 다시 선택하는 창
  Future<void> showPrivacyOptions() async {
    try {
      final done = Completer<void>();
      await ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) debugPrint('개인정보 설정 창 오류: ${error.message}');
        if (!done.isCompleted) done.complete();
      });
      await done.future;
      await _refresh();
    } catch (e) {
      debugPrint('개인정보 설정 창 실패: $e');
    }
  }

  Future<void> _refresh() async {
    final info = ConsentInformation.instance;
    privacyOptionsRequired =
        await info.getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
    if (!adsAllowed.value && await info.canRequestAds()) {
      await MobileAds.instance.initialize();
      adsAllowed.value = true;
    }
  }

  /// 광고가 허용되면(이미 허용됐으면 즉시) [callback]을 한 번 실행한다.
  /// 반환값을 호출하면 기다리기를 취소한다.
  VoidCallback whenAdsAllowed(VoidCallback callback) {
    if (adsAllowed.value) {
      callback();
      return () {};
    }
    void listener() {
      if (!adsAllowed.value) return;
      adsAllowed.removeListener(listener);
      callback();
    }

    adsAllowed.addListener(listener);
    return () => adsAllowed.removeListener(listener);
  }
}
