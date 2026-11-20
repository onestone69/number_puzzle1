import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:number_puzzle1/puzzle_solver.dart';

/// 게임과 같은 방식(완성 상태에서 무작위 이동)으로 섞은 판
List<int> shuffled(int n, int moves, Random r) {
  final t = List.generate(n * n, (i) => i == n * n - 1 ? 0 : i + 1);
  var e = n * n - 1, prev = -1;
  for (var k = 0; k < moves; k++) {
    final opts = [
      if (e >= n) e - n,
      if (e < n * n - n) e + n,
      if (e % n > 0) e - 1,
      if (e % n < n - 1) e + 1,
    ]..remove(prev);
    final m = opts[r.nextInt(opts.length)];
    t[e] = t[m];
    t[m] = 0;
    prev = e;
    e = m;
  }
  return t;
}

/// 풀이대로 칸을 눌렀을 때 완성되는지 확인
bool applies(List<int> tiles, int n, List<int> path) {
  final t = List.of(tiles);
  var e = t.indexOf(0);
  for (final i in path) {
    final adjacent =
        (i - e).abs() == n || ((i - e).abs() == 1 && i ~/ n == e ~/ n);
    if (!adjacent) return false;
    t[e] = t[i];
    t[i] = 0;
    e = i;
  }
  for (var i = 0; i < t.length - 1; i++) {
    if (t[i] != i + 1) return false;
  }
  return true;
}

void main() {
  test('이미 완성된 판은 빈 풀이', () {
    expect(PuzzleSolver(3).solve([1, 2, 3, 4, 5, 6, 7, 8, 0]), isEmpty);
  });

  test('한 수 남은 판은 그 한 수', () {
    expect(PuzzleSolver(3).solve([1, 2, 3, 4, 5, 6, 7, 0, 8]), [8]);
  });

  test('풀 수 없는 판은 null', () {
    expect(PuzzleSolver(3).solve([2, 1, 3, 4, 5, 6, 7, 8, 0]), isNull);
  });

  test('3x3은 최단 풀이 (알려진 최장 31수 배치)', () {
    final path = PuzzleSolver(3).solve([8, 6, 7, 2, 5, 4, 3, 0, 1])!;
    expect(path.length, 31);
    expect(applies([8, 6, 7, 2, 5, 4, 3, 0, 1], 3, path), isTrue);
  });

  for (final n in [3, 4, 5]) {
    test('${n}x$n: 게임처럼 섞은 판을 빠르게 풂', () {
      final r = Random(n);
      final sw = Stopwatch()..start();
      var worst = Duration.zero;
      for (var k = 0; k < 20; k++) {
        final tiles = shuffled(n, 100 + k * 10, r); // 게임보다 더 많이 섞음
        final t0 = sw.elapsed;
        final path = PuzzleSolver(n).solve(tiles);
        final took = sw.elapsed - t0;
        if (took > worst) worst = took;
        expect(path, isNotNull, reason: '$tiles');
        expect(applies(tiles, n, path!), isTrue, reason: '$tiles');
      }
      // ignore: avoid_print
      print(
        '${n}x$n: 20판 ${sw.elapsedMilliseconds}ms, 가장 오래 걸린 판 ${worst.inMilliseconds}ms',
      );
      expect(worst, lessThan(const Duration(seconds: 3)));
    });
  }

  test('아주 많이 섞인 판(4x4·5x5)도 시간 안에 풂', () {
    final r = Random(42);
    for (final n in [4, 5]) {
      for (var k = 0; k < 5; k++) {
        final tiles = shuffled(n, 3000, r);
        final sw = Stopwatch()..start();
        final path = PuzzleSolver(n).solve(tiles);
        // ignore: avoid_print
        print(
          '${n}x$n 3000수 섞음: ${sw.elapsedMilliseconds}ms, 풀이 ${path?.length}수',
        );
        expect(path, isNotNull);
        expect(applies(tiles, n, path!), isTrue);
        expect(sw.elapsed, lessThan(const Duration(seconds: 8)));
      }
    }
  });
}
