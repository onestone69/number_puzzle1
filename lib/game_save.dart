import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 이어하기용으로 저장된 게임 진행 상황.
class SavedGame {
  const SavedGame({
    required this.tiles,
    required this.moves,
    required this.seconds,
  });

  /// 칸 순서대로의 숫자 (0은 빈칸)
  final List<int> tiles;
  final int moves;
  final int seconds;

  Map<String, Object> toJson() => {
    'tiles': tiles,
    'moves': moves,
    'seconds': seconds,
  };

  /// 저장된 값이 손상되었거나 [tileCount]와 맞지 않으면 null.
  static SavedGame? tryParse(String? source, int tileCount) {
    if (source == null) return null;
    try {
      final json = jsonDecode(source) as Map<String, dynamic>;
      final tiles = (json['tiles'] as List).cast<int>();
      final moves = json['moves'] as int;
      final seconds = json['seconds'] as int;
      // 0~(tileCount-1)이 한 번씩 들어 있어야 함
      final isPermutation =
          tiles.length == tileCount &&
          (tiles.toSet()..removeAll(List.generate(tileCount, (i) => i)))
              .isEmpty &&
          tiles.toSet().length == tileCount;
      if (!isPermutation || moves < 0 || seconds < 0) return null;
      // 이미 완성된 배치는 이어할 필요 없음
      if (isSolved(tiles)) return null;
      return SavedGame(tiles: tiles, moves: moves, seconds: seconds);
    } catch (_) {
      return null;
    }
  }

  /// 1, 2, ..., n-1, 0 순서이면 완성
  static bool isSolved(List<int> tiles) {
    for (var i = 0; i < tiles.length - 1; i++) {
      if (tiles[i] != i + 1) return false;
    }
    return tiles.last == 0;
  }
}

/// 퍼즐 종류별 진행 상황 저장소.
class GameSaveStore {
  GameSaveStore._();

  static String _key(String puzzleType) => 'saved_game_$puzzleType';

  static Future<SavedGame?> load(String puzzleType, int tileCount) async {
    final prefs = await SharedPreferences.getInstance();
    return SavedGame.tryParse(prefs.getString(_key(puzzleType)), tileCount);
  }

  /// 저장. SharedPreferences는 메모리 값을 즉시 갱신하므로
  /// 결과를 기다리지 않아도 바로 다음 [load]에서 읽힌다.
  static Future<void> save(String puzzleType, SavedGame game) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(puzzleType), jsonEncode(game.toJson()));
  }

  static Future<void> clear(String puzzleType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(puzzleType));
  }
}
