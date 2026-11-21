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
