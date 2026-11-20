import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

import '../game_save.dart';
import 'game_ui_3d.dart';

/// 저장된 게임을 이어할지 묻는다.
///
/// true: 이어하기, false: 새 게임, null: 취소(창 바깥을 누름)
Future<bool?> showContinueDialog(
  BuildContext context, {
  required Color color,
  required SavedGame saved,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder:
        (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(24),
          child: _ContinuePanel(color: color, saved: saved),
        ),
  );
}

String _formatTime(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

class _ContinuePanel extends StatelessWidget {
  const _ContinuePanel({required this.color, required this.saved});

  final Color color;
  final SavedGame saved;

  @override
  Widget build(BuildContext context) {
    final textColor = shadeColor(color, -0.35);

    Widget statChip(IconData icon, String value) => Inset3D(
      color: shadeColor(color, 0.7),
      radius: 14,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: textColor),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'HiMelody',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );

    Widget button(String label, Color buttonColor, bool result) => Expanded(
      child: Pressable3D(
        color: buttonColor,
        width: double.infinity,
        height: 56,
        semanticLabel: label,
        onPressed: () => Navigator.of(context).pop(result),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'HiMelody',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: shadeColor(buttonColor, -0.5),
                    offset: const Offset(0, 1.5),
                    blurRadius: 1.5,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Raised3D(
        color: shadeColor(color, 0.85),
        radius: 28,
        depth: 8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 40, color: textColor),
              const SizedBox(height: 4),
              Text(
                'continue_title'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'HiMelody',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  shadows: [
                    Shadow(
                      color: shadeColor(color, 0.4),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'continue_message'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'HiMelody',
                  fontSize: 20,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 14),
              // 진행 상황: 이동 횟수, 경과 시간
              Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  statChip(Icons.swap_horiz, '${saved.moves}'),
                  statChip(Icons.timer, _formatTime(saved.seconds)),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  button(
                    'continue_new'.tr(),
                    shadeColor(Colors.blueGrey, 0.25),
                    false,
                  ),
                  const SizedBox(width: 14),
                  button('continue_resume'.tr(), color, true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
