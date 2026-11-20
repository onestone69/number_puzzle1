import 'package:flutter_test/flutter_test.dart';
import 'package:number_puzzle1/game_save.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const game = SavedGame(
    tiles: [1, 2, 3, 4, 5, 6, 7, 0, 8],
    moves: 12,
    seconds: 83,
  );

  test('저장한 게임을 그대로 불러옴', () async {
    await GameSaveStore.save('puzzle_8', game);
    final loaded = await GameSaveStore.load('puzzle_8', 9);
    expect(loaded, isNotNull);
    expect(loaded!.tiles, game.tiles);
    expect(loaded.moves, 12);
    expect(loaded.seconds, 83);
  });

  test('퍼즐 종류별로 따로 저장되고 삭제됨', () async {
    await GameSaveStore.save('puzzle_8', game);
    expect(await GameSaveStore.load('puzzle_15', 16), isNull);
    await GameSaveStore.clear('puzzle_8');
    expect(await GameSaveStore.load('puzzle_8', 9), isNull);
  });

  test('손상되었거나 맞지 않는 값은 무시', () {
    expect(SavedGame.tryParse(null, 9), isNull);
    expect(SavedGame.tryParse('not json', 9), isNull);
    // 칸 수가 다름
    expect(
      SavedGame.tryParse('{"tiles":[1,2,3,0],"moves":1,"seconds":1}', 9),
      isNull,
    );
    // 같은 숫자가 두 번
    expect(
      SavedGame.tryParse(
        '{"tiles":[1,1,3,4,5,6,7,0,8],"moves":1,"seconds":1}',
        9,
      ),
      isNull,
    );
    // 이미 완성된 배치는 이어할 필요 없음
    expect(
      SavedGame.tryParse(
        '{"tiles":[1,2,3,4,5,6,7,8,0],"moves":5,"seconds":9}',
        9,
      ),
      isNull,
    );
    expect(
      SavedGame.tryParse(
        '{"tiles":[1,2,3,4,5,6,7,0,8],"moves":5,"seconds":9}',
        9,
      ),
      isNotNull,
    );
  });
}
