import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:number_puzzle1/game_save.dart';
import 'package:number_puzzle1/screen/home_screen.dart';
import 'package:number_puzzle1/screen/puzzle_screen.dart';
import 'package:number_puzzle1/screen/records_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'saved_game_puzzle_8':
          '{"tiles":[1,2,3,4,5,6,7,0,8],"moves":123,"seconds":3599}',
      'best_moves_puzzle_15': 9999,
      'best_time_puzzle_15': 5999,
      'records_clears_puzzle_15': 999,
      'records_top_puzzle_15':
          '[{"moves":9999,"seconds":5999,"date":1795000000000}]',
    });
    await EasyLocalization.ensureInitialized();
  });

  // 한국어 문구로 작은 화면(320x568)에서도 화면이 넘치지 않아야 함
  testWidgets('한국어: 모든 화면이 작은 화면에서 넘치지 않음', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(320, 568) * 3.0;
    addTearDown(tester.view.reset);

    final home = ValueNotifier<Widget>(const SizedBox());
    addTearDown(home.dispose);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ko')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('ko'),
        saveLocale: false,
        child: Builder(
          builder:
              (context) => MaterialApp(
                // 기본 UI(버튼·대화상자 등)의 한국어 번역: material_ui용 delegate가 필요
                localizationsDelegates: [
                  ...context.localizationDelegates,
                  ...GlobalMaterialLocalizations.delegates,
                ],
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

    Future<void> show(Widget screen, Finder ready) async {
      home.value = screen;
      await tester.pump();
      for (var i = 0; i < 50 && ready.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 300));
      expect(ready, findsWidgets, reason: '$screen');
      expect(tester.takeException(), isNull, reason: '$screen');
    }

    await show(const HomeScreen(), find.textContaining('이어하기'));
    await show(const RecordsScreen(initialIndex: 1), find.text('최소 이동'));
    await show(
      Number8Screen(
        key: UniqueKey(),
        showAd: false,
        savedGame: const SavedGame(
          tiles: [1, 2, 3, 4, 5, 6, 7, 0, 8],
          moves: 9998,
          seconds: 5998,
        ),
      ),
      find.text('3 x 3 퍼즐'),
    );
    await show(
      Number15Screen(key: UniqueKey(), showAd: false),
      find.textContaining('최고기록'),
    );
    await show(
      Number24Screen(key: UniqueKey(), showAd: false),
      find.text('5 x 5 퍼즐'),
    );

    // 설정 창과 완성 축하 창(3x3 마지막 타일)
    home.value = Number8Screen(
      key: UniqueKey(),
      showAd: false,
      savedGame: const SavedGame(
        tiles: [1, 2, 3, 4, 5, 6, 7, 0, 8],
        moves: 9998,
        seconds: 5998,
        hints: 99,
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();
    expect(find.text('효과음'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('8'));
    for (var i = 0; i < 50 && find.text('퍼즐 완성!').evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.textContaining('힌트 사용'), findsOneWidget);
    expect(tester.takeException(), isNull);

    home.value = const SizedBox();
    await tester.pump();
  });
}
