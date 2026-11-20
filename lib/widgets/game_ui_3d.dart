import 'package:material_ui/material_ui.dart';

import '../feedback_service.dart';

/// 색을 [amount]만큼 밝게(양수) 또는 어둡게(음수) 만든다.
Color shadeColor(Color color, double amount) {
  return amount >= 0
      ? Color.lerp(color, Colors.white, amount)!
      : Color.lerp(color, Colors.black, -amount)!;
}

const _pressDuration = Duration(milliseconds: 70);

/// 두께(옆면)와 바닥 그림자가 있는 볼록한 판.
///
/// [pressed]가 true이면 윗면이 아래로 눌려 들어간다.
/// [expand]가 true이면 주어진 공간을 꽉 채우고, false이면 [child] 크기에 맞춘다.
class Raised3D extends StatelessWidget {
  const Raised3D({
    super.key,
    required this.color,
    required this.child,
    this.radius = 16,
    this.depth = 6,
    this.pressed = false,
    this.expand = false,
    this.rimWidth = 1.2,
  });

  final Color color;
  final Widget child;
  final double radius;
  final double depth;
  final bool pressed;
  final bool expand;
  final double rimWidth;

  @override
  Widget build(BuildContext context) {
    final sink = pressed ? depth * 0.7 : 0.0;
    final borderRadius = BorderRadius.circular(radius);

    return Stack(
      fit: expand ? StackFit.expand : StackFit.loose,
      children: [
        // 옆면(두께) + 바닥 그림자
        Positioned.fill(
          top: depth,
          child: AnimatedContainer(
            duration: _pressDuration,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              color: shadeColor(color, -0.3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: pressed ? depth * 0.6 : depth * 1.6,
                  offset: Offset(0, pressed ? depth * 0.2 : depth * 0.7),
                ),
              ],
            ),
          ),
        ),
        // 윗면
        AnimatedContainer(
          duration: _pressDuration,
          margin: EdgeInsets.only(top: sink, bottom: depth - sink),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                shadeColor(color, pressed ? 0.12 : 0.3),
                color,
                shadeColor(color, -0.08),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: rimWidth,
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

/// 움푹 파인 홈. 위쪽이 어두워 안으로 들어가 보인다.
class Inset3D extends StatelessWidget {
  const Inset3D({
    super.key,
    required this.color,
    required this.child,
    this.radius = 12,
  });

  final Color color;
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.35, 1],
          colors: [shadeColor(color, -0.2), color, shadeColor(color, 0.05)],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

/// 누르면 눌려 들어가는 입체 버튼. [child]에 아이콘이나 글자를 넣는다.
class Pressable3D extends StatefulWidget {
  const Pressable3D({
    super.key,
    required this.color,
    required this.onPressed,
    required this.child,
    required this.width,
    required this.height,
    this.radius = 16,
    this.depth = 6,
    this.semanticLabel,
  });

  final Color color;
  final VoidCallback onPressed;
  final Widget child;
  final double width;
  final double height;
  final double radius;
  final double depth;
  final String? semanticLabel;

  @override
  State<Pressable3D> createState() => _Pressable3DState();
}

class _Pressable3DState extends State<Pressable3D> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: () {
          FeedbackService.instance.tap();
          widget.onPressed();
        },
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Raised3D(
            color: widget.color,
            radius: widget.radius,
            depth: widget.depth,
            pressed: _pressed,
            expand: true,
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// 누르면 눌려 들어가는 입체 아이콘 버튼.
class Button3D extends StatelessWidget {
  const Button3D({
    super.key,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Pressable3D(
      color: color,
      onPressed: onPressed,
      width: 72,
      height: 54,
      semanticLabel: tooltip,
      child: Icon(
        icon,
        size: 28,
        color: Colors.white,
        shadows: [
          Shadow(
            color: shadeColor(color, -0.5),
            offset: const Offset(0, 1.5),
            blurRadius: 1.5,
          ),
        ],
      ),
    );
    final message = tooltip;
    return message == null ? button : Tooltip(message: message, child: button);
  }
}

/// 입체적인 상단 제목 바.
class GameHeader3D extends StatelessWidget {
  const GameHeader3D({super.key, required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [shadeColor(color, 0.18), shadeColor(color, -0.06)],
        ),
        // 아래쪽 두께
        border: Border(
          bottom: BorderSide(color: shadeColor(color, -0.3), width: 5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'HiMelody',
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: shadeColor(color, -0.45),
              offset: const Offset(0, 2.5),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// 입체 버튼을 담는 하단 메뉴 바.
class GameMenuBar3D extends StatelessWidget {
  const GameMenuBar3D({super.key, required this.color, required this.children});

  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [shadeColor(color, 0.12), shadeColor(color, -0.12)],
        ),
        // 위쪽 하이라이트
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: children,
      ),
    );
  }
}

/// 이동 횟수와 경과 시간을 보여주는 입체 표시줄.
class StatsPanel3D extends StatelessWidget {
  const StatsPanel3D({
    super.key,
    required this.moves,
    required this.time,
    required this.color,
    required this.textColor,
  });

  final int moves;
  final String time;
  final Color color;
  final Color textColor;

  Widget _stat(IconData icon, String value) {
    return Inset3D(
      color: shadeColor(color, -0.08),
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
                shadows: [
                  Shadow(
                    color: shadeColor(color, -0.45),
                    offset: const Offset(0, 1.5),
                    blurRadius: 1.5,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 좁은 화면에서는 축소해서 표시
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Raised3D(
        color: color,
        radius: 24,
        depth: 7,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _stat(Icons.swap_horiz, '$moves'),
              const SizedBox(width: 14),
              _stat(Icons.timer, time),
            ],
          ),
        ),
      ),
    );
  }
}

/// 최고 기록을 보여주는 볼록한 배지.
class BestRecordBadge3D extends StatelessWidget {
  const BestRecordBadge3D({super.key, required this.text, required this.color});

  final String text;

  /// 테마 색 (배지는 이 색을 밝게, 글자는 어둡게 사용)
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textColor = shadeColor(color, -0.3);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Raised3D(
        color: shadeColor(color, 0.78),
        radius: 18,
        depth: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, size: 22, color: textColor),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  fontFamily: 'HiMelody',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
