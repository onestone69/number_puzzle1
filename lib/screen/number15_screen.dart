import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';
import 'package:number_puzzle1/ad_banner_widget.dart';
import 'dart:math';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_color.dart';

class Number15Screen extends StatefulWidget {
  const Number15Screen({super.key, this.showAd = true});

  /// 광고 배너 표시 여부 (테스트에서는 false)
  final bool showAd;

  @override
  State<Number15Screen> createState() => _Number15ScreenState();
}

class _Number15ScreenState extends State<Number15Screen> {
  // 타일 위치를 관리할 리스트 (0~15 인덱스 값을 저장)
  late List<int> tiles;
  // 빈 타일의 현재 위치
  late int emptyIndex;

  // 새로운 변수들 추가
  int moveCount = 0; // 이동 횟수
  int elapsedSeconds = 0; // 경과 시간(초)
  late Timer timer; // 타이머

  // 최고 기록 저장용 변수 추가
  int? bestMoveCount;
  int? bestTime;
  bool isCompleted = false;

  // SharedPreferences 키
  static const String puzzleType = 'puzzle_15'; // 15 퍼즐 구분
  static const String bestMovesKey = 'best_moves_';
  static const String bestTimeKey = 'best_time_';

  @override
  void initState() {
    super.initState();
    loadBestScores();
    initializePuzzle();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  // 최고 기록 불러오기
  Future<void> loadBestScores() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      bestMoveCount = prefs.getInt('$bestMovesKey$puzzleType');
      bestTime = prefs.getInt('$bestTimeKey$puzzleType');
    });
  }

  // 최고 기록 저장
  Future<bool> saveBestScores(int moves, int time) async {
    final prefs = await SharedPreferences.getInstance();
    bool isNewRecord = false;

    setState(() {
      // 이동 횟수 최고 기록 갱신
      if (bestMoveCount == null || moves < bestMoveCount!) {
        prefs.setInt('$bestMovesKey$puzzleType', moves);
        bestMoveCount = moves;
        isNewRecord = true;
      }

      // 시간 최고 기록 갱신
      if (bestTime == null || time < bestTime!) {
        prefs.setInt('$bestTimeKey$puzzleType', time);
        bestTime = time;
        isNewRecord = true;
      }
    });

    return isNewRecord;
  }

  // 타이머 시작 함수
  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!isCompleted) {
        setState(() {
          elapsedSeconds++;
        });
      }
    });
  }

  // 초기 설정을 위한 새로운 함수
  void initializePuzzle() {
    setState(() {
      tiles = List.generate(16, (index) => index == 15 ? 0 : index + 1);
      emptyIndex = 15;
      moveCount = 0;
      elapsedSeconds = 0;
      isCompleted = false;
    });

    shufflePuzzle();
    startTimer();
  }

  // 퍼즐 초기화 및 섞기
  void resetPuzzle() {
    if (timer.isActive) {
      timer.cancel();
    }

    setState(() {
      tiles = List.generate(16, (index) => index == 15 ? 0 : index + 1);
      emptyIndex = 15;
      moveCount = 0;
      elapsedSeconds = 0;
      isCompleted = false;
    });

    shufflePuzzle();
    startTimer();
  }

  // 퍼즐 섞기 함수
  void shufflePuzzle() {
    final random = Random();
    for (int i = 0; i < 200; i++) {
      // 15퍼즐은 더 많은 섞기 횟수 필요
      final validMoves = getValidMoves();
      if (validMoves.isNotEmpty) {
        final tileToMove = validMoves[random.nextInt(validMoves.length)];
        swapTiles(tileToMove, checkComplete: false);
      }
    }
  }

  // 빈 공간 주변의 이동 가능한 타일 위치 반환
  List<int> getValidMoves() {
    final validMoves = <int>[];
    // 위에 타일이 있는지 확인
    if (emptyIndex >= 4) validMoves.add(emptyIndex - 4);
    // 아래에 타일이 있는지 확인
    if (emptyIndex < 12) validMoves.add(emptyIndex + 4);
    // 왼쪽에 타일이 있는지 확인
    if (emptyIndex % 4 > 0) validMoves.add(emptyIndex - 1);
    // 오른쪽에 타일이 있는지 확인
    if (emptyIndex % 4 < 3) validMoves.add(emptyIndex + 1);

    return validMoves;
  }

  // 타일과 빈 공간의 위치 교환
  void swapTiles(int tileIndex, {bool checkComplete = true}) {
    if (isCompleted && checkComplete) return;

    setState(() {
      final temp = tiles[tileIndex];
      tiles[tileIndex] = tiles[emptyIndex];
      tiles[emptyIndex] = temp;
      emptyIndex = tileIndex;
      if (checkComplete) moveCount++;
    });

    if (checkComplete) {
      checkPuzzleComplete();
    }
  }

  // 퍼즐이 완료되었는지 확인
  void checkPuzzleComplete() {
    bool isComplete = true;
    for (int i = 0; i < 15; i++) {
      if (tiles[i] != i + 1) {
        isComplete = false;
        break;
      }
    }

    if (isComplete && tiles[15] == 0) {
      isCompleted = true;
      timer.cancel();

      saveBestScores(moveCount, elapsedSeconds).then((isNewRecord) {
        if (!mounted) return;
        String message =
            "${'completion_congratulations'.tr()}\n${'completion_moves'.tr(namedArgs: {'count': moveCount.toString()})}\n${'completion_time'.tr(namedArgs: {'time': formatTime(elapsedSeconds)})}\n\n";

        if (isNewRecord) {
          message += "${'completion_new_record'.tr()}\n";
        }

        if (bestMoveCount != null) {
          message +=
              "${'completion_best_moves'.tr(namedArgs: {'count': bestMoveCount.toString()})}\n";
        }
        if (bestTime != null) {
          message += 'completion_best_time'.tr(
            namedArgs: {'time': formatTime(bestTime!)},
          );
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: Text(
                  'completion_title'.tr(),
                  style: TextStyle(
                    fontFamily: 'HiMelody',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Text(
                  message,
                  style: TextStyle(fontFamily: 'HiMelody', fontSize: 24),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      resetPuzzle();
                    },
                    child: Text(
                      'completion_restart'.tr(),
                      style: TextStyle(fontSize: 26),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'completion_ok'.tr(),
                      style: TextStyle(fontSize: 26),
                    ),
                  ),
                ],
              ),
        );
      });
    }
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColor.puzzle15Background,
        body: Column(
          children: [
            Container(
              color: AppColor.puzzle15MenuBackground,
              height: 80,
              width: double.infinity,
              alignment: Alignment.center,
              padding: EdgeInsets.all(8),
              child: Text(
                'home_puzzle_4'.tr(),
                style: TextStyle(
                  fontFamily: 'HiMelody',
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColor.puzzle15Background,
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (bestMoveCount != null && bestTime != null)
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'puzzle_best_record'.tr(
                            namedArgs: {
                              'moves': bestMoveCount.toString(),
                              'time': formatTime(bestTime!),
                            },
                          ),
                          style: TextStyle(
                            fontFamily: 'HiMelody',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 150, 158, 248),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // 남은 공간에 맞춰 그리드가 줄어들도록 Flexible로 감쌈
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        constraints: BoxConstraints(maxWidth: 400),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: GridView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemCount: 16,
                            itemBuilder: (context, index) {
                              final tileValue = tiles[index];

                              if (tileValue == 0) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: AppColor.puzzle15Empty,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                );
                              }

                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColor.puzzle15Tile,
                                  foregroundColor: AppColor.puzzle15Text,
                                  padding: EdgeInsets.zero,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  disabledBackgroundColor: AppColor.tile2
                                      .withValues(alpha: 0.7),
                                ),
                                onPressed:
                                    isCompleted
                                        ? null
                                        : () {
                                          if (getValidMoves().contains(index)) {
                                            swapTiles(index);
                                          }
                                        },
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '$tileValue',
                                    style: TextStyle(
                                      fontFamily: 'HiMelody',
                                      color: AppColor.puzzle15Text,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 좁은 화면에서는 축소해서 표시
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColor.puzzle15Tile.withValues(
                                  alpha: 0.9,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(width: 10),
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.swap_horiz,
                                          size: 20,
                                          color: AppColor.puzzle15Text,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '$moveCount',
                                          style: TextStyle(
                                            fontFamily: 'HiMelody',
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: AppColor.puzzle15Text,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 30),
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.timer,
                                          size: 20,
                                          color: AppColor.puzzle15Text,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          formatTime(elapsedSeconds),
                                          style: TextStyle(
                                            fontFamily: 'HiMelody',
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: AppColor.puzzle15Text,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.puzzle15MenuBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    color: Colors.white,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    color: Colors.white,
                    onPressed: () {
                      resetPuzzle();
                    },
                  ),
                ],
              ),
            ),

            if (widget.showAd) const AdBannerWidget(),
          ],
        ),
      ),
    );
  }
}
