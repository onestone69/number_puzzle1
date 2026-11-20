import 'package:material_ui/material_ui.dart';

import 'game_ui_3d.dart';

/// 입체적으로 보이는 슬라이딩 퍼즐 보드.
///
/// [tiles]는 칸 순서대로의 숫자 목록이며 0은 빈칸이다.
/// 타일은 숫자별로 위치가 애니메이션되어 이동할 때 미끄러지듯 움직인다.
class PuzzleBoard3D extends StatelessWidget {
  const PuzzleBoard3D({
    super.key,
    required this.tiles,
    required this.gridSize,
    required this.tileColor,
    required this.textColor,
    required this.emptyColor,
    required this.frameColor,
    required this.onTileTap,
    this.enabled = true,
    this.hintIndex,
  });

  final List<int> tiles;
  final int gridSize;
  final Color tileColor;
  final Color textColor;
  final Color emptyColor;
  final Color frameColor;
  final bool enabled;

  /// 타일을 탭했을 때 그 타일의 칸 번호(index)를 전달한다.
  final ValueChanged<int> onTileTap;

  /// 힌트로 강조할 타일의 칸 번호 (없으면 null)
  final int? hintIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;
        final frame = size * 0.035; // 바깥 틀 두께
        final inner = size - frame * 2;
        final pad = inner * 0.025; // 홈 안쪽 여백
        final gap = inner * 0.022; // 타일 간격
        final cell = (inner - pad * 2 - gap * (gridSize - 1)) / gridSize;
        final radius = cell * 0.16;

        Offset cellOffset(int index) => Offset(
          pad + (index % gridSize) * (cell + gap),
          pad + (index ~/ gridSize) * (cell + gap),
        );

        // 숫자 → 현재 칸 번호
        final positionOf = <int, int>{
          for (var i = 0; i < tiles.length; i++) tiles[i]: i,
        };

        return Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(frame),
          // 바깥 틀: 위는 밝고 아래는 어두운 그라데이션 + 바닥 그림자
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius + frame + pad),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                shadeColor(frameColor, 0.25),
                shadeColor(frameColor, -0.2),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: size * 0.05,
                offset: Offset(0, size * 0.025),
              ),
            ],
          ),
          child: Container(
            // 안쪽 홈: 위쪽이 어두워 움푹 들어가 보이도록
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius + pad),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.12, 1],
                colors: [
                  shadeColor(emptyColor, -0.25),
                  shadeColor(emptyColor, -0.08),
                  emptyColor,
                ],
              ),
            ),
            child: Stack(
              children: [
                // 각 칸의 파인 자리
                for (var i = 0; i < gridSize * gridSize; i++)
                  Positioned(
                    left: cellOffset(i).dx,
                    top: cellOffset(i).dy,
                    width: cell,
                    height: cell,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            shadeColor(emptyColor, -0.14),
                            shadeColor(emptyColor, -0.04),
                          ],
                        ),
                      ),
                    ),
                  ),
                // 숫자 타일 (숫자를 키로 써서 위치 변경 시 미끄러지게 함)
                for (var value = 1; value < gridSize * gridSize; value++)
                  if (positionOf[value] case final index?)
                    AnimatedPositioned(
                      key: ValueKey(value),
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutCubic,
                      left: cellOffset(index).dx,
                      top: cellOffset(index).dy,
                      width: cell,
                      height: cell,
                      child: _HintPulse(
                        key: ValueKey('hint-$value'),
                        // 힌트 타일이면 빈칸 방향으로 살짝 들썩이며 빛남
                        direction:
                            index == hintIndex
                                ? Offset(
                                  ((positionOf[0]! % gridSize) -
                                          (index % gridSize))
                                      .toDouble(),
                                  ((positionOf[0]! ~/ gridSize) -
                                          (index ~/ gridSize))
                                      .toDouble(),
                                )
                                : null,
                        distance: cell * 0.06,
                        radius: radius,
                        child: _Tile3D(
                          value: value,
                          color: tileColor,
                          textColor: textColor,
                          radius: radius,
                          enabled: enabled,
                          onTap: () => onTileTap(index),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 두께와 그림자가 있는 입체 타일. 누르면 아래로 눌려 들어간다.
class _Tile3D extends StatefulWidget {
  const _Tile3D({
    required this.value,
    required this.color,
    required this.textColor,
    required this.radius,
    required this.enabled,
    required this.onTap,
  });

  final int value;
  final Color color;
  final Color textColor;
  final double radius;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_Tile3D> createState() => _Tile3DState();
}

class _Tile3DState extends State<_Tile3D> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = constraints.maxHeight;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.enabled ? (_) => _setPressed(true) : null,
          onTapUp: widget.enabled ? (_) => _setPressed(false) : null,
          onTapCancel: () => _setPressed(false),
          onTap: widget.enabled ? widget.onTap : null,
          child: Raised3D(
            color: widget.color,
            radius: widget.radius,
            depth: cell * 0.08, // 타일 두께
            pressed: _pressed,
            expand: true,
            rimWidth: cell * 0.012 + 0.5,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.all(cell * 0.08),
                  child: Text(
                    '${widget.value}',
                    style: TextStyle(
                      fontFamily: 'HiMelody',
                      fontSize: cell * 0.5,
                      fontWeight: FontWeight.bold,
                      color: widget.textColor,
                      // 글자가 도드라져 보이도록 아래쪽 그림자
                      shadows: [
                        Shadow(
                          color: shadeColor(widget.color, -0.45),
                          offset: Offset(0, cell * 0.022),
                          blurRadius: cell * 0.02,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 힌트 강조: [direction]이 있으면 그 방향(빈칸 쪽)으로 들썩이며 빛난다.
class _HintPulse extends StatefulWidget {
  const _HintPulse({
    super.key,
    required this.direction,
    required this.distance,
    required this.radius,
    required this.child,
  });

  final Offset? direction;
  final double distance;
  final double radius;
  final Widget child;

  @override
  State<_HintPulse> createState() => _HintPulseState();
}

class _HintPulseState extends State<_HintPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  static const _glow = Color(0xFFFFD54F);

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_HintPulse old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.direction != null) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else if (_controller.isAnimating || _controller.value != 0) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final direction = widget.direction;
    if (direction == null) return widget.child;
    return Semantics(
      label: 'hint',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_controller.value);
          return Transform.translate(
            offset: direction * widget.distance * t,
            child: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                // 바깥으로 퍼지는 빛 (타일 아래)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.radius),
                      boxShadow: [
                        BoxShadow(
                          color: _glow.withValues(alpha: 0.55 + t * 0.35),
                          blurRadius: 10 + t * 10,
                          spreadRadius: 1 + t * 3,
                        ),
                      ],
                    ),
                  ),
                ),
                child!,
                // 빛나는 테두리 (타일 위)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.radius),
                        border: Border.all(color: _glow, width: 3 + t * 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
