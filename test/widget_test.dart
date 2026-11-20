import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:number_puzzle1/feedback_service.dart';
import 'package:number_puzzle1/game_save.dart';
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

    // 타일 탭으로 실제 이동이 되는지 확인 (이동 횟수 0 → 1 이상)
    tester.view.physicalSize = const Size(412, 915) * 3.0;
    home.value = Number8Screen(key: UniqueKey(), showAd: false);
    await tester.pump();
    await waitFor(find.textContaining('Best Record'));
    expect(find.text('0'), findsOneWidget);
    for (var i = 1; i <= 8; i++) {
      await tester.tap(find.text('$i').first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('0'), findsNothing, reason: '타일을 탭해도 이동하지 않음');

    // 이어하기: 이동하면 진행 상황이 저장되고, 저장된 게임으로 열면 그대로 이어짐
    final saved = await tester.runAsync(
      () => GameSaveStore.load(Number8Screen.puzzleType, 9),
    );
    expect(saved, isNotNull, reason: '이동 후 진행 상황이 저장되지 않음');
    expect(saved!.moves, greaterThan(0));
    home.value = Number8Screen(
      key: UniqueKey(),
      showAd: false,
      savedGame: saved,
    );
    await tester.pump();
    expect(find.text('${saved.moves}'), findsWidgets);
    final minutes = (saved.seconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (saved.seconds % 60).toString().padLeft(2, '0');
    expect(find.text('$minutes:$seconds'), findsOneWidget);
    // 보드 배치도 저장된 그대로: 빈칸 위치의 타일만 없어야 함
    for (var i = 1; i <= 8; i++) {
      expect(find.text('$i'), findsWidgets);
    }

    // 설정 창: 게임 화면의 설정 버튼으로 열고, 스위치를 끄면 저장되어야 함
    final feedback = FeedbackService.instance;
    expect(feedback.soundEnabled, isTrue);
    expect(feedback.hapticsEnabled, isTrue);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Sound Effects'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('sound_switch')));
    await tester.tap(find.byKey(const ValueKey('haptics_switch')));
    await tester.pumpAndSettle();
    expect(feedback.soundEnabled, isFalse);
    expect(feedback.hapticsEnabled, isFalse);
    final prefs = await tester.runAsync(SharedPreferences.getInstance);
    expect(prefs!.getBool('settings_sound'), isFalse);
    expect(prefs.getBool('settings_haptics'), isFalse);

    // 닫기 버튼으로 창이 닫혀야 함
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Sound Effects'), findsNothing);

    // 완성 축하 창: 한 칸만 밀면 완성되는 게임에서 마지막 타일을 밀면
    // 신기록·TOP 5 순위와 함께 축하 창이 떠야 함
    home.value = Number8Screen(
      key: UniqueKey(),
      showAd: false,
      savedGame: const SavedGame(
        tiles: [1, 2, 3, 4, 5, 6, 7, 0, 8],
        moves: 5,
        seconds: 10,
      ),
    );
    await tester.pump();
    await tester.tap(find.text('8'));
    await waitFor(find.text('Puzzle Completed!'));
    await tester.pumpAndSettle();
    expect(find.text('Puzzle Completed!'), findsOneWidget);
    expect(find.text('New Record!'), findsOneWidget);
    expect(find.text('#1 in Top 5'), findsOneWidget);
    expect(find.text('NEW'), findsNWidgets(2)); // 이동·시간 모두 신기록
    expect(find.text('6'), findsWidgets); // 이번 이동 횟수
    expect(tester.takeException(), isNull);
    // 완성했으므로 이어하기 저장은 지워짐
    expect(
      await tester.runAsync(
        () => GameSaveStore.load(Number8Screen.puzzleType, 9),
      ),
      isNull,
    );

    // 다시 하기 → 창이 닫히고 새 게임(0번 이동)
    await tester.tap(find.text('Play Again'));
    await tester.pumpAndSettle();
    expect(find.text('Puzzle Completed!'), findsNothing);
    expect(find.text('0'), findsOneWidget);

    // 화면을 떠나며 타이머 정리
    home.value = const SizedBox();
    await tester.pump();
  });
}
