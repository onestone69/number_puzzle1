import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:number_puzzle1/ad_policy.dart';
import 'package:number_puzzle1/consent_manager.dart';
import 'package:number_puzzle1/feedback_service.dart';
import 'package:number_puzzle1/screen/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 세로 화면 전용 레이아웃이므로 세로 모드로 고정
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await EasyLocalization.ensureInitialized();

  // 효과음·진동 설정 불러오기 (효과음 파일은 백그라운드에서 로드)
  await FeedbackService.instance.init();

  // 실행 횟수 기록 (광고 노출 빈도 조절에 사용)
  await AdPolicy.instance.recordLaunch();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ko')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      // 항상 기기 언어를 따름 (예전 실행에서 저장된 언어를 쓰지 않음)
      saveLocale: false,
      child: const MyApp(),
    ),
  );

  // 광고 동의(필요한 지역만) → 광고 SDK 초기화. 앱 시작을 늦추지 않도록 기다리지 않음
  unawaited(ConsentManager.instance.gatherConsentAndInitAds());
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
      // 기본 UI(버튼·대화상자 등)의 한국어 번역: material_ui용 delegate가 필요
      localizationsDelegates: [
        ...context.localizationDelegates,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(fontFamily: 'HiMelody'),
      home: const HomeScreen(),
    );
  }
}
