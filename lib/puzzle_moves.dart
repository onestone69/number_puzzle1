import 'dart:math';

/// 빈칸과 같은 줄(가로·세로)에 있는 [index] 칸을 밀었을 때,
/// 한 칸씩 옮기는 순서대로 눌러야 할 칸 번호 목록.
///
/// 예) 3x3에서 빈칸이 0, [index]가 2이면 [1, 2]
/// (1을 빈칸으로 → 2를 빈 1로). 같은 줄이 아니거나 빈칸이면 빈 목록.
List<int> slideSteps(int index, int empty, int size) {
  if (index == empty) return const [];
  final int step;
  if (index ~/ size == empty ~/ size) {
    step = index > empty ? 1 : -1; // 같은 가로줄
  } else if (index % size == empty % size) {
    step = index > empty ? size : -size; // 같은 세로줄
  } else {
    return const [];
  }
  final steps = <int>[];
  for (var i = empty + step; ; i += step) {
    steps.add(i);
    if (i == index) return steps;
  }
}

/// 새 게임용으로 섞은 판.
///
/// 완성 상태에서 무작위로 움직여 섞으므로 항상 풀 수 있다.
/// 방금 한 이동을 바로 되돌리지 않고, 너무 쉽게(완성에 가깝게) 섞인 판은
/// 다시 섞는다.
List<int> shuffledBoard(int size, Random random, {int moves = 150}) {
  final count = size * size;
  // 타일들이 제자리에서 떨어진 거리의 합이 이 값 이상이 되도록
  final minDistance = count + size;
  while (true) {
    final tiles = List.generate(count, (i) => i == count - 1 ? 0 : i + 1);
    var empty = count - 1;
    var previous = -1;
    for (var k = 0; k < moves; k++) {
      final options = [
        if (empty >= size) empty - size,
        if (empty < count - size) empty + size,
        if (empty % size > 0) empty - 1,
        if (empty % size < size - 1) empty + 1,
      ]..remove(previous); // 바로 되돌리기 금지
      final next = options[random.nextInt(options.length)];
      tiles[empty] = tiles[next];
      tiles[next] = 0;
      previous = empty;
      empty = next;
    }
    if (manhattanDistance(tiles, size) >= minDistance) return tiles;
  }
}

/// 각 타일이 제자리에서 떨어진 가로+세로 거리의 합
int manhattanDistance(List<int> tiles, int size) {
  var total = 0;
  for (var i = 0; i < tiles.length; i++) {
    final v = tiles[i];
    if (v == 0) continue;
    total +=
        ((v - 1) ~/ size - i ~/ size).abs() + ((v - 1) % size - i % size).abs();
  }
  return total;
}
