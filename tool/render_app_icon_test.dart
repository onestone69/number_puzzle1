// 앱 아이콘 이미지를 앱의 입체 보드 위젯으로 렌더링한다.
//
// 다시 만들려면:
//   flutter test tool/render_app_icon_test.dart --update-goldens
//   dart run flutter_launcher_icons
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:number_puzzle1/app_color.dart';
import 'package:number_puzzle1/widgets/game_ui_3d.dart';
import 'package:number_puzzle1/widgets/puzzle_board_3d.dart';

Future<void> _loadFont(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}

/// 크림색 배경 (게임 화면 배경과 같은 계열)
Widget _background() {
  const bg = AppColor.puzzle15Background;
  return DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: const Alignment(0, -0.3),
        radius: 1.0,
        colors: [shadeColor(bg, 0.55), shadeColor(bg, -0.06)],
      ),
    ),
  );
}

/// 한 칸만 밀면 완성되는 3x3 보드
Widget _board(double side) {
  return SizedBox(
    width: side,
    height: side,
    child: PuzzleBoard3D(
      tiles: const [1, 2, 3, 4, 5, 6, 7, 0, 8],
      gridSize: 3,
      tileColor: AppColor.puzzle15Tile,
      textColor: AppColor.puzzle15Text,
      emptyColor: AppColor.puzzle15Empty,
      frameColor: AppColor.puzzle15MenuBackground,
      onTileTap: (_) {},
    ),
  );
}

void main() {
  setUpAll(() => _loadFont('HiMelody', 'assets/fonts/HiMelody-Regular.ttf'));

  Future<void> render(WidgetTester tester, Widget child, String name) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1024, 1024);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: const ValueKey('icon'),
          child: SizedBox(width: 1024, height: 1024, child: child),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await expectLater(
      find.byKey(const ValueKey('icon')),
      matchesGoldenFile('../assets/icon/$name.png'),
    );
  }

  testWidgets('앱 아이콘 렌더링', (tester) async {
    // iOS·구형 Android용 전체 아이콘
    await render(
      tester,
      Stack(
        children: [
          Positioned.fill(child: _background()),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _board(800),
            ),
          ),
        ],
      ),
      'app_icon',
    );
    // Android 적응형 아이콘: 배경 / 앞면 (기기별 모양으로 잘려도 보이도록 안전 영역 안에 보드)
    await render(tester, _background(), 'icon_background');
    await render(
      tester,
      Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _board(500),
        ),
      ),
      'icon_foreground',
    );
  });
}
