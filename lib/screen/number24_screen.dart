import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';
import 'package:number_puzzle1/ad_banner_widget.dart';
import 'dart:math';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_color.dart';
import '../feedback_service.dart';
import '../widgets/game_ui_3d.dart';
import '../widgets/puzzle_board_3d.dart';
import '../widgets/settings_dialog.dart';

class Number24Screen extends StatefulWidget {
  const Number24Screen({super.key, this.showAd = true});

  /// 광고 배너 표시 여부 (테스트에서는 false)
  final bool showAd;

  @override
  State<Number24Screen> createState() => _Number24ScreenState();
}

class _Number24ScreenState extends State<Number24Screen> {
  // 타일 위치를 관리할 리스트 (0~24 인덱스 값을 저장)
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
  bool isPaused = false; // 설정 창이 열려 있는 동안 타이머 정지

  // SharedPreferences 키
  static const String puzzleType = 'puzzle_24';
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
      if (!isCompleted && !isPaused) {
        setState(() {
          elapsedSeconds++;
        });
      }
    });
  }

  // 초기 설정을 위한 새로운 함수
  void initializePuzzle() {
    setState(() {
      tiles = List.generate(25, (index) => index == 24 ? 0 : index + 1);
      emptyIndex = 24;
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
      tiles = List.generate(25, (index) => index == 24 ? 0 : index + 1);
      emptyIndex = 24;
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
    for (int i = 0; i < 300; i++) {
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
    if (emptyIndex >= 5) validMoves.add(emptyIndex - 5);
    if (emptyIndex < 20) validMoves.add(emptyIndex + 5);
    if (emptyIndex % 5 > 0) validMoves.add(emptyIndex - 1);
    if (emptyIndex % 5 < 4) validMoves.add(emptyIndex + 1);

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
    for (int i = 0; i < 24; i++) {
      if (tiles[i] != i + 1) {
        isComplete = false;
        break;
      }
    }

    if (isComplete && tiles[24] == 0) {
      isCompleted = true;
      timer.cancel();
      FeedbackService.instance.win();

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

  // 설정 창 열기 (열려 있는 동안 타이머 정지)
  Future<void> openSettings() async {
    setState(() => isPaused = true);
    await showSettingsDialog(context, color: AppColor.puzzle24MenuBackground);
    if (mounted) setState(() => isPaused = false);
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
        backgroundColor: AppColor.puzzle24Background,
        body: Column(
          children: [
            GameHeader3D(
              title: 'home_puzzle_5'.tr(),
              color: AppColor.puzzle24MenuBackground,
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8),
              child:
                  bestMoveCount != null && bestTime != null
                      ? BestRecordBadge3D(
                        color: AppColor.puzzle24MenuBackground,
                        text: 'puzzle_best_record'.tr(
                          namedArgs: {
                            'moves': bestMoveCount.toString(),
                            'time': formatTime(bestTime!),
                          },
                        ),
                      )
                      : const SizedBox.shrink(),
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
                          child: PuzzleBoard3D(
                            tiles: tiles,
                            gridSize: 5,
                            tileColor: AppColor.puzzle24Tile,
                            textColor: AppColor.puzzle24Text,
                            emptyColor: AppColor.puzzle24Empty,
                            frameColor: AppColor.puzzle24MenuBackground,
                            // 완성된 상태에서는 타일 이동 불가
                            enabled: !isCompleted,
                            onTileTap: (index) {
                              // 빈 공간 주변의 타일만 이동 가능
                              if (getValidMoves().contains(index)) {
                                FeedbackService.instance.move();
                                swapTiles(index);
                              } else {
                                FeedbackService.instance.invalid();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // 이동 횟수와 시간 표시 영역
                    StatsPanel3D(
                      moves: moveCount,
                      time: formatTime(elapsedSeconds),
                      color: AppColor.puzzle24Tile,
                      textColor: AppColor.puzzle24Text,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            GameMenuBar3D(
              color: AppColor.puzzle24MenuBackground,
              children: [
                Button3D(
                  icon: Icons.arrow_back,
                  tooltip: 'menu_back'.tr(),
                  color: shadeColor(AppColor.puzzle24MenuBackground, 0.12),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Button3D(
                  icon: Icons.refresh,
                  tooltip: 'menu_restart'.tr(),
                  color: shadeColor(AppColor.puzzle24MenuBackground, 0.12),
                  onPressed: resetPuzzle,
                ),
                Button3D(
                  icon: Icons.settings,
                  tooltip: 'settings_tooltip'.tr(),
                  color: shadeColor(AppColor.puzzle24MenuBackground, 0.12),
                  onPressed: openSettings,
                ),
              ],
            ),

            if (widget.showAd) const AdBannerWidget(),
          ],
        ),
      ),
    );
  }
}
