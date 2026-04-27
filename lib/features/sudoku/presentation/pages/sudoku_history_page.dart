import 'package:flutter/material.dart';

import '../../../../theme/theme_mode_picker_button.dart';
import '../../data/win_history_repository.dart';
import '../../domain/game_difficulty.dart';
import '../../domain/sudoku_win_record.dart';
import '../navigation/page_transitions.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/how_to_play.dart';

enum HistoryListFilter { all, win, lost }

/// Lists past games (wins and losses) with filters and staggered list animations.
class SudokuHistoryPage extends StatefulWidget {
  const SudokuHistoryPage({super.key});

  static Route<void> route() => slideFadeRoute<void>(const SudokuHistoryPage());

  @override
  State<SudokuHistoryPage> createState() => _SudokuHistoryPageState();
}

class _SudokuHistoryPageState extends State<SudokuHistoryPage> {
  List<SudokuWinRecord> _records = [];
  bool _loading = true;
  HistoryListFilter _filter = HistoryListFilter.all;

  static const _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  List<SudokuWinRecord> get _visibleRecords {
    switch (_filter) {
      case HistoryListFilter.all:
        return _records;
      case HistoryListFilter.win:
        return _records.where((e) => e.isWin).toList();
      case HistoryListFilter.lost:
        return _records.where((e) => e.isLost).toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = await WinHistoryRepository.instance();
    if (!mounted) return;
    setState(() {
      _records = repo.readAllSync();
      _loading = false;
    });
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text(
          'This removes every saved game (wins and losses) from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final repo = await WinHistoryRepository.instance();
    await repo.clearAll();
    if (!mounted) return;
    await _load();
  }

  Future<void> _confirmDeleteRecord(SudokuWinRecord r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove this entry?'),
        content: Text(
          r.isWin
              ? 'This win will be removed from history on this device.'
              : 'This loss will be removed from history on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final repo = await WinHistoryRepository.instance();
    await repo.deleteById(r.id);
    if (!mounted) return;
    await _load();
  }

  String _formatWhen(DateTime dt) {
    final d = dt.toLocal();
    final mon = _monthAbbr[d.month - 1];
    final day = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$day $mon ${d.year}   ·   $h:$min';
  }

  Widget _buildEmptyAll() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.14),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) {
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 16 * (1 - t)),
                child: child,
              ),
            );
          },
          child: Column(
            children: [
              Icon(
                Icons.history_rounded,
                size: 64,
                color: colorScheme.primary.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 20),
              Text(
                'No games yet',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Wins and losses are saved here so you can review difficulty, '
                'time, and stats.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyFilter(HistoryListFilter f) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = f == HistoryListFilter.win ? 'No wins yet' : 'No losses yet';
    final body = f == HistoryListFilter.win
        ? 'Play and finish a puzzle to see wins here. Try another filter.'
        : 'Games that end after too many mistakes appear here. Try another filter.';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
        Icon(
          f == HistoryListFilter.win
              ? Icons.emoji_events_outlined
              : Icons.sentiment_dissatisfied_outlined,
          size: 56,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final visible = _visibleRecords;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'History',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'How to play',
            onPressed: () => showHowToPlay(context),
            icon: const Icon(Icons.help_outline_rounded),
          ),
          const ThemeModePickerButton(),
          if (_records.isNotEmpty)
            IconButton(
              tooltip: 'Clear all',
              onPressed: _confirmClear,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedButton<HistoryListFilter>(
              segments: const [
                ButtonSegment(
                  value: HistoryListFilter.all,
                  label: Text('All'),
                  icon: Icon(Icons.list_alt_rounded, size: 18),
                ),
                ButtonSegment(
                  value: HistoryListFilter.win,
                  label: Text('Win'),
                  icon: Icon(Icons.emoji_events_outlined, size: 18),
                ),
                ButtonSegment(
                  value: HistoryListFilter.lost,
                  label: Text('Lost'),
                  icon: Icon(Icons.close_rounded, size: 18),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (s) {
                setState(() => _filter = s.first);
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              edgeOffset: 8,
              color: colorScheme.primary,
              child: _loading
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(child: CircularProgressIndicator()),
                      ],
                    )
                  : _records.isEmpty
                      ? _buildEmptyAll()
                      : visible.isEmpty
                          ? _buildEmptyFilter(_filter)
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                              itemCount: visible.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final r = visible[index];
                                return FadeSlideIn(
                                  index: index,
                                  child: _HistoryCard(
                                    record: r,
                                    whenLabel: _formatWhen(r.completedAt),
                                    onDelete: () => _confirmDeleteRecord(r),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.record,
    required this.whenLabel,
    required this.onDelete,
  });

  final SudokuWinRecord record;
  final String whenLabel;
  final VoidCallback onDelete;

  static ({Color bg, Color fg, Color stripe}) _tierStyle(
    GameDifficulty d,
    ColorScheme cs,
  ) {
    return switch (d) {
      GameDifficulty.easy => (
          bg: cs.tertiaryContainer.withValues(alpha: 0.55),
          fg: cs.onTertiaryContainer,
          stripe: cs.tertiary,
        ),
      GameDifficulty.medium => (
          bg: cs.secondaryContainer.withValues(alpha: 0.55),
          fg: cs.onSecondaryContainer,
          stripe: cs.secondary,
        ),
      GameDifficulty.expert => (
          bg: cs.primaryContainer.withValues(alpha: 0.65),
          fg: cs.onPrimaryContainer,
          stripe: cs.primary,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tier = _tierStyle(record.difficulty, colorScheme);
    final stripeColor =
        record.isLost ? colorScheme.error : tier.stripe;

    return Material(
      color: colorScheme.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: colorScheme.surfaceTint.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: stripeColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(19),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 4, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: record.isLost
                              ? colorScheme.errorContainer
                                  .withValues(alpha: 0.55)
                              : colorScheme.primaryContainer
                                  .withValues(alpha: 0.45),
                          child: Icon(
                            record.isWin
                                ? Icons.task_alt_rounded
                                : Icons.highlight_off_rounded,
                            size: 26,
                            color: record.isLost
                                ? colorScheme.error
                                : colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.isWin ? 'Win' : 'Lost',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                  height: 1.1,
                                  color: record.isLost
                                      ? colorScheme.error
                                      : colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 3,
                                    height: 15,
                                    decoration: BoxDecoration(
                                      color: tier.stripe,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          height: 1.25,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: record.difficulty.title,
                                            style: TextStyle(
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.85),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const TextSpan(text: ' · '),
                                          TextSpan(
                                            text: '9×9 puzzle',
                                            style: TextStyle(
                                              color: colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove from history',
                          onPressed: onDelete,
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TIME',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  letterSpacing: 1.1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                record.durationLabel,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            whenLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Divider(
                        height: 1,
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            icon: Icons.gpp_maybe_outlined,
                            label: 'Mistakes',
                            value: '${record.mistakes}',
                            colorScheme: colorScheme,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatTile(
                            icon: Icons.auto_fix_high_rounded,
                            label: 'Hints',
                            value: '${record.hintsUsed}',
                            colorScheme: colorScheme,
                            theme: theme,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: colorScheme.primary.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
