import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:number_puzzle1/screen/number15_screen.dart';
import 'package:number_puzzle1/screen/number24_screen.dart';
import 'package:number_puzzle1/screen/number8_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 테스트할 세로 화면 크기 (논리 픽셀)
const screenSizes = <String, Size>{
  '작은 폰 320x568': Size(320, 568),
  '보급형 폰 360x640': Size(360, 640),
  '일반 폰 412x915': Size(412, 915),
};

/// 퍼즐 이름, 화면 생성 함수, 타일 개수
final puzzles = <(String, Widget Function(Key), int)>[
  ('3x3', (key) => Number8Screen(key: key, showAd: false), 8),
  ('4x4', (key) => Number15Screen(key: key, showAd: false), 15),
  ('5x5', (key) => Number24Screen(key: key, showAd: false), 24),
];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // 최고 기록 문구도 표시되도록 긴 기록값을 넣어 둠
    SharedPreferences.setMockInitialValues({
      for (final p in ['puzzle_8', 'puzzle_15', 'puzzle_24']) ...{
        'best_moves_$p': 9999,
        'best_time_$p': 5999,
      },
    });
    await EasyLocalization.ensureInitialized();
  });

  // easy_localization은 테스트마다 다시 띄우면 번역 로딩이 끝나지 않으므로
  // 앱을 한 번만 띄우고 화면과 크기를 바꿔 가며 검사한다.
  testWidgets('모든 퍼즐 화면이 여러 화면 크기에서 넘치지 않음', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final home = ValueNotifier<Widget>(const SizedBox());
    addTearDown(home.dispose);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: Builder(
          builder:
              (context) => MaterialApp(
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                home: ValueListenableBuilder<Widget>(
                  valueListenable: home,
                  builder: (_, child, _) => child,
                ),
              ),
        ),
      ),
    );

    /// 실제 비동기 작업(번역·저장값 로드)이 끝나고 [finder]가 나타날 때까지 대기
    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 50 && finder.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
    }

    for (final (name, build, tileCount) in puzzles) {
      for (final MapEntry(key: sizeName, value: size) in screenSizes.entries) {
        final label = '$name / $sizeName';
        tester.view.physicalSize = size * 3.0;
        home.value = build(UniqueKey());
        await tester.pump();
        await waitFor(find.textContaining('Best Record'));
        await tester.pump();

        // 레이아웃 넘침(RenderFlex overflow) 등 예외가 없어야 함
        expect(tester.takeException(), isNull, reason: label);

        // 최고 기록 문구가 '$' 없이 표시되어야 함
        expect(
          find.text('Best Record: 9999 moves / 99:59'),
          findsOneWidget,
          reason: label,
        );

        // 모든 숫자 타일이 표시되어야 함
        for (var i = 1; i <= tileCount; i++) {
          expect(find.text('$i'), findsWidgets, reason: '$label 타일 $i');
        }
      }
    }

    // 화면을 떠나며 타이머 정리
    home.value = const SizedBox();
    await tester.pump();
  });
}
