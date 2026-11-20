import 'package:material_ui/material_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:number_puzzle1/feedback_service.dart';
import 'package:number_puzzle1/screen/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 세로 화면 전용 레이아웃이므로 세로 모드로 고정
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await EasyLocalization.ensureInitialized();

  // 효과음·진동 설정 불러오기 (효과음 파일은 백그라운드에서 로드)
  await FeedbackService.instance.init();

  //AdMob 초기화
  await MobileAds.instance.initialize();

  runApp(
    EasyLocalization(
      //supportedLocales: const [Locale('en'), Locale('ko')],
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // 초기화 코드를 여기에 추가할 수 있습니다
  }

  @override
  void dispose() {
    // 정리 코드를 여기에 추가할 수 있습니다
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sliding Puzzle',
      debugShowCheckedModeBanner: false, // 디버그 배너 제거
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(fontFamily: 'HiMelody'),
      home: const HomeScreen(),
    );
  }
}
