import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 효과음 종류. [path]는 assets/ 기준 경로, [length]는 재생 길이.
enum Sfx {
  tap('sounds/tap.wav', Duration(milliseconds: 80)),
  move('sounds/move.wav', Duration(milliseconds: 120)),
  invalid('sounds/invalid.wav', Duration(milliseconds: 180)),
  win('sounds/win.wav', Duration(milliseconds: 1400));

  const Sfx(this.path, this.length);

  final String path;
  final Duration length;
}

/// 효과음과 햅틱(진동) 피드백, 그리고 그 설정을 관리한다.
///
/// 설정이 바뀌면 리스너에게 알리므로 설정 화면에서 바로 반영된다.
class FeedbackService extends ChangeNotifier {
  FeedbackService._();

  static final FeedbackService instance = FeedbackService._();

  static const _soundKey = 'settings_sound';
  static const _volumeKey = 'settings_volume';
  static const _hapticsKey = 'settings_haptics';

  bool _soundEnabled = true;
  double _volume = 0.8;
  bool _hapticsEnabled = true;

  bool _audioReady = false;
  final Map<Sfx, AudioPool> _pools = {};

  bool get soundEnabled => _soundEnabled;
  double get volume => _volume;
  bool get hapticsEnabled => _hapticsEnabled;

  /// 저장된 설정을 불러오고 효과음을 미리 로드한다.
  ///
  /// 설정은 기다려서 불러오고, 효과음 로드는 앱 시작을 늦추지 않도록
  /// 백그라운드에서 진행한다.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool(_soundKey) ?? true;
    _volume = prefs.getDouble(_volumeKey) ?? 0.8;
    _hapticsEnabled = prefs.getBool(_hapticsKey) ?? true;
    notifyListeners();
    unawaited(_loadAudio());
  }

  Future<void> _loadAudio() async {
    try {
      // 게임 효과음: 다른 앱의 음악을 끊지 않고, iOS에서는 무음 스위치를 따른다.
      final audioContext = AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
      );
      await AudioPlayer.global.setAudioContext(audioContext);
      for (final sfx in Sfx.values) {
        _pools[sfx] = await AudioPool.create(
          source: AssetSource(sfx.path),
          maxPlayers: sfx == Sfx.win ? 1 : 4,
          playerMode: PlayerMode.lowLatency,
          audioContext: audioContext,
        );
      }
      _audioReady = true;
    } catch (e) {
      debugPrint('효과음 로드 실패: $e');
    }
  }

  // ───────────── 설정 변경 ─────────────

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    notifyListeners();
    if (value) _play(Sfx.tap); // 켰을 때 미리 들려줌
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, value);
  }

  /// 음량 변경. 슬라이더를 움직이는 동안에는 [save]를 false로 호출하고,
  /// 손을 뗐을 때 true로 호출해 저장한다.
  Future<void> setVolume(double value, {bool save = true}) async {
    _volume = value.clamp(0.0, 1.0);
    notifyListeners();
    if (!save) return;
    _play(Sfx.tap); // 바뀐 음량으로 미리 들려줌
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, _volume);
  }

  Future<void> setHapticsEnabled(bool value) async {
    _hapticsEnabled = value;
    notifyListeners();
    if (value) _haptic(HapticFeedback.mediumImpact); // 켰을 때 미리 느끼게 함
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsKey, value);
  }

  // ───────────── 피드백 ─────────────

  /// 버튼 탭
  void tap() {
    _play(Sfx.tap);
    _haptic(HapticFeedback.selectionClick);
  }

  /// 타일 이동
  void move() {
    _play(Sfx.move);
    _haptic(HapticFeedback.lightImpact);
  }

  /// 움직일 수 없는 타일을 탭함
  void invalid() {
    _play(Sfx.invalid);
    _haptic(HapticFeedback.mediumImpact);
  }

  /// 퍼즐 완성 (진동 두 번)
  void win() {
    _play(Sfx.win);
    _haptic(HapticFeedback.heavyImpact);
    Future<void>.delayed(
      const Duration(milliseconds: 180),
      () => _haptic(HapticFeedback.heavyImpact),
    );
  }

  void _haptic(Future<void> Function() feedback) {
    if (!_hapticsEnabled) return;
    // 진동을 지원하지 않는 기기에서도 앱이 멈추지 않도록 오류 무시
    unawaited(feedback().catchError((Object _) {}));
  }

  void _play(Sfx sfx) {
    if (!_soundEnabled || !_audioReady || _volume <= 0) return;
    final pool = _pools[sfx];
    if (pool == null) return;
    unawaited(() async {
      try {
        final stop = await pool.start(volume: _volume);
        // 저지연 모드는 재생 완료 이벤트가 없으므로 길이만큼 뒤에 반납
        await Future<void>.delayed(sfx.length);
        await stop();
      } catch (e) {
        debugPrint('효과음 재생 실패: $e');
      }
    }());
  }
}
