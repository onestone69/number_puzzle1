import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

import '../records_store.dart';
import 'game_ui_3d.dart';

/// 완성 축하 창에서 사용자가 고른 동작
enum CompletionAction { close, playAgain, records }

/// 순위 메달 색 (1위 금, 2위 은, 3위 동)
const _medalColors = [Color(0xFFE2A93B), Color(0xFFA8B0B8), Color(0xFFC58A5A)];

String _formatTime(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// 퍼즐 완성 축하 창. 이번 기록, 신기록 여부, TOP 5 순위를 보여준다.
Future<CompletionAction> showCompletionDialog(
  BuildContext context, {
  required Color color,
  required int moves,
  required int seconds,
  required RecordResult result,
  int hintsUsed = 0,
}) async {
  final action = await showGeneralDialog<CompletionAction>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder:
        (context, _, _) => _CompletionView(
          color: color,
          moves: moves,
          seconds: seconds,
          result: result,
          hintsUsed: hintsUsed,
        ),
    // 통통 튀며 나타남
    transitionBuilder:
        (context, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween(begin: 0.6, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.elasticOut),
            ),
            child: child,
          ),
        ),
  );
  return action ?? CompletionAction.close;
}

class _CompletionView extends StatefulWidget {
  const _CompletionView({
    required this.color,
    required this.moves,
    required this.seconds,
    required this.result,
    required this.hintsUsed,
  });

  final Color color;
  final int moves;
  final int seconds;
  final RecordResult result;
  final int hintsUsed;

  @override
  State<_CompletionView> createState() => _CompletionViewState();
}

class _CompletionViewState extends State<_CompletionView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..forward();

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final result = widget.result;
    final rank = result.rank;
    final textColor = shadeColor(color, -0.35);
    final accent =
        rank != null && rank <= 3
            ? _medalColors[rank - 1]
            : shadeColor(color, 0.1);

    TextStyle style(double size, {Color? c, FontWeight w = FontWeight.bold}) =>
        TextStyle(
          fontFamily: 'HiMelody',
          fontSize: size,
          fontWeight: w,
          color: c ?? textColor,
          decoration: TextDecoration.none,
        );

    return Stack(
      children: [
        // 색종이
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _confetti,
              builder:
                  (context, _) => CustomPaint(
                    painter: _ConfettiPainter(
                      progress: _confetti.value,
                      colors: [
                        color,
                        shadeColor(color, 0.4),
                        _medalColors[0],
                        Colors.white,
                        const Color(0xFFF8A6AB),
                        const Color(0xFF8FC7E8),
                      ],
                    ),
                  ),
            ),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Material(
                type: MaterialType.transparency,
                child: Raised3D(
                  color: shadeColor(color, 0.85),
                  radius: 28,
                  depth: 8,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 트로피 메달
                        SizedBox(
                          width: 84,
                          height: 84,
                          child: Raised3D(
                            color: accent,
                            radius: 42,
                            depth: 6,
                            expand: true,
                            child: Icon(
                              rank == 1 ? Icons.emoji_events : Icons.star,
                              size: 46,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: shadeColor(accent, -0.5),
                                  offset: const Offset(0, 2),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'completion_title'.tr(),
                          textAlign: TextAlign.center,
                          style: style(32).copyWith(
                            shadows: [
                              Shadow(
                                color: shadeColor(color, 0.4),
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 신기록 리본 / 순위 배지
                        if (result.isNewRecord) ...[
                          _Ribbon(
                            text: 'completion_new_record_short'.tr(),
                            color: const Color(0xFFE85D75),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (rank != null)
                          _Ribbon(
                            text: 'completion_rank'.tr(
                              namedArgs: {'rank': '$rank'},
                            ),
                            color: accent,
                            icon: Icons.military_tech,
                          )
                        else
                          Text(
                            'completion_not_ranked'.tr(),
                            textAlign: TextAlign.center,
                            style: style(19, w: FontWeight.normal),
                          ),
                        const SizedBox(height: 14),

                        // 이번 기록과 최고 기록
                        Row(
                          children: [
                            _StatBox(
                              icon: Icons.swap_horiz,
                              value: '${widget.moves}',
                              best: result.records.bestMoves?.toString(),
                              isNew: result.isNewBestMoves,
                              color: color,
                              textColor: textColor,
                            ),
                            const SizedBox(width: 12),
                            _StatBox(
                              icon: Icons.timer,
                              value: _formatTime(widget.seconds),
                              best:
                                  result.records.bestTime == null
                                      ? null
                                      : _formatTime(result.records.bestTime!),
                              isNew: result.isNewBestTime,
                              color: color,
                              textColor: textColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 힌트 사용 횟수 (안 썼으면 칭찬)
                        _HintsBadge(
                          hintsUsed: widget.hintsUsed,
                          color: color,
                          textColor: textColor,
                        ),
                        const SizedBox(height: 20),

                        // 버튼: 기록 보기 / 닫기 / 다시 하기
                        Row(
                          children: [
                            Pressable3D(
                              color: _medalColors[0],
                              width: 56,
                              height: 56,
                              semanticLabel: 'completion_records'.tr(),
                              onPressed:
                                  () => Navigator.of(
                                    context,
                                  ).pop(CompletionAction.records),
                              child: Tooltip(
                                message: 'completion_records'.tr(),
                                child: Icon(
                                  Icons.emoji_events,
                                  size: 28,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: shadeColor(_medalColors[0], -0.5),
                                      offset: const Offset(0, 1.5),
                                      blurRadius: 1.5,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _ActionButton(
                              label: 'completion_close'.tr(),
                              color: shadeColor(Colors.blueGrey, 0.25),
                              action: CompletionAction.close,
                            ),
                            const SizedBox(width: 12),
                            _ActionButton(
                              label: 'completion_play_again'.tr(),
                              color: color,
                              action: CompletionAction.playAgain,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 신기록·순위를 알리는 볼록한 리본
class _Ribbon extends StatelessWidget {
  const _Ribbon({required this.text, required this.color, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final shadow = Shadow(
      color: shadeColor(color, -0.5),
      offset: const Offset(0, 1.5),
      blurRadius: 1.5,
    );
    return Raised3D(
      color: color,
      radius: 20,
      depth: 5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 24, color: Colors.white, shadows: [shadow]),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'HiMelody',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                  shadows: [shadow],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 이번 기록 한 칸: 값 + 최고 기록 (+ 신기록이면 NEW 표시)
class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.value,
    required this.best,
    required this.isNew,
    required this.color,
    required this.textColor,
  });

  final IconData icon;
  final String value;
  final String? best;
  final bool isNew;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    TextStyle style(double size, {FontWeight w = FontWeight.bold}) => TextStyle(
      fontFamily: 'HiMelody',
      fontSize: size,
      fontWeight: w,
      color: textColor,
      decoration: TextDecoration.none,
    );

    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 칸이 가로로 꽉 차도록
          SizedBox(
            width: double.infinity,
            child: Inset3D(
              color: shadeColor(color, 0.72),
              radius: 18,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                child: Column(
                  children: [
                    Icon(icon, size: 24, color: textColor),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(value, style: style(34)),
                    ),
                    if (best != null)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'completion_best'.tr(namedArgs: {'value': best!}),
                          style: style(17, w: FontWeight.normal),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // 신기록 표시
          if (isNew)
            Positioned(
              top: -10,
              right: -6,
              child: Transform.rotate(
                angle: 0.2,
                child: Raised3D(
                  color: const Color(0xFFE85D75),
                  radius: 10,
                  depth: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 1,
                    ),
                    child: Text(
                      'completion_new'.tr(),
                      style: const TextStyle(
                        fontFamily: 'HiMelody',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.action,
  });

  final String label;
  final Color color;
  final CompletionAction action;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Pressable3D(
        color: color,
        width: double.infinity,
        height: 56,
        semanticLabel: label,
        onPressed: () => Navigator.of(context).pop(action),
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
                decoration: TextDecoration.none,
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
      ),
    );
  }
}

/// 위에서 흩날리며 떨어지는 색종이
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.colors});

  final double progress;
  final List<Color> colors;

  static final _pieces = List.generate(70, (i) {
    final r = Random(i * 7919);
    return (
      x: r.nextDouble(),
      delay: r.nextDouble() * 0.35,
      speed: 0.7 + r.nextDouble() * 0.6,
      sway: 10 + r.nextDouble() * 30,
      spin: (r.nextDouble() - 0.5) * 12,
      size: 6 + r.nextDouble() * 7,
      color: r.nextInt(1 << 16),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1) return;
    for (final p in _pieces) {
      final t = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final y = -20 + t * p.speed * (size.height + 60);
      final x = p.x * size.width + sin(t * pi * 3 + p.x * 10) * p.sway;
      // 마지막에 서서히 사라짐
      final fade = t > 0.75 ? (1 - t) / 0.25 : 1.0;
      final paint =
          Paint()
            ..color = colors[p.color % colors.length].withValues(
              alpha: 0.9 * fade,
            );
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * p.spin);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.55,
          ),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

/// 힌트 사용 횟수 표시. 힌트 없이 완성하면 칭찬 배지.
class _HintsBadge extends StatelessWidget {
  const _HintsBadge({
    required this.hintsUsed,
    required this.color,
    required this.textColor,
  });

  final int hintsUsed;
  final Color color;
  final Color textColor;

  static const _bulb = Color(0xFFF2B33D);

  @override
  Widget build(BuildContext context) {
    final noHints = hintsUsed == 0;
    final text =
        noHints
            ? 'completion_no_hints'.tr()
            : 'completion_hints'.tr(namedArgs: {'count': '$hintsUsed'});
    final label = Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'HiMelody',
        fontSize: 21,
        fontWeight: FontWeight.bold,
        color: noHints ? Colors.white : textColor,
        decoration: TextDecoration.none,
        shadows:
            noHints
                ? [
                  Shadow(
                    color: shadeColor(_bulb, -0.5),
                    offset: const Offset(0, 1.5),
                    blurRadius: 1.5,
                  ),
                ]
                : null,
      ),
    );
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            noHints ? Icons.auto_awesome : Icons.lightbulb,
            size: 22,
            color: noHints ? Colors.white : _bulb,
          ),
          const SizedBox(width: 6),
          Flexible(child: label),
        ],
      ),
    );
    // 힌트 없이 완성: 볼록한 금색 배지 / 힌트 사용: 움푹 파인 칸
    return noHints
        ? Raised3D(color: _bulb, radius: 18, depth: 4, child: content)
        : Inset3D(color: shadeColor(color, 0.72), radius: 18, child: content);
  }
}
