import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:number_puzzle1/ad_banner_widget.dart';
import 'dart:math';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

import '../app_color.dart';
import '../feedback_service.dart';
import '../game_save.dart';
import '../puzzle_solver.dart';
import '../records_store.dart';
import 'records_screen.dart';
import '../widgets/completion_dialog.dart';
import '../widgets/game_ui_3d.dart';
import '../widgets/puzzle_board_3d.dart';
import '../widgets/settings_dialog.dart';

class Number8Screen extends StatefulWidget {
  const Number8Screen({super.key, this.showAd = true, this.savedGame});

  /// 이어할 게임 (없으면 새 게임)
  final SavedGame? savedGame;

  /// 저장 키에 쓰는 퍼즐 구분값
  static const String puzzleType = 'puzzle_8';

  /// 광고 배너 표시 여부 (테스트에서는 false)
  final bool showAd;

  @override
  State<Number8Screen> createState() => _Number8ScreenState();
}

class _Number8ScreenState extends State<Number8Screen>
    with WidgetsBindingObserver {
  // 타일 위치를 관리할 리스트 (0~8 인덱스 값을 저장)
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
  bool _inBackground = false; // 앱이 백그라운드에 있는 동안 타이머 정지

  // 힌트
  List<int> _hintPath = []; // 완성까지 눌러야 할 칸 순서 (풀이)
  int? _hintIndex; // 지금 강조 중인 힌트 타일의 칸 번호
  bool _hintLoading = false;
  int hintsUsed = 0; // 이 게임에서 사용한 힌트 횟수

  // SharedPreferences 키
  static const String puzzleType = Number8Screen.puzzleType;
  static const String bestMovesKey = 'best_moves_';
  static const String bestTimeKey = 'best_time_';

  @override
  void initState() {
    super.initState();
    loadBestScores(); // 최고 기록 불러오기
    WidgetsBinding.instance.addObserver(this);
    final saved = widget.savedGame;
    if (saved != null && saved.tiles.length == 9) {
      restoreGame(saved); // 이어하기
    } else {
      initializePuzzle();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    saveGame(); // 진행 상황 저장
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
  Future<RecordResult> saveBestScores(int moves, int time) async {
    // 최소 이동·최단 시간·완성 횟수·TOP 5 기록 갱신
    final result = await RecordsStore.addResult(
      puzzleType,
      moves: moves,
      seconds: time,
    );
    bestMoveCount = result.records.bestMoves;
    bestTime = result.records.bestTime;
    return result;
  }

  // 타이머 시작 함수
  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!isCompleted && !isPaused && !_inBackground) {
        setState(() {
          elapsedSeconds++;
        });
      }
    });
  }

  // 저장된 게임 이어하기
  void restoreGame(SavedGame saved) {
    tiles = List.of(saved.tiles);
    emptyIndex = tiles.indexOf(0);
    moveCount = saved.moves;
    elapsedSeconds = saved.seconds;
    hintsUsed = saved.hints;
    isCompleted = false;
    startTimer();
  }

  // 진행 상황 저장 (한 번도 움직이지 않았거나 완성한 게임은 저장하지 않음)
  void saveGame() {
    if (isCompleted || moveCount == 0) return;
    GameSaveStore.save(
      puzzleType,
      SavedGame(
        tiles: List.of(tiles),
        moves: moveCount,
        seconds: elapsedSeconds,
        hints: hintsUsed,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // 백그라운드에 있는 동안 시간이 흐르지 않게 하고, 앱이 종료될 수 있으니 저장
        _inBackground = true;
        saveGame();
      case AppLifecycleState.resumed:
        _inBackground = false;
      default:
        break;
    }
  }

  // 초기 설정을 위한 새로운 함수
  void initializePuzzle() {
    setState(() {
      tiles = List.generate(9, (index) => index == 8 ? 0 : index + 1);
      emptyIndex = 8;
      moveCount = 0;
      hintsUsed = 0;
      elapsedSeconds = 0;
      isCompleted = false;
    });

    shufflePuzzle();
    startTimer(); // 타이머 시작
  }

  // 퍼즐 초기화 및 섞기
  void resetPuzzle() {
    _hintPath = [];
    _hintIndex = null;
    GameSaveStore.clear(puzzleType); // 새 게임이므로 이어하기 삭제
    // 기존 타이머가 있다면 취소
    if (timer.isActive) {
      timer.cancel();
    }

    setState(() {
      tiles = List.generate(9, (index) => index == 8 ? 0 : index + 1);
      emptyIndex = 8;
      moveCount = 0;
      hintsUsed = 0;
      elapsedSeconds = 0;
      isCompleted = false;
    });

    shufflePuzzle();
    startTimer(); // 타이머 재시작
  }

  // 퍼즐 섞기 함수
  void shufflePuzzle() {
    // 랜덤하게 100번 이동
    final random = Random();
    for (int i = 0; i < 100; i++) {
      // 빈 공간 주변의 이동 가능한 타일 찾기
      final validMoves = getValidMoves();
      if (validMoves.isNotEmpty) {
        // 랜덤하게 하나의 타일 선택해서 이동
        final tileToMove = validMoves[random.nextInt(validMoves.length)];
        // 초기 셔플에서는 완료 체크를 하지 않음
        swapTiles(tileToMove, checkComplete: false);
      }
    }
  }

  // 빈 공간 주변의 이동 가능한 타일 위치 반환
  List<int> getValidMoves() {
    final validMoves = <int>[];
    // 위에 타일이 있는지 확인
    if (emptyIndex >= 3) validMoves.add(emptyIndex - 3);
    // 아래에 타일이 있는지 확인
    if (emptyIndex < 6) validMoves.add(emptyIndex + 3);
    // 왼쪽에 타일이 있는지 확인
    if (emptyIndex % 3 > 0) validMoves.add(emptyIndex - 1);
    // 오른쪽에 타일이 있는지 확인
    if (emptyIndex % 3 < 2) validMoves.add(emptyIndex + 1);

    return validMoves;
  }

  // 타일과 빈 공간의 위치 교환
  void swapTiles(int tileIndex, {bool checkComplete = true}) {
    // 퍼즐이 완성된 상태면 이동 불가
    if (isCompleted && checkComplete) return;

    if (checkComplete) {
      if (_hintPath.isNotEmpty && _hintPath.first == tileIndex) {
        _hintPath.removeAt(0); // 힌트대로 둠 → 다음 힌트는 바로 이어서
      } else {
        _hintPath = []; // 다른 수를 둠 → 다음 힌트 때 다시 계산
      }
      _hintIndex = null;
    }

    setState(() {
      final temp = tiles[tileIndex];
      tiles[tileIndex] = tiles[emptyIndex];
      tiles[emptyIndex] = temp;
      emptyIndex = tileIndex;
      if (checkComplete) moveCount++; // 실제 플레이어 이동 시에만 카운트 증가
    });

    if (checkComplete) {
      checkPuzzleComplete();
      if (!isCompleted) saveGame(); // 이동할 때마다 저장
    }
  }

  // 퍼즐이 완료되었는지 확인
  void checkPuzzleComplete() {
    bool isComplete = true;
    for (int i = 0; i < 8; i++) {
      if (tiles[i] != i + 1) {
        isComplete = false;
        break;
      }
    }

    if (isComplete && tiles[8] == 0) {
      isCompleted = true;
      timer.cancel();
      FeedbackService.instance.win();
      GameSaveStore.clear(puzzleType); // 완성했으므로 이어하기 삭제

      saveBestScores(moveCount, elapsedSeconds).then((result) async {
        if (!mounted) return;
        setState(() {}); // 상단 최고 기록 갱신
        final action = await showCompletionDialog(
          context,
          color: AppColor.puzzle8MenuBackground,
          moves: moveCount,
          seconds: elapsedSeconds,
          result: result,
          hintsUsed: hintsUsed,
        );
        if (!mounted) return;
        switch (action) {
          case CompletionAction.playAgain:
            resetPuzzle();
          case CompletionAction.records:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RecordsScreen(initialIndex: 0),
              ),
            );
          case CompletionAction.close:
            break;
        }
      });
    }
  }

  // 힌트: 다음에 움직일 타일을 강조
  Future<void> showHint() async {
    if (isCompleted || _hintLoading) return;
    if (_hintPath.isEmpty) {
      setState(() => _hintLoading = true);
      final snapshot = List.of(tiles);
      // 풀이 계산은 화면이 멈추지 않도록 별도 isolate에서
      final path = await compute(solveForHint, [...snapshot, 3]);
      if (!mounted) return;
      setState(() => _hintLoading = false);
      // 계산하는 동안 판이 바뀌었으면 무시
      if (!listEquals(snapshot, tiles) || path == null || path.isEmpty) return;
      _hintPath = path;
    }
    setState(() {
      // 같은 힌트를 다시 누른 것은 세지 않음
      if (_hintIndex == null) hintsUsed++;
      _hintIndex = _hintPath.first;
    });
  }

  // 설정 창 열기 (열려 있는 동안 타이머 정지)
  Future<void> openSettings() async {
    setState(() => isPaused = true);
    await showSettingsDialog(context, color: AppColor.puzzle8MenuBackground);
    if (mounted) setState(() => isPaused = false);
  }

  // 시간을 분:초 형식으로 변환하는 함수
  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) saveGame();
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColor.puzzle8Background,
          body: Column(
            children: [
              // 타이틀 영역
              GameHeader3D(
                title: 'home_puzzle_3'.tr(),
                color: AppColor.puzzle8MenuBackground,
              ),
              // 최고 기록 표시 영역 수정
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(8),
                child:
                    bestMoveCount != null && bestTime != null
                        ? BestRecordBadge3D(
                          color: AppColor.puzzle8MenuBackground,
                          text: 'puzzle_best_record'.tr(
                            namedArgs: {
                              'moves': bestMoveCount.toString(),
                              'time': formatTime(bestTime!),
                            },
                          ),
                        )
                        : const SizedBox.shrink(),
              ),

              // 메인 콘텐츠 영역
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
                              gridSize: 3,
                              tileColor: AppColor.puzzle8Tile,
                              textColor: AppColor.puzzle8Text,
                              emptyColor: AppColor.puzzle8Empty,
                              frameColor: AppColor.puzzle8MenuBackground,
                              // 완성된 상태에서는 타일 이동 불가
                              enabled: !isCompleted,
                              hintIndex: _hintIndex,
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
                        color: AppColor.puzzle8Tile,
                        textColor: AppColor.puzzle8Text,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // 하단 메뉴 영역
              GameMenuBar3D(
                color: AppColor.puzzle8MenuBackground,
                children: [
                  Button3D(
                    icon: Icons.arrow_back,
                    tooltip: 'menu_back'.tr(),
                    color: shadeColor(AppColor.puzzle8MenuBackground, 0.12),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Button3D(
                    icon: Icons.refresh,
                    tooltip: 'menu_restart'.tr(),
                    color: shadeColor(AppColor.puzzle8MenuBackground, 0.12),
                    onPressed: resetPuzzle,
                  ),
                  Button3D(
                    icon: _hintLoading ? Icons.hourglass_top : Icons.lightbulb,
                    tooltip: 'menu_hint'.tr(),
                    color: shadeColor(AppColor.puzzle8MenuBackground, 0.12),
                    onPressed: showHint,
                  ),
                  Button3D(
                    icon: Icons.settings,
                    tooltip: 'settings_tooltip'.tr(),
                    color: shadeColor(AppColor.puzzle8MenuBackground, 0.12),
                    onPressed: openSettings,
                  ),
                ],
              ),

              // AdMob 배너 영역을 위젯으로 교체
              if (widget.showAd) const AdBannerWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
