import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:number_puzzle1/game_save.dart';
import 'package:number_puzzle1/screen/home_screen.dart';
import 'package:number_puzzle1/screen/puzzle_screen.dart';
import 'package:number_puzzle1/screen/records_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _saved3x3 = '{"tiles":[1,2,3,4,5,6,7,0,8],"moves":7,"seconds":42}';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  // easy_localization은 테스트마다 다시 띄우면 번역 로딩이 끝나지 않으므로
  // 앱을 한 번만 띄우고 시나리오를 이어서 검사한다.
  testWidgets('이어하기 확인 창과 기록 화면', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(412, 915) * 3.0;
    addTearDown(tester.view.reset);

    final prefs = (await tester.runAsync(SharedPreferences.getInstance))!;
    await prefs.setString('saved_game_puzzle_8', _saved3x3);

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
                home: const HomeScreen(),
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
      await tester.pump(const Duration(milliseconds: 400));
    }

    // 1) 저장된 게임이 있는 퍼즐만 홈 버튼에 이어하기 표시
    await waitFor(find.text('Continue · 7 moves · 00:42'));
    expect(find.text('Continue · 7 moves · 00:42'), findsOneWidget);
    expect(find.textContaining('Continue ·'), findsOneWidget); // 3x3만

    // 2) 저장된 게임이 있는 퍼즐을 누르면 이어할지 물어봄 → 바깥을 누르면 취소
    await tester.tap(find.text('3x3 Puzzle'));
    await waitFor(find.text('Continue?'));
    expect(find.text('Continue?'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Continue?'), findsNothing);
    expect(find.byType(Number8Screen), findsNothing);

    // 3) 이어하기 → 저장된 이동 횟수·시간으로 시작
    await tester.tap(find.text('3x3 Puzzle'));
    await waitFor(find.text('Continue?'));
    await tester.tap(find.text('Continue').last);
    await waitFor(find.byType(Number8Screen));
    expect(find.byType(Number8Screen), findsOneWidget);
    expect(find.text('00:42'), findsOneWidget);
    expect(find.text('7'), findsWidgets);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle(); // 화면 전환 완료까지 대기
    await waitFor(find.text('Continue · 7 moves · 00:42'));

    // 4) 새 게임 → 저장된 게임이 지워지고 0번 이동으로 시작
    await tester.tap(find.text('3x3 Puzzle'));
    await waitFor(find.text('Continue?'));
    await tester.tap(find.text('New Game'));
    await waitFor(find.byType(Number8Screen));
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    final cleared = await tester.runAsync(
      () => GameSaveStore.load(Number8Screen.puzzleType, 9),
    );
    expect(cleared, isNull);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle(); // 화면 전환 완료까지 대기
    await waitFor(find.text('Records'));
    // 한 번도 움직이지 않았으므로 이어하기 표시 없음
    expect(find.textContaining('Continue ·'), findsNothing);

    // 5) 기록 화면: 기록이 있으면 표시, 탭으로 난이도 전환
    await prefs.setInt('best_moves_puzzle_8', 31);
    await prefs.setInt('best_time_puzzle_8', 65);
    await prefs.setInt('records_clears_puzzle_8', 3);
    await prefs.setString(
      'records_top_puzzle_8',
      '[{"moves":31,"seconds":65,"date":1795000000000},'
          '{"moves":40,"seconds":80,"date":1795000000000}]',
    );
    // 작은 화면에서도 넘치지 않아야 함
    tester.view.physicalSize = const Size(320, 568) * 3.0;
    await tester.tap(find.text('Records'));
    await waitFor(find.byType(RecordsScreen));
    await waitFor(find.text('Fewest Moves'));
    expect(find.text('Fewest Moves'), findsOneWidget);
    expect(find.text('31'), findsWidgets);
    expect(find.text('01:05'), findsWidgets);
    expect(find.text('Completed 3 times'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('5x5 Puzzle'));
    await tester.pumpAndSettle();
    expect(
      find.text('No records yet.\nComplete a puzzle to set one!'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
