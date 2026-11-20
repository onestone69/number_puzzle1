import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 완성한 게임 하나의 기록.
class RecordEntry {
  const RecordEntry({
    required this.moves,
    required this.seconds,
    required this.date,
  });

  final int moves;
  final int seconds;
  final DateTime date;

  Map<String, Object> toJson() => {
    'moves': moves,
    'seconds': seconds,
    'date': date.millisecondsSinceEpoch,
  };

  static RecordEntry? fromJson(Object? json) {
    if (json is! Map) return null;
    final moves = json['moves'];
    final seconds = json['seconds'];
    final date = json['date'];
    if (moves is! int || seconds is! int || date is! int) return null;
    return RecordEntry(
      moves: moves,
      seconds: seconds,
      date: DateTime.fromMillisecondsSinceEpoch(date),
    );
  }

  /// 빠른 시간 순, 같으면 적은 이동 순
  static int compare(RecordEntry a, RecordEntry b) {
    final byTime = a.seconds.compareTo(b.seconds);
    return byTime != 0 ? byTime : a.moves.compareTo(b.moves);
  }
}

/// 난이도 하나의 기록 모음.
class PuzzleRecords {
  const PuzzleRecords({
    this.bestMoves,
    this.bestTime,
    this.clears = 0,
    this.top = const [],
  });

  final int? bestMoves;
  final int? bestTime;

  /// 완성한 횟수
  final int clears;

  /// 빠른 순 상위 기록 (최대 [RecordsStore.topCount]개)
  final List<RecordEntry> top;

  bool get isEmpty => bestMoves == null && bestTime == null && top.isEmpty;
}

/// 게임을 완성했을 때의 기록 갱신 결과.
class RecordResult {
  const RecordResult({
    required this.records,
    required this.isNewBestMoves,
    required this.isNewBestTime,
    required this.rank,
  });

  final PuzzleRecords records;
  final bool isNewBestMoves;
  final bool isNewBestTime;

  /// TOP 기록 안에서의 순위 (1부터). 순위 밖이면 null.
  final int? rank;

  bool get isNewRecord => isNewBestMoves || isNewBestTime;
}

/// 난이도별 기록 저장소.
///
/// 최소 이동·최단 시간은 예전 버전과 같은 키(best_moves_/best_time_)를 써서
/// 기존 기록이 그대로 이어진다.
class RecordsStore {
  RecordsStore._();

  static const topCount = 5;

  static String _bestMovesKey(String type) => 'best_moves_$type';
  static String _bestTimeKey(String type) => 'best_time_$type';
  static String _clearsKey(String type) => 'records_clears_$type';
  static String _topKey(String type) => 'records_top_$type';

  static Future<PuzzleRecords> load(String puzzleType) async {
    final prefs = await SharedPreferences.getInstance();
    return _read(prefs, puzzleType);
  }

  static PuzzleRecords _read(SharedPreferences prefs, String type) {
    var top = <RecordEntry>[];
    try {
      final raw = prefs.getString(_topKey(type));
      if (raw != null) {
        top =
            (jsonDecode(raw) as List)
                .map(RecordEntry.fromJson)
                .whereType<RecordEntry>()
                .toList()
              ..sort(RecordEntry.compare);
      }
    } catch (_) {
      top = []; // 손상된 값은 무시
    }
    return PuzzleRecords(
      bestMoves: prefs.getInt(_bestMovesKey(type)),
      bestTime: prefs.getInt(_bestTimeKey(type)),
      clears: prefs.getInt(_clearsKey(type)) ?? 0,
      top: top.take(topCount).toList(),
    );
  }

  /// 완성한 게임을 기록에 반영한다.
  static Future<RecordResult> addResult(
    String puzzleType, {
    required int moves,
    required int seconds,
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final old = _read(prefs, puzzleType);
    final entry = RecordEntry(
      moves: moves,
      seconds: seconds,
      date: now ?? DateTime.now(),
    );

    final isNewBestMoves = old.bestMoves == null || moves < old.bestMoves!;
    final isNewBestTime = old.bestTime == null || seconds < old.bestTime!;

    final top = [...old.top, entry]..sort(RecordEntry.compare);
    final index = top.indexOf(entry);
    final kept = top.take(topCount).toList();

    final records = PuzzleRecords(
      bestMoves: isNewBestMoves ? moves : old.bestMoves,
      bestTime: isNewBestTime ? seconds : old.bestTime,
      clears: old.clears + 1,
      top: kept,
    );

    await prefs.setInt(_bestMovesKey(puzzleType), records.bestMoves!);
    await prefs.setInt(_bestTimeKey(puzzleType), records.bestTime!);
    await prefs.setInt(_clearsKey(puzzleType), records.clears);
    await prefs.setString(
      _topKey(puzzleType),
      jsonEncode(kept.map((e) => e.toJson()).toList()),
    );

    return RecordResult(
      records: records,
      isNewBestMoves: isNewBestMoves,
      isNewBestTime: isNewBestTime,
      rank: index < topCount ? index + 1 : null,
    );
  }
}
