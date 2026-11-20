import 'package:material_ui/material_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:number_puzzle1/app_open_ad_manager.dart';
import 'package:number_puzzle1/screen/number8_screen.dart';
import 'package:number_puzzle1/screen/number15_screen.dart';
import 'package:number_puzzle1/screen/number24_screen.dart';

import '../app_color.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AppOpenAdManager _appOpenAdManager = AppOpenAdManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8E8EE), // 파스텔 핑크 배경
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 제목
              Text(
                'app_title'.tr(),
                style: TextStyle(
                  fontFamily: 'HiMelody',
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9E7676), // 파스텔 브라운
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.white,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 60),

              // 3x3 퍼즐 버튼
              _buildPuzzleButton(
                context,
                'home_puzzle_3'.tr(),
                AppColor.puzzle8MenuBackground, // 파스텔 로즈
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Number8Screen()),
                ),
              ),
              SizedBox(height: 20),

              // 4x4 퍼즐 버튼
              _buildPuzzleButton(
                context,
                'home_puzzle_4'.tr(),
                AppColor.puzzle15MenuBackground, // 파스텔 블루
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Number15Screen()),
                ),
              ),
              SizedBox(height: 20),

              // 5x5 퍼즐 버튼
              _buildPuzzleButton(
                context,
                'home_puzzle_5'.tr(),
                AppColor.puzzle24MenuBackground, // 파스텔 그린
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Number24Screen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPuzzleButton(
    BuildContext context,
    String text,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      width: 200,
      height: 80,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'HiMelody',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
