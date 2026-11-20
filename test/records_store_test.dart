import 'package:flutter_test/flutter_test.dart';
import 'package:number_puzzle1/records_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final day = DateTime(2026, 11, 21);

  test('첫 완성은 최소 이동·최단 시간 모두 신기록, 1위', () async {
    final r = await RecordsStore.addResult(
      'puzzle_8',
      moves: 40,
      seconds: 90,
      now: day,
    );
    expect(r.isNewBestMoves, isTrue);
    expect(r.isNewBestTime, isTrue);
    expect(r.rank, 1);
    expect(r.records.clears, 1);
  });

  test('최소 이동과 최단 시간은 따로 갱신됨', () async {
    await RecordsStore.addResult('puzzle_8', moves: 40, seconds: 90, now: day);
    // 이동은 더 적지만 시간은 더 김
    final r = await RecordsStore.addResult(
      'puzzle_8',
      moves: 30,
      seconds: 120,
      now: day,
    );
    expect(r.isNewBestMoves, isTrue);
    expect(r.isNewBestTime, isFalse);
    expect(r.records.bestMoves, 30);
    expect(r.records.bestTime, 90);
    expect(r.rank, 2); // 시간 순으로 2위
  });

  test('TOP 5는 빠른 순으로 5개까지만 유지', () async {
    for (final s in [100, 50, 80, 120, 60, 70, 200]) {
      await RecordsStore.addResult('puzzle_8', moves: 10, seconds: s, now: day);
    }
    final records = await RecordsStore.load('puzzle_8');
    expect(records.top.map((e) => e.seconds), [50, 60, 70, 80, 100]);
    expect(records.clears, 7);

    final outside = await RecordsStore.addResult(
      'puzzle_8',
      moves: 10,
      seconds: 300,
      now: day,
    );
    expect(outside.rank, isNull);
  });

  test('예전 버전의 최고 기록을 그대로 이어서 씀', () async {
    SharedPreferences.setMockInitialValues({
      'best_moves_puzzle_15': 55,
      'best_time_puzzle_15': 140,
    });
    final old = await RecordsStore.load('puzzle_15');
    expect(old.bestMoves, 55);
    expect(old.bestTime, 140);
    expect(old.isEmpty, isFalse);

    final r = await RecordsStore.addResult(
      'puzzle_15',
      moves: 60,
      seconds: 130,
      now: day,
    );
    expect(r.isNewBestMoves, isFalse);
    expect(r.isNewBestTime, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('best_time_puzzle_15'), 130);
  });

  test('난이도별로 따로 저장됨', () async {
    await RecordsStore.addResult('puzzle_8', moves: 40, seconds: 90, now: day);
    expect((await RecordsStore.load('puzzle_24')).isEmpty, isTrue);
  });
}
