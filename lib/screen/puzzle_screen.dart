import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../ad_banner_widget.dart';
import '../app_color.dart';
import '../feedback_service.dart';
import '../game_save.dart';
import '../puzzle_moves.dart';
import '../puzzle_solver.dart';
import '../records_store.dart';
import '../widgets/completion_dialog.dart';
import '../widgets/game_ui_3d.dart';
import '../widgets/puzzle_board_3d.dart';
import '../widgets/settings_dialog.dart';
import 'records_screen.dart';

/// 난이도(판 크기)별 설정
class PuzzleConfig {
  const PuzzleConfig({
    required this.gridSize,
    required this.puzzleType,
    required this.titleKey,
    required this.background,
    required this.menuColor,
    required this.tileColor,
    required this.textColor,
    required this.emptyColor,
  });

  /// 한 줄의 칸 수 (3, 4, 5)
  final int gridSize;

  /// 저장 키에 쓰는 구분값 (예전 버전과 같은 값을 유지해야 기록이 이어짐)
  final String puzzleType;

  /// 제목 번역 키
  final String titleKey;

  final Color background;
  final Color menuColor;
  final Color tileColor;
  final Color textColor;
  final Color emptyColor;

  int get tileCount => gridSize * gridSize;

  /// 기록 화면 탭 순서
  int get index => all.indexOf(this);

  static const size3 = PuzzleConfig(
    gridSize: 3,
    puzzleType: 'puzzle_8',
    titleKey: 'home_puzzle_3',
    background: AppColor.puzzle8Background,
    menuColor: AppColor.puzzle8MenuBackground,
    tileColor: AppColor.puzzle8Tile,
    textColor: AppColor.puzzle8Text,
    emptyColor: AppColor.puzzle8Empty,
  );

  static const size4 = PuzzleConfig(
    gridSize: 4,
    puzzleType: 'puzzle_15',
    titleKey: 'home_puzzle_4',
    background: AppColor.puzzle15Background,
    menuColor: AppColor.puzzle15MenuBackground,
    tileColor: AppColor.puzzle15Tile,
    textColor: AppColor.puzzle15Text,
    emptyColor: AppColor.puzzle15Empty,
  );

  static const size5 = PuzzleConfig(
    gridSize: 5,
    puzzleType: 'puzzle_24',
    titleKey: 'home_puzzle_5',
    background: AppColor.puzzle24Background,
    menuColor: AppColor.puzzle24MenuBackground,
    tileColor: AppColor.puzzle24Tile,
    textColor: AppColor.puzzle24Text,
    emptyColor: AppColor.puzzle24Empty,
  );

  static const all = [size3, size4, size5];
}

/// 3x3 퍼즐 화면
class Number8Screen extends PuzzleScreen {
  const Number8Screen({super.key, super.showAd, super.savedGame})
    : super(config: PuzzleConfig.size3);

  static const String puzzleType = 'puzzle_8';
}

/// 4x4 퍼즐 화면
class Number15Screen extends PuzzleScreen {
  const Number15Screen({super.key, super.showAd, super.savedGame})
    : super(config: PuzzleConfig.size4);

  static const String puzzleType = 'puzzle_15';
}

/// 5x5 퍼즐 화면
class Number24Screen extends PuzzleScreen {
  const Number24Screen({super.key, super.showAd, super.savedGame})
    : super(config: PuzzleConfig.size5);

  static const String puzzleType = 'puzzle_24';
}

/// 슬라이딩 퍼즐 게임 화면 (모든 난이도 공용)
class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({
    super.key,
    required this.config,
    this.showAd = true,
    this.savedGame,
  });

  final PuzzleConfig config;

  /// 광고 배너 표시 여부 (테스트에서는 false)
  final bool showAd;

  /// 이어할 게임 (없으면 새 게임)
  final SavedGame? savedGame;

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen>
    with WidgetsBindingObserver {
  PuzzleConfig get config => widget.config;
  String get puzzleType => config.puzzleType;

  /// 칸 순서대로의 숫자 (0은 빈칸)
  late List<int> tiles;
  late int emptyIndex;

  int moveCount = 0;
  int elapsedSeconds = 0;

  /// 타이머: 첫 이동을 한 순간 시작 (화면에 들어온 것만으로는 시간이 흐르지 않음)
  Timer? timer;

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

  @override
  void initState() {
    super.initState();
    loadBestScores();
    WidgetsBinding.instance.addObserver(this);
    final saved = widget.savedGame;
    if (saved != null && saved.tiles.length == config.tileCount) {
      restoreGame(saved); // 이어하기
    } else {
      _startNewGame();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    saveGame(); // 진행 상황 저장
    timer?.cancel();
    super.dispose();
  }

  Future<void> loadBestScores() async {
    final records = await RecordsStore.load(puzzleType);
    if (!mounted) return;
    setState(() {
      bestMoveCount = records.bestMoves;
      bestTime = records.bestTime;
    });
  }

  /// 완성한 게임을 기록에 반영 (최소 이동·최단 시간·완성 횟수·TOP 5)
  Future<RecordResult> saveBestScores(int moves, int time) async {
    final result = await RecordsStore.addResult(
      puzzleType,
      moves: moves,
      seconds: time,
    );
    bestMoveCount = result.records.bestMoves;
    bestTime = result.records.bestTime;
    return result;
  }

  /// 첫 이동 때 타이머 시작 (이미 돌고 있으면 그대로)
  void _startTimerIfNeeded() {
    timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isCompleted && !isPaused && !_inBackground) {
        setState(() => elapsedSeconds++);
      }
    });
  }

  void _stopTimer() {
    timer?.cancel();
    timer = null;
  }

  /// 저장된 게임 이어하기 (타이머는 다시 움직일 때 시작)
  void restoreGame(SavedGame saved) {
    tiles = List.of(saved.tiles);
    emptyIndex = tiles.indexOf(0);
    moveCount = saved.moves;
    elapsedSeconds = saved.seconds;
    hintsUsed = saved.hints;
    isCompleted = false;
  }

  /// 진행 상황 저장 (한 번도 움직이지 않았거나 완성한 게임은 저장하지 않음)
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

  /// 새로 섞은 판으로 시작 (너무 쉽게 섞이지 않은, 항상 풀 수 있는 판)
  void _startNewGame() {
    _stopTimer();
    _hintPath = [];
    _hintIndex = null;
    tiles = shuffledBoard(config.gridSize, Random());
    emptyIndex = tiles.indexOf(0);
    moveCount = 0;
    hintsUsed = 0;
    elapsedSeconds = 0;
    isCompleted = false;
  }

  /// 다시 시작 버튼 / 완성 후 다시 하기
  void resetPuzzle() {
    GameSaveStore.clear(puzzleType); // 새 게임이므로 이어하기 삭제
    setState(_startNewGame);
  }

  /// [tileIndex] 칸의 타일을 빈칸으로 한 칸 옮긴다.
  void swapTiles(int tileIndex) {
    if (isCompleted) return;

    if (_hintPath.isNotEmpty && _hintPath.first == tileIndex) {
      _hintPath.removeAt(0); // 힌트대로 둠 → 다음 힌트는 바로 이어서
    } else {
      _hintPath = []; // 다른 수를 둠 → 다음 힌트 때 다시 계산
    }
    _hintIndex = null;
    _startTimerIfNeeded();

    setState(() {
      tiles[emptyIndex] = tiles[tileIndex];
      tiles[tileIndex] = 0;
      emptyIndex = tileIndex;
      moveCount++;
    });

    checkPuzzleComplete();
    if (!isCompleted) saveGame(); // 이동할 때마다 저장
  }

  /// 타일을 탭하거나 끌었을 때
  void _onTileTap(int index) {
    // 빈칸과 같은 줄의 타일이면 그 사이 타일들까지 한 번에 밀기
    // (한 칸씩 옮긴 것과 같으므로 이동 횟수도 밀린 타일 수만큼)
    final steps = slideSteps(index, emptyIndex, config.gridSize);
    if (steps.isEmpty) {
      FeedbackService.instance.invalid();
      return;
    }
    FeedbackService.instance.move();
    for (final step in steps) {
      swapTiles(step);
    }
  }

  void checkPuzzleComplete() {
    if (!SavedGame.isSolved(tiles)) return;
    isCompleted = true;
    _stopTimer();
    FeedbackService.instance.win();
    GameSaveStore.clear(puzzleType); // 완성했으므로 이어하기 삭제

    saveBestScores(moveCount, elapsedSeconds).then((result) async {
      if (!mounted) return;
      setState(() {}); // 상단 최고 기록 갱신
      final action = await showCompletionDialog(
        context,
        color: config.menuColor,
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
              builder: (context) => RecordsScreen(initialIndex: config.index),
            ),
          );
        case CompletionAction.close:
          break;
      }
    });
  }

  /// 힌트: 다음에 움직일 타일을 강조
  Future<void> showHint() async {
    if (isCompleted || _hintLoading) return;
    if (_hintPath.isEmpty) {
      setState(() => _hintLoading = true);
      final snapshot = List.of(tiles);
      // 풀이 계산은 화면이 멈추지 않도록 별도 isolate에서
      final path = await compute(solveForHint, [...snapshot, config.gridSize]);
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

  /// 설정 창 열기 (열려 있는 동안 타이머 정지)
  Future<void> openSettings() async {
    setState(() => isPaused = true);
    await showSettingsDialog(context, color: config.menuColor);
    if (mounted) setState(() => isPaused = false);
  }

  String formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final menuButtonColor = shadeColor(config.menuColor, 0.12);
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) saveGame();
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: config.background,
          body: Column(
            children: [
              GameHeader3D(
                title: config.titleKey.tr(),
                color: config.menuColor,
              ),
              const SizedBox(height: 10),
              // 최고 기록
              Padding(
                padding: const EdgeInsets.all(8),
                child:
                    bestMoveCount != null && bestTime != null
                        ? BestRecordBadge3D(
                          color: config.menuColor,
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
                    children: [
                      // 남은 공간에 맞춰 보드가 줄어들도록
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: PuzzleBoard3D(
                              tiles: tiles,
                              gridSize: config.gridSize,
                              tileColor: config.tileColor,
                              textColor: config.textColor,
                              emptyColor: config.emptyColor,
                              frameColor: config.menuColor,
                              enabled: !isCompleted, // 완성 후에는 이동 불가
                              hintIndex: _hintIndex,
                              onTileTap: _onTileTap,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      StatsPanel3D(
                        moves: moveCount,
                        time: formatTime(elapsedSeconds),
                        color: config.tileColor,
                        textColor: config.textColor,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              GameMenuBar3D(
                color: config.menuColor,
                children: [
                  Button3D(
                    icon: Icons.arrow_back,
                    tooltip: 'menu_back'.tr(),
                    color: menuButtonColor,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Button3D(
                    icon: Icons.refresh,
                    tooltip: 'menu_restart'.tr(),
                    color: menuButtonColor,
                    onPressed: resetPuzzle,
                  ),
                  Button3D(
                    icon: _hintLoading ? Icons.hourglass_top : Icons.lightbulb,
                    tooltip: 'menu_hint'.tr(),
                    color: menuButtonColor,
                    onPressed: showHint,
                  ),
                  Button3D(
                    icon: Icons.settings,
                    tooltip: 'settings_tooltip'.tr(),
                    color: menuButtonColor,
                    onPressed: openSettings,
                  ),
                ],
              ),
              if (widget.showAd) const AdBannerWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
