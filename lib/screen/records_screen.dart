import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

import '../app_color.dart';
import '../feedback_service.dart';
import '../records_store.dart';
import '../widgets/game_ui_3d.dart';
import 'number15_screen.dart';
import 'number24_screen.dart';
import 'number8_screen.dart';

/// 기록 화면에 보여줄 난이도 정보
class _Difficulty {
  const _Difficulty({
    required this.puzzleType,
    required this.titleKey,
    required this.color,
    required this.tileColor,
    required this.textColor,
  });

  final String puzzleType;
  final String titleKey;
  final Color color;
  final Color tileColor;
  final Color textColor;
}

const _difficulties = [
  _Difficulty(
    puzzleType: Number8Screen.puzzleType,
    titleKey: 'home_puzzle_3',
    color: AppColor.puzzle8MenuBackground,
    tileColor: AppColor.puzzle8Tile,
    textColor: AppColor.puzzle8Text,
  ),
  _Difficulty(
    puzzleType: Number15Screen.puzzleType,
    titleKey: 'home_puzzle_4',
    color: AppColor.puzzle15MenuBackground,
    tileColor: AppColor.puzzle15Tile,
    textColor: AppColor.puzzle15Text,
  ),
  _Difficulty(
    puzzleType: Number24Screen.puzzleType,
    titleKey: 'home_puzzle_5',
    color: AppColor.puzzle24MenuBackground,
    tileColor: AppColor.puzzle24Tile,
    textColor: AppColor.puzzle24Text,
  ),
];

/// 기록 화면에서 쓰는 금색 (트로피)
const recordsColor = Color(0xFFE2A93B);

String _formatTime(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

String _formatDate(DateTime d) =>
    '${d.year}.${d.month.toString().padLeft(2, '0')}.'
    '${d.day.toString().padLeft(2, '0')}';

/// 난이도별 최고 기록을 보여주는 화면.
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key, this.initialIndex = 0});

  /// 처음 선택할 난이도 (0: 3x3, 1: 4x4, 2: 5x5)
  final int initialIndex;

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  late int _selected = widget.initialIndex.clamp(0, _difficulties.length - 1);
  final Map<String, PuzzleRecords> _records = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = <String, PuzzleRecords>{};
    for (final d in _difficulties) {
      loaded[d.puzzleType] = await RecordsStore.load(d.puzzleType);
    }
    if (!mounted) return;
    setState(() => _records.addAll(loaded));
  }

  @override
  Widget build(BuildContext context) {
    final difficulty = _difficulties[_selected];
    final records = _records[difficulty.puzzleType];

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColor.puzzle8Background,
        body: Column(
          children: [
            GameHeader3D(title: 'records_title'.tr(), color: recordsColor),
            const SizedBox(height: 16),

            // 난이도 탭
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (var i = 0; i < _difficulties.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: _DifficultyTab(
                        label: _difficulties[i].titleKey.tr(),
                        color: _difficulties[i].color,
                        selected: i == _selected,
                        onTap: () {
                          if (i == _selected) return;
                          FeedbackService.instance.tap();
                          setState(() => _selected = i);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 선택한 난이도의 기록
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _RecordsCard(
                        key: ValueKey(difficulty.puzzleType),
                        difficulty: difficulty,
                        records: records,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            GameMenuBar3D(
              color: recordsColor,
              children: [
                Button3D(
                  icon: Icons.arrow_back,
                  tooltip: 'menu_back'.tr(),
                  color: shadeColor(recordsColor, 0.12),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 난이도 탭: 선택되면 눌려 들어간 모양.
class _DifficultyTab extends StatelessWidget {
  const _DifficultyTab({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tabColor = selected ? color : shadeColor(color, 0.55);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Raised3D(
            color: tabColor,
            radius: 16,
            depth: 6,
            pressed: selected,
            expand: true,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'HiMelody',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : shadeColor(color, -0.3),
                      shadows:
                          selected
                              ? [
                                Shadow(
                                  color: shadeColor(color, -0.5),
                                  offset: const Offset(0, 1.5),
                                  blurRadius: 1.5,
                                ),
                              ]
                              : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 한 난이도의 기록 카드: 최소 이동 / 최단 시간 / 완성 횟수 / TOP 5
class _RecordsCard extends StatelessWidget {
  const _RecordsCard({
    super.key,
    required this.difficulty,
    required this.records,
  });

  final _Difficulty difficulty;
  final PuzzleRecords? records;

  @override
  Widget build(BuildContext context) {
    final color = difficulty.color;
    final textColor = shadeColor(color, -0.35);
    final records = this.records;

    TextStyle style(double size, {Color? c, FontWeight? w}) => TextStyle(
      fontFamily: 'HiMelody',
      fontSize: size,
      fontWeight: w ?? FontWeight.bold,
      color: c ?? textColor,
    );

    Widget bestBox(IconData icon, String label, String value) => Expanded(
      child: Inset3D(
        color: shadeColor(color, 0.72),
        radius: 18,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 26, color: textColor),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: style(18, w: FontWeight.normal)),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: style(34)),
              ),
            ],
          ),
        ),
      ),
    );

    return Raised3D(
      color: shadeColor(color, 0.85),
      radius: 26,
      depth: 8,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child:
            records == null
                ? const SizedBox(height: 200)
                : records.isEmpty
                ? _EmptyRecords(textColor: textColor)
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        bestBox(
                          Icons.swap_horiz,
                          'records_best_moves'.tr(),
                          records.bestMoves?.toString() ?? '-',
                        ),
                        const SizedBox(width: 12),
                        bestBox(
                          Icons.timer,
                          'records_best_time'.tr(),
                          records.bestTime == null
                              ? '-'
                              : _formatTime(records.bestTime!),
                        ),
                      ],
                    ),
                    if (records.clears > 0) ...[
                      const SizedBox(height: 10),
                      Text(
                        'records_clears'.tr(
                          namedArgs: {'count': records.clears.toString()},
                        ),
                        textAlign: TextAlign.center,
                        style: style(20, w: FontWeight.normal),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.emoji_events, color: recordsColor, size: 26),
                        const SizedBox(width: 6),
                        Text('records_top'.tr(), style: style(24)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (records.top.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'records_top_empty'.tr(),
                          textAlign: TextAlign.center,
                          style: style(18, w: FontWeight.normal),
                        ),
                      )
                    else
                      for (var i = 0; i < records.top.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _TopRow(
                            rank: i + 1,
                            entry: records.top[i],
                            color: color,
                            textColor: textColor,
                          ),
                        ),
                  ],
                ),
      ),
    );
  }
}

/// TOP 기록 한 줄: 순위 메달, 시간, 이동 횟수, 날짜
class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.rank,
    required this.entry,
    required this.color,
    required this.textColor,
  });

  final int rank;
  final RecordEntry entry;
  final Color color;
  final Color textColor;

  static const _medals = [
    Color(0xFFE2A93B), // 금
    Color(0xFFA8B0B8), // 은
    Color(0xFFC58A5A), // 동
  ];

  @override
  Widget build(BuildContext context) {
    final medal = rank <= 3 ? _medals[rank - 1] : shadeColor(color, 0.35);
    TextStyle style(double size, {FontWeight w = FontWeight.bold}) => TextStyle(
      fontFamily: 'HiMelody',
      fontSize: size,
      fontWeight: w,
      color: textColor,
    );

    return Inset3D(
      color: shadeColor(color, 0.72),
      radius: 14,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: Raised3D(
                color: medal,
                radius: 18,
                depth: 3,
                expand: true,
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontFamily: 'HiMelody',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: shadeColor(medal, -0.5),
                          offset: const Offset(0, 1),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 좁은 화면에서는 시간·이동 부분을 축소
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(Icons.timer, size: 20, color: textColor),
                    const SizedBox(width: 4),
                    Text(_formatTime(entry.seconds), style: style(24)),
                    const SizedBox(width: 12),
                    Icon(Icons.swap_horiz, size: 20, color: textColor),
                    const SizedBox(width: 4),
                    Text('${entry.moves}', style: style(24)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDate(entry.date),
              style: style(16, w: FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords({required this.textColor});

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: textColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 10),
          Text(
            'records_empty'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'HiMelody',
              fontSize: 22,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
