import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:material_ui/material_ui.dart';

import '../consent_manager.dart';
import '../feedback_service.dart';
import 'game_ui_3d.dart';

/// 효과음·음량·진동 설정 창을 띄운다. [color]는 화면의 테마 색.
Future<void> showSettingsDialog(BuildContext context, {required Color color}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder:
        (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: SettingsPanel(color: color),
        ),
  );
}

/// 설정 창 내용.
class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final feedback = FeedbackService.instance;
    final textColor = shadeColor(color, -0.35);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Raised3D(
        color: shadeColor(color, 0.85),
        radius: 28,
        depth: 8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: ListenableBuilder(
            listenable: feedback,
            builder:
                (context, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'settings_title'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'HiMelody',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        shadows: [
                          const Shadow(
                            color: Colors.white,
                            offset: Offset(0, -1),
                          ),
                          Shadow(
                            color: shadeColor(color, 0.4),
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 효과음 켜기/끄기
                    _SettingRow(
                      icon:
                          feedback.soundEnabled
                              ? Icons.volume_up
                              : Icons.volume_off,
                      label: 'settings_sound'.tr(),
                      textColor: textColor,
                      color: color,
                      trailing: Switch3D(
                        key: const ValueKey('sound_switch'),
                        value: feedback.soundEnabled,
                        color: color,
                        semanticLabel: 'settings_sound'.tr(),
                        onChanged: feedback.setSoundEnabled,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 음량 (효과음이 꺼져 있으면 비활성)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: feedback.soundEnabled ? 1 : 0.4,
                      child: IgnorePointer(
                        ignoring: !feedback.soundEnabled,
                        child: _VolumeSlider(
                          value: feedback.volume,
                          color: color,
                          textColor: textColor,
                          label: 'settings_volume'.tr(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 진동 켜기/끄기
                    _SettingRow(
                      icon: Icons.vibration,
                      label: 'settings_haptics'.tr(),
                      textColor: textColor,
                      color: color,
                      trailing: Switch3D(
                        key: const ValueKey('haptics_switch'),
                        value: feedback.hapticsEnabled,
                        color: color,
                        semanticLabel: 'settings_haptics'.tr(),
                        onChanged: feedback.setHapticsEnabled,
                      ),
                    ),
                    // 광고 동의가 필요한 지역(EEA·영국 등)에서만: 광고 동의 다시 선택
                    if (ConsentManager.instance.privacyOptionsRequired) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          FeedbackService.instance.tap();
                          ConsentManager.instance.showPrivacyOptions();
                        },
                        child: _SettingRow(
                          icon: Icons.privacy_tip,
                          label: 'settings_privacy'.tr(),
                          textColor: textColor,
                          color: color,
                          trailing: Icon(Icons.chevron_right, color: textColor),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),

                    Center(
                      child: Pressable3D(
                        color: color,
                        width: 160,
                        height: 54,
                        onPressed: () => Navigator.of(context).pop(),
                        semanticLabel: 'settings_close'.tr(),
                        child: Text(
                          'settings_close'.tr(),
                          style: TextStyle(
                            fontFamily: 'HiMelody',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: shadeColor(color, -0.5),
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
        ),
      ),
    );
  }
}

/// 아이콘 + 이름 + 오른쪽 컨트롤이 있는 설정 한 줄 (움푹 파인 칸 안에 표시).
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.color,
    required this.trailing,
  });

  final IconData icon;
  final String label;
  final Color textColor;
  final Color color;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Inset3D(
      color: shadeColor(color, 0.7),
      radius: 16,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
        child: Row(
          children: [
            Icon(icon, size: 26, color: textColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'HiMelody',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    required this.value,
    required this.color,
    required this.textColor,
    required this.label,
  });

  final double value;
  final Color color;
  final Color textColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    final feedback = FeedbackService.instance;
    return Inset3D(
      color: shadeColor(color, 0.7),
      radius: 16,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Row(
          children: [
            Icon(Icons.volume_mute, size: 24, color: textColor),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 8,
                  activeTrackColor: color,
                  inactiveTrackColor: shadeColor(color, 0.45),
                  thumbColor: Colors.white,
                  overlayColor: color.withValues(alpha: 0.2),
                  thumbShape: _Thumb3D(color: color),
                ),
                child: Slider(
                  value: value,
                  semanticFormatterCallback:
                      (v) => '$label ${(v * 100).round()}%',
                  onChanged: (v) => feedback.setVolume(v, save: false),
                  onChangeEnd: (v) => feedback.setVolume(v),
                ),
              ),
            ),
            Icon(Icons.volume_up, size: 24, color: textColor),
          ],
        ),
      ),
    );
  }
}

/// 입체 토글 스위치: 움푹 파인 홈 안에서 볼록한 손잡이가 좌우로 움직인다.
class Switch3D extends StatelessWidget {
  const Switch3D({
    super.key,
    required this.value,
    required this.color,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 160);
    return Semantics(
      toggled: value,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: SizedBox(
          width: 66,
          height: 38,
          child: Stack(
            children: [
              // 홈 (켜지면 테마 색)
              Positioned.fill(
                top: 2,
                bottom: 2,
                child: AnimatedContainer(
                  duration: duration,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors:
                          value
                              ? [shadeColor(color, -0.25), color]
                              : [Colors.grey.shade500, Colors.grey.shade300],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
              // 손잡이
              AnimatedAlign(
                duration: duration,
                curve: Curves.easeOutBack,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3),
                  child: SizedBox(
                    width: 30,
                    height: 32,
                    child: Raised3D(
                      color: Colors.white,
                      radius: 15,
                      depth: 3,
                      expand: true,
                      child: SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 슬라이더 손잡이: 부드러운 그림자와 테마 색 테두리가 있는 흰 원.
class _Thumb3D extends SliderComponentShape {
  const _Thumb3D({required this.color});

  final Color color;
  static const _radius = 12.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    // 바닥 그림자
    canvas.drawCircle(
      center + const Offset(0, 2),
      _radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    // 윗면 (위가 밝은 그라데이션)
    final rect = Rect.fromCircle(center: center, radius: _radius);
    canvas.drawCircle(
      center,
      _radius,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.grey.shade200],
        ).createShader(rect),
    );
    canvas.drawCircle(
      center,
      _radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
  }
}
