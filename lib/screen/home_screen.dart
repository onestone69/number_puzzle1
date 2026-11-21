import 'package:material_ui/material_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:number_puzzle1/app_open_ad_manager.dart';
import 'package:number_puzzle1/screen/puzzle_screen.dart';

import '../app_color.dart';
import '../consent_manager.dart';
import '../game_save.dart';
import '../widgets/continue_dialog.dart';
import '../widgets/game_ui_3d.dart';
import 'records_screen.dart';
import '../widgets/settings_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AppOpenAdManager _appOpenAdManager = AppOpenAdManager();
  VoidCallback? _cancelAdsWait;

  static const _background = Color(0xFFF8E8EE); // 파스텔 핑크 배경
  static const _titleColor = Color(0xFF9E7676); // 파스텔 브라운

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              shadeColor(_background, 0.4),
              shadeColor(_background, -0.06),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 제목 (아래로 겹친 그림자로 두께가 있는 입체 글자)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'app_title'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'HiMelody',
                              fontSize: 52,
                              fontWeight: FontWeight.bold,
                              color: _titleColor,
                              shadows: [
                                const Shadow(
                                  color: Colors.white,
                                  offset: Offset(0, -1.5),
                                ),
                                for (var i = 1; i <= 5; i++)
                                  Shadow(
                                    color: shadeColor(
                                      _titleColor,
                                      -0.25 - i * 0.04,
                                    ),
                                    offset: Offset(0, i.toDouble()),
                                  ),
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  offset: const Offset(0, 8),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 56),

                        // 3x3 퍼즐 버튼
                        _buildPuzzleButton(
                          'home_puzzle_3'.tr(),
                          Icons.grid_3x3,
                          AppColor.puzzle8MenuBackground,
                          _saves[Number8Screen.puzzleType],
                          () => _openPuzzle(
                            Number8Screen.puzzleType,
                            9,
                            AppColor.puzzle8MenuBackground,
                            (saved) => Number8Screen(savedGame: saved),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 4x4 퍼즐 버튼
                        _buildPuzzleButton(
                          'home_puzzle_4'.tr(),
                          Icons.grid_4x4,
                          AppColor.puzzle15MenuBackground,
                          _saves[Number15Screen.puzzleType],
                          () => _openPuzzle(
                            Number15Screen.puzzleType,
                            16,
                            AppColor.puzzle15MenuBackground,
                            (saved) => Number15Screen(savedGame: saved),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 5x5 퍼즐 버튼
                        _buildPuzzleButton(
                          'home_puzzle_5'.tr(),
                          Icons.grid_on,
                          AppColor.puzzle24MenuBackground,
                          _saves[Number24Screen.puzzleType],
                          () => _openPuzzle(
                            Number24Screen.puzzleType,
                            25,
                            AppColor.puzzle24MenuBackground,
                            (saved) => Number24Screen(savedGame: saved),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // 기록 보기 버튼
                        Pressable3D(
                          color: recordsColor,
                          width: 200,
                          height: 62,
                          radius: 18,
                          depth: 7,
                          semanticLabel: 'records_button'.tr(),
                          onPressed:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RecordsScreen(),
                                ),
                              ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.emoji_events,
                                size: 28,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: shadeColor(recordsColor, -0.5),
                                    offset: const Offset(0, 1.5),
                                    blurRadius: 1.5,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'records_button'.tr(),
                                    style: TextStyle(
                                      fontFamily: 'HiMelody',
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: shadeColor(recordsColor, -0.5),
                                          offset: const Offset(0, 1.5),
                                          blurRadius: 1.5,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 설정 버튼
              Positioned(
                top: 8,
                right: 12,
                child: Pressable3D(
                  color: shadeColor(_titleColor, 0.25),
                  width: 56,
                  height: 50,
                  radius: 16,
                  semanticLabel: 'settings_tooltip'.tr(),
                  onPressed:
                      () => showSettingsDialog(
                        context,
                        color: shadeColor(_titleColor, 0.1),
                      ),
                  child: Icon(
                    Icons.settings,
                    size: 28,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: shadeColor(_titleColor, -0.5),
                        offset: const Offset(0, 1.5),
                        blurRadius: 1.5,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPuzzleButton(
    String text,
    IconData icon,
    Color color,
    SavedGame? saved,
    VoidCallback onPressed,
  ) {
    final shadow = Shadow(
      color: shadeColor(color, -0.5),
      offset: const Offset(0, 2),
      blurRadius: 2,
    );
    return Pressable3D(
      color: color,
      onPressed: onPressed,
      width: 240,
      height: 86,
      radius: 20,
      depth: 8,
      semanticLabel: text,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: Colors.white, shadows: [shadow]),
            const SizedBox(width: 12),
            // 긴 문구도 버튼 안에 들어가도록 필요하면 축소
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        fontFamily: 'HiMelody',
                        fontSize: 28,
                        height: 1.1,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [shadow],
                      ),
                    ),
                    // 저장된 게임이 있으면 이어하기 정보 표시
                    if (saved != null)
                      Text(
                        'home_continue'.tr(
                          namedArgs: {
                            'moves': saved.moves.toString(),
                            'time': _formatTime(saved.seconds),
                          },
                        ),
                        style: TextStyle(
                          fontFamily: 'HiMelody',
                          fontSize: 17,
                          height: 1.1,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.92),
                          shadows: [shadow],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// 퍼즐별 이어하기 정보 (홈 버튼에 표시)
  final Map<String, SavedGame?> _saves = {};

  Future<void> _loadSaves() async {
    final loaded = {
      Number8Screen.puzzleType: await GameSaveStore.load(
        Number8Screen.puzzleType,
        9,
      ),
      Number15Screen.puzzleType: await GameSaveStore.load(
        Number15Screen.puzzleType,
        16,
      ),
      Number24Screen.puzzleType: await GameSaveStore.load(
        Number24Screen.puzzleType,
        25,
      ),
    };
    if (!mounted) return;
    setState(
      () =>
          _saves
            ..clear()
            ..addAll(loaded),
    );
  }

  /// 저장된 게임이 있으면 이어서, 없으면 새 게임으로 연다.
  Future<void> _openPuzzle(
    String puzzleType,
    int tileCount,
    Color color,
    Widget Function(SavedGame? saved) builder,
  ) async {
    var saved = await GameSaveStore.load(puzzleType, tileCount);
    if (!mounted) return;
    if (saved != null) {
      // 저장된 게임이 있으면 이어할지 물어봄
      final resume = await showContinueDialog(
        context,
        color: color,
        saved: saved,
      );
      if (resume == null || !mounted) return; // 취소
      if (!resume) {
        await GameSaveStore.clear(puzzleType); // 새 게임
        saved = null;
      }
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => builder(saved)),
    );
    _loadSaves(); // 돌아오면 이어하기 정보 갱신
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSaves();
    // 앱 열기 광고: 광고 동의·SDK 초기화가 끝난 뒤, 노출 규칙(AdPolicy)을 만족할 때만
    _cancelAdsWait = ConsentManager.instance.whenAdsAllowed(
      _appOpenAdManager.onColdStart,
    );
  }

  @override
  void dispose() {
    _cancelAdsWait?.call();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _appOpenAdManager.onPaused();
      case AppLifecycleState.resumed:
        _appOpenAdManager.onResumed();
      default:
        break;
    }
  }
}
