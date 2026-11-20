import 'dart:typed_data';

/// 슬라이딩 퍼즐 풀이기 (힌트용).
///
/// A* 탐색에 맨해튼 거리 + 선형 충돌(linear conflict) 휴리스틱을 쓴다.
/// - 3x3: 가중치 1 → 최단 풀이
/// - 4x4, 5x5: 가중치를 두어(weighted A*) 최단은 아니어도 빠르게 풀이를 찾는다.
///   탐색 노드가 한도를 넘으면 가중치를 높여 다시 시도한다.
class PuzzleSolver {
  PuzzleSolver(this.size)
    : _goalRow = Int8List(size * size),
      _goalCol = Int8List(size * size) {
    // 숫자 v(1..n-1)의 목표 위치는 v-1, 빈칸(0)은 마지막 칸
    for (var v = 1; v < size * size; v++) {
      _goalRow[v] = (v - 1) ~/ size;
      _goalCol[v] = (v - 1) % size;
    }
  }

  final int size;
  final Int8List _goalRow;
  final Int8List _goalCol;

  /// [tiles]에서 완성까지 눌러야 할 칸 번호(index) 목록. 풀 수 없으면 null.
  List<int>? solve(List<int> tiles, {int maxNodes = 300000}) {
    assert(tiles.length == size * size);
    if (!isSolvable(tiles)) return null;
    if (_isGoal(tiles)) return const [];

    final weights = switch (size) {
      3 => [1.0, 1.5, 3.0],
      4 => [1.5, 2.5, 5.0, 10.0],
      _ => [2.0, 3.5, 6.0, 12.0],
    };
    for (final w in weights) {
      final path = _aStar(Uint8List.fromList(tiles), w, maxNodes);
      if (path != null) return path;
    }
    return null;
  }

  /// 슬라이딩 퍼즐의 풀이 가능 여부 (반전 수 기준)
  bool isSolvable(List<int> tiles) {
    var inversions = 0;
    final values = tiles.where((v) => v != 0).toList();
    for (var i = 0; i < values.length; i++) {
      for (var j = i + 1; j < values.length; j++) {
        if (values[i] > values[j]) inversions++;
      }
    }
    if (size.isOdd) return inversions.isEven;
    final blankRowFromBottom = size - tiles.indexOf(0) ~/ size;
    return (inversions + blankRowFromBottom).isOdd;
  }

  bool _isGoal(List<int> tiles) {
    for (var i = 0; i < tiles.length - 1; i++) {
      if (tiles[i] != i + 1) return false;
    }
    return true;
  }

  /// 맨해튼 거리 + 선형 충돌
  int _heuristic(Uint8List t) {
    final n = size;
    var h = 0;
    for (var i = 0; i < t.length; i++) {
      final v = t[i];
      if (v == 0) continue;
      h += (_goalRow[v] - i ~/ n).abs() + (_goalCol[v] - i % n).abs();
    }
    // 같은 줄에 목표가 있는데 순서가 뒤바뀐 쌍마다 +2
    for (var r = 0; r < n; r++) {
      for (var a = 0; a < n; a++) {
        final va = t[r * n + a];
        if (va == 0 || _goalRow[va] != r) continue;
        for (var b = a + 1; b < n; b++) {
          final vb = t[r * n + b];
          if (vb != 0 && _goalRow[vb] == r && _goalCol[vb] < _goalCol[va]) {
            h += 2;
          }
        }
      }
    }
    for (var c = 0; c < n; c++) {
      for (var a = 0; a < n; a++) {
        final va = t[a * n + c];
        if (va == 0 || _goalCol[va] != c) continue;
        for (var b = a + 1; b < n; b++) {
          final vb = t[b * n + c];
          if (vb != 0 && _goalCol[vb] == c && _goalRow[vb] < _goalRow[va]) {
            h += 2;
          }
        }
      }
    }
    return h;
  }

  List<int>? _aStar(Uint8List start, double weight, int maxNodes) {
    final n = size;
    // 노드 정보 (배열로 관리해 메모리 절약)
    final states = <Uint8List>[start];
    final parents = <int>[-1];
    final moved = <int>[-1]; // 이 상태로 오기 위해 누른 칸
    final gCost = <int>[0];
    final blank = <int>[start.indexOf(0)];
    final bestG = <String, int>{String.fromCharCodes(start): 0};
    final open = _MinHeap()..push(weight * _heuristic(start), 0);

    while (open.isNotEmpty) {
      final node = open.pop();
      final state = states[node];
      final g = gCost[node];
      if (bestG[String.fromCharCodes(state)]! < g) continue; // 더 짧은 경로로 이미 방문
      if (_isGoal(state)) return _path(node, parents, moved);
      if (states.length > maxNodes) return null;

      final e = blank[node];
      final er = e ~/ n, ec = e % n;
      for (final next in [
        if (er > 0) e - n,
        if (er < n - 1) e + n,
        if (ec > 0) e - 1,
        if (ec < n - 1) e + 1,
      ]) {
        if (parents[node] >= 0 && next == blank[parents[node]]) {
          continue; // 바로 되돌리는 수는 건너뜀
        }
        final child = Uint8List.fromList(state);
        child[e] = child[next];
        child[next] = 0;
        final key = String.fromCharCodes(child);
        final ng = g + 1;
        final known = bestG[key];
        if (known != null && known <= ng) continue;
        bestG[key] = ng;
        states.add(child);
        parents.add(node);
        moved.add(next);
        gCost.add(ng);
        blank.add(next);
        open.push(ng + weight * _heuristic(child), states.length - 1);
      }
    }
    return null;
  }

  List<int> _path(int node, List<int> parents, List<int> moved) {
    final path = <int>[];
    for (var i = node; parents[i] >= 0; i = parents[i]) {
      path.add(moved[i]);
    }
    return path.reversed.toList();
  }
}

/// 우선순위 큐 (값이 작은 노드부터)
class _MinHeap {
  final _keys = <double>[];
  final _items = <int>[];

  bool get isNotEmpty => _items.isNotEmpty;

  void push(double key, int item) {
    _keys.add(key);
    _items.add(item);
    var i = _items.length - 1;
    while (i > 0) {
      final p = (i - 1) >> 1;
      if (_keys[p] <= _keys[i]) break;
      _swap(i, p);
      i = p;
    }
  }

  int pop() {
    final top = _items.first;
    final lastKey = _keys.removeLast();
    final lastItem = _items.removeLast();
    if (_items.isNotEmpty) {
      _keys[0] = lastKey;
      _items[0] = lastItem;
      var i = 0;
      while (true) {
        final l = 2 * i + 1, r = l + 1;
        var m = i;
        if (l < _items.length && _keys[l] < _keys[m]) m = l;
        if (r < _items.length && _keys[r] < _keys[m]) m = r;
        if (m == i) break;
        _swap(i, m);
        i = m;
      }
    }
    return top;
  }

  void _swap(int a, int b) {
    final k = _keys[a];
    _keys[a] = _keys[b];
    _keys[b] = k;
    final t = _items[a];
    _items[a] = _items[b];
    _items[b] = t;
  }
}

/// [compute]로 별도 isolate에서 실행하기 위한 함수.
/// [args]: 타일 목록 뒤에 판 크기를 붙인 값.
List<int>? solveForHint(List<int> args) {
  final size = args.last;
  return PuzzleSolver(size).solve(args.sublist(0, args.length - 1));
}
