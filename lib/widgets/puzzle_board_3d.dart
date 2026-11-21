import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:material_ui/material_ui.dart';

import '../puzzle_moves.dart';
import 'game_ui_3d.dart';

/// 타일이 칸 사이를 미끄러지는 시간과 곡선
const _slideDuration = Duration(milliseconds: 160);
const _slideCurve = Curves.easeOutCubic;

/// 입체적으로 보이는 슬라이딩 퍼즐 보드.
///
/// [tiles]는 칸 순서대로의 숫자 목록이며 0은 빈칸이다.
/// 타일은 숫자별로 위치가 애니메이션되어 이동할 때 미끄러지듯 움직인다.
///
/// 빈칸과 같은 줄의 타일은 탭하거나 빈칸 쪽으로 끌어서 옮길 수 있고,
/// 그 사이의 타일들도 함께 밀린다.
class PuzzleBoard3D extends StatefulWidget {
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

  /// 타일을 탭하거나 끌어서 옮겼을 때 그 타일의 칸 번호(index)를 전달한다.
  final ValueChanged<int> onTileTap;

  /// 힌트로 강조할 타일의 칸 번호 (없으면 null)
  final int? hintIndex;

  @override
  State<PuzzleBoard3D> createState() => _PuzzleBoard3DState();
}

class _PuzzleBoard3DState extends State<PuzzleBoard3D>
    with SingleTickerProviderStateMixin {
  // 드래그 중인 줄: 함께 움직이는 타일들(숫자), 빈칸 쪽 방향, 끌어온 거리
  Set<int> _group = const {};
  Offset _direction = Offset.zero;
  double _offset = 0;
  double _travel = 0;
  int? _dragIndex;

  // 손을 뗀 뒤 0으로 돌아가는 애니메이션 (칸 이동과 같은 곡선이라 끊김 없이 이어짐)
  double _settleFrom = 0;
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: _slideDuration,
  )..addListener(() {
    setState(() {
      _offset = _settleFrom * (1 - _slideCurve.transform(_settle.value));
      if (_settle.isCompleted) _group = const {};
    });
  });

  int get _empty => widget.tiles.indexOf(0);

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _onDragStart(int index, double travel) {
    final steps = slideSteps(index, _empty, widget.gridSize);
    if (steps.isEmpty) return;
    _settle.stop();
    final step = steps.first - _empty; // 빈칸에서 이 타일 쪽 한 칸
    final n = widget.gridSize;
    setState(() {
      _dragIndex = index;
      _travel = travel;
      _group = {for (final i in steps) widget.tiles[i]};
      // 타일은 빈칸 쪽(step의 반대 방향)으로 움직임
      _direction =
          step.abs() == 1
              ? Offset(-step.sign.toDouble(), 0)
              : Offset(0, -(step ~/ n).sign.toDouble());
      _offset = 0;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_dragIndex == null) return;
    final along =
        details.delta.dx * _direction.dx + details.delta.dy * _direction.dy;
    setState(() => _offset = (_offset + along).clamp(0.0, _travel));
  }

  void _onDragEnd(DragEndDetails details) {
    final index = _dragIndex;
    if (index == null) return;
    final v = details.velocity.pixelsPerSecond;
    final speed = v.dx * _direction.dx + v.dy * _direction.dy;
    // 한 칸의 30% 이상 끌었거나 빈칸 쪽으로 빠르게 밀면 이동
    final commit = _offset > 0 && (_offset > _travel * 0.3 || speed > 350);
    _release();
    if (commit) widget.onTileTap(index);
  }

  void _release() {
    _dragIndex = null;
    _settleFrom = _offset;
    _settle.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final gridSize = widget.gridSize;
    final tiles = widget.tiles;
    final tileColor = widget.tileColor;
    final textColor = widget.textColor;
    final emptyColor = widget.emptyColor;
    final frameColor = widget.frameColor;
    final enabled = widget.enabled;
    final hintIndex = widget.hintIndex;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;
        final frame = size * 0.035; // 바깥 틀 두께
        final inner = size - frame * 2;
        final pad = inner * 0.025; // 홈 안쪽 여백
        final gap = inner * 0.022; // 타일 간격
        final cell = (inner - pad * 2 - gap * (gridSize - 1)) / gridSize;
        final radius = cell * 0.16;
        final empty = tiles.indexOf(0);

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
                      duration: _slideDuration,
                      curve: _slideCurve,
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
                                  ((empty % gridSize) - (index % gridSize))
                                      .toDouble(),
                                  ((empty ~/ gridSize) - (index ~/ gridSize))
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
                          onTap: () => widget.onTileTap(index),
                          // 끌고 있는 줄에 속한 타일은 함께 움직임
                          dragOffset:
                              _group.contains(value)
                                  ? _direction * _offset
                                  : Offset.zero,
                          // 빈칸과 같은 줄의 타일만 끌 수 있음
                          canDrag:
                              enabled &&
                              slideSteps(index, empty, gridSize).isNotEmpty,
                          onDragStart: () => _onDragStart(index, cell + gap),
                          onDragUpdate: _onDragUpdate,
                          onDragEnd: _onDragEnd,
                          onDragCancel: () {
                            if (_dragIndex != null) _release();
                          },
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
    required this.dragOffset,
    required this.canDrag,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  final int value;
  final Color color;
  final Color textColor;
  final double radius;
  final bool enabled;
  final VoidCallback onTap;

  /// 드래그로 끌려 온 만큼의 이동량
  final Offset dragOffset;
  final bool canDrag;
  final VoidCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final VoidCallback onDragCancel;

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

        final tile = Raised3D(
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
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.enabled ? (_) => _setPressed(true) : null,
          onTapUp: widget.enabled ? (_) => _setPressed(false) : null,
          onTapCancel: () => _setPressed(false),
          onTap: widget.enabled ? widget.onTap : null,
          // 처음 닿은 지점부터 손가락을 정확히 따라오도록
          dragStartBehavior: DragStartBehavior.down,
          onPanStart:
              widget.canDrag
                  ? (_) {
                    _setPressed(false);
                    widget.onDragStart();
                  }
                  : null,
          onPanUpdate: widget.canDrag ? widget.onDragUpdate : null,
          onPanEnd: widget.canDrag ? widget.onDragEnd : null,
          onPanCancel: widget.canDrag ? widget.onDragCancel : null,
          child:
              widget.dragOffset == Offset.zero
                  ? tile
                  : Transform.translate(offset: widget.dragOffset, child: tile),
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
