// 플레이 스토어 등록용 이미지를 앱 화면으로 직접 렌더링한다.
//
// 다시 만들려면:
//   flutter test tool/render_store_assets_test.dart --update-goldens
//   tool/convert_store_assets.sh
//
// 결과 (PNG, 이후 변환 스크립트가 JPEG로 변환):
//   store_assets/raw/{en,ko}/NN_*.png      앱 화면 그대로 (1080x1920)
//   store_assets/framed/{en,ko}/NN_*.png   설명 문구 + 기기 틀 (1080x1920)
//   store_assets/feature_graphic.png       그래픽 이미지 (1024x500)
import 'dart:io';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:number_puzzle1/app_color.dart';
import 'package:number_puzzle1/game_save.dart';
import 'package:number_puzzle1/screen/home_screen.dart';
import 'package:number_puzzle1/screen/puzzle_screen.dart';
import 'package:number_puzzle1/screen/records_screen.dart';
import 'package:number_puzzle1/widgets/game_ui_3d.dart';
import 'package:number_puzzle1/widgets/puzzle_board_3d.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _out = '../store_assets';

/// 스크린샷 순서·배경색·설명 문구
const _shots = <(String, Color, String, String)>[
  (
    '01_home',
    Color(0xFFE8A0B4),
    'Three sizes,\ncontinue anytime',
    '3가지 크기, 언제든 이어하기',
  ),
  (
    '02_slide',
    AppColor.puzzle8MenuBackground,
    'Tap, drag, or\nslide a whole row',
    '탭·드래그·한 줄 통째로 밀기',
  ),
  (
    '03_hint',
    AppColor.puzzle15MenuBackground,
    'Stuck?\nGet a hint',
    '막히면 힌트로 다음 수 확인',
  ),
  (
    '04_complete',
    AppColor.puzzle24MenuBackground,
    'Beat your best &\nreach the Top 5',
    '최고 기록과 TOP 5에 도전',
  ),
  ('05_records', recordsColor, 'Records for\nevery size', '난이도별 기록을 한눈에'),
  (
    '06_settings',
    Color(0xFF9E7676),
    'Sound effects\nand haptics',
    '효과음과 진동 설정',
  ),
];

Future<void> _loadFont(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}

String _materialIconsPath() {
  final flutterRoot =
      File(
        Platform.resolvedExecutable,
      ).parent.parent.parent.parent.parent.parent.path;
  final candidates = [
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ];
  return candidates.firstWhere((p) => File(p).existsSync());
}

void main() {
  setUpAll(() async {
    final day = DateTime(2026, 11, 21).millisecondsSinceEpoch;
    String top(List<(int, int)> entries) =>
        '[${entries.map((e) => '{"moves":${e.$1},"seconds":${e.$2},"date":$day}').join(',')}]';
    // tool/은 분석기가 테스트 폴더로 보지 않지만 flutter test로만 실행함
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      // 홈 화면의 이어하기 표시
      'saved_game_puzzle_8':
          '{"tiles":[4,1,3,0,2,6,7,5,8],"moves":14,"seconds":37,"hints":0}',
      // 기록
      'best_moves_puzzle_8': 22,
      'best_time_puzzle_8': 31,
      'records_clears_puzzle_8': 27,
      'records_top_puzzle_8': top([
        (24, 31),
        (22, 36),
        (28, 44),
        (31, 52),
        (40, 68),
      ]),
      'best_moves_puzzle_15': 86,
      'best_time_puzzle_15': 142,
      'records_clears_puzzle_15': 8,
      'records_top_puzzle_15': top([(86, 142), (97, 171)]),
      // 효과음·진동 설정 (기본값)
      'settings_sound': true,
      'settings_haptics': true,
      'settings_volume': 0.8,
    });
    await EasyLocalization.ensureInitialized();
    await _loadFont('HiMelody', 'assets/fonts/HiMelody-Regular.ttf');
    await _loadFont('MaterialIcons', _materialIconsPath());
  });

  testWidgets('스토어 이미지 렌더링', (tester) async {
    // ───────── 1) 앱 화면 (1080x1920) ─────────
    tester.view.devicePixelRatio = 2.625;
    tester.view.physicalSize = const Size(1080, 1920);
    addTearDown(tester.view.reset);

    final home = ValueNotifier<Widget>(const SizedBox());
    late BuildContext appContext;
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ko')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        saveLocale: false,
        child: Builder(
          builder: (context) {
            appContext = context;
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              localizationsDelegates: [
                ...context.localizationDelegates,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              theme: ThemeData(fontFamily: 'HiMelody'),
              home: ValueListenableBuilder<Widget>(
                valueListenable: home,
                builder: (_, child, _) => child,
              ),
            );
          },
        ),
      ),
    );

    Future<void> realWait([int ms = 20]) =>
        tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
        await realWait();
        await tester.pump();
      }
      expect(finder, findsWidgets);
    }

    Future<void> shoot(String lang, String name) => expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('$_out/raw/$lang/$name.png'),
    );

    for (final lang in ['en', 'ko']) {
      await tester.runAsync(() => appContext.setLocale(Locale(lang)));
      await realWait(100);
      await tester.pump();
      String tr(String key) => key.tr();

      // 01 홈 (언어마다 같은 장면이 되도록 3x3만 이어하기 상태로)
      final prefsForHome =
          (await tester.runAsync(SharedPreferences.getInstance))!;
      await prefsForHome.remove('saved_game_puzzle_15');
      await prefsForHome.remove('saved_game_puzzle_24');
      home.value = HomeScreen(key: UniqueKey());
      await tester.pump();
      await waitFor(find.textContaining(tr('continue_resume')));
      await tester.pump(const Duration(milliseconds: 500));
      await shoot(lang, '01_home');

      // 02 3x3: 한 줄 통째로 끄는 중 (2, 6이 함께 빈칸 쪽으로)
      home.value = Number8Screen(
        key: UniqueKey(),
        showAd: false,
        savedGame: const SavedGame(
          tiles: [4, 1, 3, 0, 2, 6, 7, 5, 8],
          moves: 14,
          seconds: 37,
        ),
      );
      await tester.pump();
      await waitFor(find.textContaining(tr('home_puzzle_3')));
      await tester.pump(const Duration(milliseconds: 300));
      final six = tester.getCenter(find.text('6'));
      final drag = await tester.startGesture(six);
      for (var i = 0; i < 6; i++) {
        await drag.moveBy(const Offset(-12, 0));
        await tester.pump();
      }
      await shoot(lang, '02_slide');
      await drag.moveBy(const Offset(72, 0));
      await drag.up();
      await tester.pump(const Duration(milliseconds: 300));

      // 03 4x4: 힌트 (7을 위로)
      home.value = Number15Screen(
        key: UniqueKey(),
        showAd: false,
        savedGame: const SavedGame(
          tiles: [1, 2, 3, 4, 5, 6, 0, 8, 9, 10, 7, 11, 13, 14, 15, 12],
          moves: 23,
          seconds: 71,
        ),
      );
      await tester.pump();
      await waitFor(find.textContaining(tr('home_puzzle_4')));
      await tester.tap(find.byTooltip(tr('menu_hint')));
      await waitFor(find.bySemanticsLabel(RegExp('^hint')));
      await tester.pump(const Duration(milliseconds: 650)); // 들썩임 최대
      await shoot(lang, '03_hint');

      // 04 5x5: 완성 축하 창 (마지막 타일 24를 밀어 완성)
      home.value = Number24Screen(
        key: UniqueKey(),
        showAd: false,
        savedGame: SavedGame(
          tiles: [for (var v = 1; v <= 23; v++) v, 0, 24],
          moves: 186,
          seconds: 312,
        ),
      );
      await tester.pump();
      await waitFor(find.textContaining(tr('home_puzzle_5')));
      await tester.tap(find.text('24'));
      await waitFor(find.text(tr('completion_title')));
      await tester.pump(const Duration(milliseconds: 1100)); // 색종이가 흩날리는 중
      await shoot(lang, '04_complete');
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.text(tr('completion_close')));
      await tester.pumpAndSettle();
      // 다음 언어에서도 같은 결과가 나오도록 5x5 기록 초기화
      final prefs = (await tester.runAsync(SharedPreferences.getInstance))!;
      for (final key in [
        'best_moves_puzzle_24',
        'best_time_puzzle_24',
        'records_clears_puzzle_24',
        'records_top_puzzle_24',
      ]) {
        await prefs.remove(key);
      }

      // 05 기록
      home.value = RecordsScreen(key: UniqueKey());
      await tester.pump();
      await waitFor(find.text(tr('records_best_moves')));
      await tester.pump(const Duration(milliseconds: 300));
      await shoot(lang, '05_records');

      // 06 설정 창 (5x5 게임 위)
      home.value = Number24Screen(
        key: UniqueKey(),
        showAd: false,
        savedGame: SavedGame(
          tiles: [
            1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, //
            16, 22, 17, 19, 20, 21, 0, 18, 23, 24,
          ],
          moves: 41,
          seconds: 95,
        ),
      );
      await tester.pump();
      await waitFor(find.textContaining(tr('home_puzzle_5')));
      await tester.tap(find.byTooltip(tr('settings_tooltip')));
      await tester.pumpAndSettle();
      await shoot(lang, '06_settings');
      await tester.tap(find.text(tr('settings_close')));
      await tester.pumpAndSettle();
    }
    home.value = const SizedBox();
    await tester.pump();
  });

  testWidgets('설명 문구 + 기기 틀 스크린샷', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1080, 1920);
    addTearDown(tester.view.reset);

    for (final lang in ['en', 'ko']) {
      for (final (name, color, en, ko) in _shots) {
        final bytes =
            File('store_assets/raw/$lang/$name.png').readAsBytesSync();
        final image = MemoryImage(bytes);
        await tester.pumpWidget(
          _FramedShot(
            color: color,
            caption: lang == 'en' ? en : ko,
            image: image,
          ),
        );
        await tester.runAsync(
          () => precacheImage(image, tester.element(find.byType(_FramedShot))),
        );
        await tester.pump();
        await expectLater(
          find.byType(_FramedShot),
          matchesGoldenFile('$_out/framed/$lang/$name.png'),
        );
      }
    }
  });

  testWidgets('그래픽 이미지 (1024x500)', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1024, 500);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const _FeatureGraphic());
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(_FeatureGraphic),
      matchesGoldenFile('$_out/feature_graphic.png'),
    );
  });
}

/// 입체 글자 스타일 (홈 화면 제목과 같은 방식: 아래로 겹친 그림자)
TextStyle _extruded(double size, Color color, Color side) => TextStyle(
  fontFamily: 'HiMelody',
  fontSize: size,
  fontWeight: FontWeight.bold,
  color: color,
  height: 1.15,
  shadows: [
    for (var i = 1; i <= 6; i++)
      Shadow(color: side, offset: Offset(0, i * size / 60)),
    Shadow(
      color: Colors.black.withValues(alpha: 0.25),
      offset: Offset(0, size / 7),
      blurRadius: size / 6,
    ),
  ],
);

/// 위에 설명 문구, 아래에 기기 틀 안의 앱 화면
class _FramedShot extends StatelessWidget {
  const _FramedShot({
    required this.color,
    required this.caption,
    required this.image,
  });

  final Color color;
  final String caption;
  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    const screenW = 740.0;
    const screenH = screenW * 1920 / 1080;
    const bezel = 22.0;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        child: Container(
          width: 1080,
          height: 1920,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [shadeColor(color, 0.35), shadeColor(color, -0.15)],
            ),
          ),
          child: Stack(
            children: [
              // 설명 문구
              Positioned(
                left: 60,
                right: 60,
                top: 110,
                height: 260,
                child: Center(
                  child: Text(
                    caption,
                    textAlign: TextAlign.center,
                    style: _extruded(
                      84,
                      Colors.white,
                      shadeColor(color, -0.45),
                    ),
                  ),
                ),
              ),
              // 기기 틀 (특정 제품이 아닌 단순한 둥근 틀)
              Positioned(
                left: (1080 - screenW) / 2 - bezel,
                top: 410,
                child: Container(
                  width: screenW + bezel * 2,
                  height: screenH + bezel * 2,
                  padding: const EdgeInsets.all(bezel),
                  decoration: BoxDecoration(
                    color: const Color(0xFF26262B),
                    borderRadius: BorderRadius.circular(78),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 60,
                        offset: const Offset(0, 30),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(58),
                    child: Image(
                      image: image,
                      width: screenW,
                      height: screenH,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 그래픽 이미지: 입체 보드 + 앱 이름 + 크기 배지
class _FeatureGraphic extends StatelessWidget {
  const _FeatureGraphic();

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF8E8EE);
    const titleColor = Color(0xFF9E7676);
    Widget chip(String text, Color color) => Raised3D(
      color: color,
      radius: 18,
      depth: 6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'HiMelody',
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: shadeColor(color, -0.5),
                offset: const Offset(0, 2),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        child: Container(
          width: 1024,
          height: 500,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.45, -0.2),
              radius: 1.3,
              colors: [shadeColor(bg, 0.5), shadeColor(bg, -0.08)],
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 70),
              Transform.rotate(
                angle: -0.08,
                child: const SizedBox(
                  width: 370,
                  height: 370,
                  child: PuzzleBoard3D(
                    tiles: [1, 2, 3, 4, 5, 6, 7, 0, 8],
                    gridSize: 3,
                    tileColor: AppColor.puzzle15Tile,
                    textColor: AppColor.puzzle15Text,
                    emptyColor: AppColor.puzzle15Empty,
                    frameColor: AppColor.puzzle15MenuBackground,
                    onTileTap: _noop,
                  ),
                ),
              ),
              const SizedBox(width: 50),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sliding\nPuzzle',
                      style: _extruded(
                        104,
                        titleColor,
                        shadeColor(titleColor, -0.35),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        chip('3x3', AppColor.puzzle8MenuBackground),
                        const SizedBox(width: 14),
                        chip('4x4', AppColor.puzzle15MenuBackground),
                        const SizedBox(width: 14),
                        chip('5x5', AppColor.puzzle24MenuBackground),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _noop(int _) {}
