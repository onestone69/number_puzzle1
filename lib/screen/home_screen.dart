import 'package:material_ui/material_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:number_puzzle1/app_open_ad_manager.dart';
import 'package:number_puzzle1/screen/number8_screen.dart';
import 'package:number_puzzle1/screen/number15_screen.dart';
import 'package:number_puzzle1/screen/number24_screen.dart';

import '../app_color.dart';
import '../widgets/game_ui_3d.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AppOpenAdManager _appOpenAdManager = AppOpenAdManager();

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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                              color: shadeColor(_titleColor, -0.25 - i * 0.04),
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
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Number8Screen()),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4x4 퍼즐 버튼
                  _buildPuzzleButton(
                    'home_puzzle_4'.tr(),
                    Icons.grid_4x4,
                    AppColor.puzzle15MenuBackground,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Number15Screen()),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5x5 퍼즐 버튼
                  _buildPuzzleButton(
                    'home_puzzle_5'.tr(),
                    Icons.grid_on,
                    AppColor.puzzle24MenuBackground,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Number24Screen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPuzzleButton(
    String text,
    IconData icon,
    Color color,
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30, color: Colors.white, shadows: [shadow]),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'HiMelody',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [shadow],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appOpenAdManager.loadAd();
    Future.delayed(Duration(seconds: 3), () {
      _appOpenAdManager.showAdIfAvailable();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appOpenAdManager.showAdIfAvailable();
    }
  }
}
