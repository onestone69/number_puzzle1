import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:number_puzzle1/puzzle_moves.dart';
import 'package:number_puzzle1/puzzle_solver.dart';

void main() {
  test('빈칸 바로 옆 타일은 한 칸', () {
    expect(slideSteps(1, 0, 3), [1]);
    expect(slideSteps(3, 0, 3), [3]);
  });

  test('같은 가로줄의 먼 타일은 빈칸 쪽부터 차례로', () {
    // 3x3: 빈칸 0, 2번 칸을 밀면 1 → 2 순서
    expect(slideSteps(2, 0, 3), [1, 2]);
    // 4x4: 빈칸 7(오른쪽 끝), 4번 칸(왼쪽 끝)을 밀면 6, 5, 4
    expect(slideSteps(4, 7, 4), [6, 5, 4]);
  });

  test('같은 세로줄의 먼 타일', () {
    // 5x5: 빈칸 2(맨 위), 22번 칸(맨 아래)을 밀면 7, 12, 17, 22
    expect(slideSteps(22, 2, 5), [7, 12, 17, 22]);
    expect(slideSteps(1, 13, 4), [9, 5, 1]);
  });

  test('같은 줄이 아니거나 빈칸 자신이면 움직일 수 없음', () {
    expect(slideSteps(4, 0, 3), isEmpty); // 대각선
    expect(slideSteps(0, 0, 3), isEmpty);
    // 줄이 바뀌는 칸(3x3의 2와 3)은 같은 가로줄이 아님
    expect(slideSteps(3, 2, 3), isEmpty);
  });

  test('섞은 판은 항상 풀 수 있고, 완성에 가깝지 않음', () {
    final random = Random(1);
    for (final n in [3, 4, 5]) {
      for (var k = 0; k < 200; k++) {
        final tiles = shuffledBoard(n, random);
        expect(tiles.toSet().length, n * n);
        expect(PuzzleSolver(n).isSolvable(tiles), isTrue);
        expect(manhattanDistance(tiles, n), greaterThanOrEqualTo(n * n + n));
      }
    }
  });
}
