import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../atlas/continent.dart';
import '../learning/session_repository.dart';
import '../learning/streaks.dart';
import '../learning/token_icon.dart';
import '../settings/app_preferences.dart';

/// Today (look v2, GeoKuna_Concept_Assets_Pack): continent chips, the region
/// banner with the day's call to start, map progress, the streak and three
/// illustrated training tiles. Atlas and "Moja nauka" live in the
/// bottom navigation bar.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continent = ref.watch(selectedContinentProvider);
    final daily = ref.watch(dailyOverviewProvider);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: const _Wordmark(),
        actions: [
          IconButton(
            tooltip: 'Ustawienia',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.maxWidth >= 600 ? 32.0 : 20.0;
            final padded = EdgeInsets.symmetric(horizontal: side);
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                // Training tiles stay pinned above the bottom bar; the rest
                // scrolls.
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(top: 0, bottom: 8),
                        children: [
                          Padding(
                            padding: padded,
                            child: _ContinentPicker(continent: continent),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: padded,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _StreakRescueCard(continent: continent),
                                daily.when(
                                  loading: () => const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  error: (_, _) => _LoadFailed(ref: ref),
                                  data: (overview) => _Expedition(
                                    continent: continent,
                                    overview: overview,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _LevelRow(
                                  continent: continent,
                                  activeSession:
                                      daily.asData?.value.activeSession != null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(side, 6, side, 6),
                      // Low screens (landscape) keep the tiles small.
                      child: _TrainingRow(
                        maxTile: constraints.maxHeight < 520 ? 72 : 150,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The v2 logo: globe, name and the green swoosh in one picture.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    label: 'GeoKuna',
    excludeSemantics: true,
    child: Image.asset(
      'assets/v2/logo_wordmark.webp',
      height: 32,
      cacheHeight: 96,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
    ),
  );
}

Future<void> _openAndRefresh(
  BuildContext context,
  WidgetRef ref,
  String path,
) async {
  await context.push(path);
  if (context.mounted) {
    ref.invalidate(dailyOverviewProvider);
    ref.invalidate(achievementsProvider);
    ref.invalidate(continentAchievementsProvider);
  }
}

/// One scrollable row of chips (one row at any width and text size) and a
/// hint that more areas are hidden to the side.
class _ContinentPicker extends ConsumerStatefulWidget {
  const _ContinentPicker({required this.continent});
  final Continent continent;

  @override
  ConsumerState<_ContinentPicker> createState() => _ContinentPickerState();
}

class _ContinentPickerState extends ConsumerState<_ContinentPicker> {
  final _chips = {for (final c in Continent.values) c: GlobalKey()};

  @override
  void didUpdateWidget(_ContinentPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.continent == widget.continent) return;
    // After a swipe on the banner the chosen chip may be off-screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chip = _chips[widget.continent]!.currentContext;
      if (chip != null && chip.mounted) {
        Scrollable.ensureVisible(
          chip,
          alignment: .5,
          duration: const Duration(milliseconds: 250),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final continent = widget.continent;
    final hint = Theme.of(context).textTheme.labelSmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: 'Wybierz kontynent',
          container: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                for (final option in Continent.values) ...[
                  ChoiceChip(
                    key: _chips[option],
                    label: Text(option.label),
                    selected: continent == option,
                    showCheckmark: false,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    onSelected: (_) => ref
                        .read(selectedContinentProvider.notifier)
                        .select(option),
                  ),
                  if (option != Continent.values.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
        ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.west, size: 13, color: hint?.color),
              const SizedBox(width: 6),
              Icon(Icons.swipe, size: 14, color: hint?.color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Przesuń, aby zobaczyć więcej kontynentów',
                  style: hint,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.east, size: 13, color: hint?.color),
            ],
          ),
        ),
      ],
    );
  }
}

/// Light green panel shared by the expedition card and its load states.
class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Card.filled(
    margin: EdgeInsets.zero,
    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.ref});
  final WidgetRef ref;

  void _retry() {
    if (ref.read(catalogProvider).hasError) ref.invalidate(catalogProvider);
    if (ref.read(capitalsProvider).hasError) ref.invalidate(capitalsProvider);
    if (ref.read(flagsProvider).hasError) ref.invalidate(flagsProvider);
    try {
      ref.read(databaseProvider);
    } catch (_) {
      ref.invalidate(databaseProvider);
    }
    ref.invalidate(dailyOverviewProvider);
  }

  @override
  Widget build(BuildContext context) => _CardShell(
    child: Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nie udało się wczytać dzisiejszej wyprawy.'),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _retry, child: const Text('Ponów odczyt')),
        ],
      ),
    ),
  );
}

/// „Gotowy na wyprawę?”: the day's plan in one line and the main button.
class _Expedition extends ConsumerWidget {
  const _Expedition({required this.continent, required this.overview});
  final Continent continent;
  final MemoryOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final active = overview.activeSession;
    final canStart = overview.plannedCount > 0 || active != null;
    final extra =
        active == null && overview.plannedCount == 0 && overview.canStartExtra;
    final headline = active != null
        ? 'Wracasz na szlak?'
        : canStart
        ? 'Gotowy na wyprawę?'
        : 'Na dziś wszystko!';
    // First visit of an area: the main button is the easy placement quiz.
    final placement =
        overview.firstVisit && active == null && overview.newAvailable > 0;
    final subtitle = placement
        ? '${continent.label} · krótki quiz na start, poziom łatwy'
        // The plan is one sentence; under the headline it reads as a tag.
        : '${continent.label} · '
              // The headline already says „Na dziś wszystko!”.
              '${_planText(context, overview).replaceFirst('Na dziś wszystko. ', '').replaceFirst(RegExp(r'\.$'), '')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Banner(
          continent: continent,
          headline: headline,
          subtitle: subtitle,
          onSwipe: (area) =>
              ref.read(selectedContinentProvider.notifier).select(area),
          action: placement
              ? _StartButton(
                  label: 'Wstępny quiz',
                  onPressed: () =>
                      _openAndRefresh(context, ref, '/daily?mode=placement'),
                )
              : !(canStart || extra)
              ? null
              // The extra round is optional, so it never looks like the
              // day's main task.
              : extra
              ? FilledButton.tonalIcon(
                  // Cream on the picture: optional, but still readable.
                  style: FilledButton.styleFrom(
                    backgroundColor: GeoTheme.paper.withValues(alpha: .92),
                    minimumSize: const Size.fromHeight(48),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () =>
                      _openAndRefresh(context, ref, '/daily?mode=extra'),
                  icon: const Icon(Icons.replay),
                  label: const Text('Kolejna runda'),
                )
              : _StartButton(
                  label: active == null
                      ? 'Rozpocznij wyprawę'
                      : 'Wznów wyprawę',
                  onPressed: () => _openAndRefresh(context, ref, '/daily'),
                ),
        ),
        if (overview.otherDueCount > 0) ...[
          const SizedBox(height: 8),
          Text(
            'Na innych poziomach: ${overview.otherDueCount} '
            '${_plural(overview.otherDueCount, 'powtórka', 'powtórki', 'powtórek')}.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

/// Region banner (look v2): the headline and plan above a rounded region
/// picture. On the picture: the streak (top right), map progress and the
/// main button (bottom). The headline is real text on the page, so it stays
/// readable whatever the picture shows and grows with the font.
/// Swipe left: next area, right: the previous one (the chips do the same
/// for screen readers).
class _Banner extends StatelessWidget {
  const _Banner({
    required this.continent,
    required this.headline,
    required this.subtitle,
    required this.onSwipe,
    this.action,
  });
  final Continent continent;
  final String headline, subtitle;
  final ValueChanged<Continent> onSwipe;
  final Widget? action;

  static String art(Continent area) {
    // Two variants per region; the picture changes from day to day.
    final day = DateTime.now().difference(DateTime(2026)).inDays;
    return 'assets/v2/banner_${area.artId}_${day % 2 + 1}.webp';
  }

  void _swiped(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 200) return;
    final next = continent.index + (velocity < 0 ? 1 : -1);
    if (next < 0 || next >= Continent.values.length) return;
    onSwipe(Continent.values[next]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onHorizontalDragEnd: _swiped,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              headline,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: GeoTheme.ink,
              ),
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              // Decoded at the size it is shown, not at 1080 px: a third of
              // the memory on a typical phone. The neighbours are decoded
              // ahead, so a swipe shows the next picture at once.
              final decodeWidth =
                  (constraints.maxWidth *
                          MediaQuery.devicePixelRatioOf(context))
                      .round()
                      .clamp(1, 1080);
              ImageProvider provider(Continent area) =>
                  ResizeImage(AssetImage(art(area)), width: decodeWidth);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                for (final step in const [-1, 1]) {
                  final i = continent.index + step;
                  if (i >= 0 && i < Continent.values.length) {
                    precacheImage(provider(Continent.values[i]), context);
                  }
                }
              });
              return ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 1.45,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ExcludeSemantics(
                        child: Image(
                          image: provider(continent),
                          fit: BoxFit.cover,
                          // Keeps the kuna's face in the frame.
                          alignment: const Alignment(0, -.35),
                          gaplessPlayback: true,
                        ),
                      ),
                      const Positioned(
                        top: 10,
                        right: 10,
                        child: _StreakBadge(),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MapBadge(continent: continent),
                            if (action != null) ...[
                              const SizedBox(height: 8),
                              SizedBox(width: double.infinity, child: action),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Small cream pill on the banner picture.
class _Pill extends StatelessWidget {
  const _Pill({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: GeoTheme.paper.withValues(alpha: .9),
    shape: const StadiumBorder(),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: child,
      ),
    ),
  );
}

/// „Passa nauki” on the banner: the flame and the day count.
class _StreakBadge extends ConsumerWidget {
  const _StreakBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = GeoColors.of(context);
    final text = Theme.of(context).textTheme.labelLarge
        ?.copyWith(fontWeight: FontWeight.w800, color: GeoTheme.ink);
    final streak = ref.watch(streakProvider).asData?.value;
    final current = streak?.current ?? 0;
    final tokens = streak?.tokens ?? 0;
    final next = streak?.nextReward;
    final state = current == 0
        ? 'Zacznij dziś i zdobądź pierwsze dni!'
        : streak!.practisedToday
        ? 'Dzisiaj zaliczone.'
        : 'Odpowiedz dziś, aby jej nie stracić.';
    return Semantics(
      label:
          'Passa nauki: ${daysLabel(current)}. $state '
          'Rekord: ${daysLabel(streak?.best ?? 0)}.'
          '${tokens > 0 ? ' Żetony Nieprzykunowanie: $tokens.' : ''}'
          '${next == null ? '' : ' Nagroda za $next dni z rzędu: jeszcze ${daysLabel(streak!.daysToNextReward!)}.'}',
      excludeSemantics: true,
      child: _Pill(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department, size: 20, color: colors.streak),
            const SizedBox(width: 2),
            Text(daysLabel(current), style: text),
            if (tokens > 0) ...[
              const SizedBox(width: 8),
              const TokenIcon(size: 16),
              Text(' $tokens', style: text),
            ],
          ],
        ),
      ),
    );
  }
}

/// Map progress of the area at its current level, toward the next medal.
class _MapBadge extends ConsumerWidget {
  const _MapBadge({required this.continent});
  final Continent continent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level =
        ref
            .watch(appPreferencesProvider)
            .asData
            ?.value
            .difficultyFor(continent) ??
        LearningDifficulty.normal;
    final map = ref
        .watch(achievementsProvider)
        .asData
        ?.value
        .where((a) => a.topic == 'map' && a.level == level)
        .firstOrNull;
    if (map == null || map.totalCount == 0) return const SizedBox.shrink();
    final next = [(50, 'brązowego'), (80, 'srebrnego'), (100, 'złotego')]
        .where((t) => map.qualifiedCount * 100 < map.totalCount * t.$1)
        .firstOrNull;
    final missing = next == null
        ? 0
        : (map.totalCount * next.$1 + 99) ~/ 100 - map.qualifiedCount;
    final label =
        '${continent.label}: ${map.qualifiedCount}/${map.totalCount} '
        '${continent.areaNoun}';
    return Semantics(
      button: true,
      label:
          'Postęp mapy: $label. '
          '${next == null ? 'Złoty medal zdobyty.' : 'Do ${next.$2} medalu: jeszcze $missing.'}',
      excludeSemantics: true,
      child: _Pill(
        onTap: () => context.push('/learning/${continent.name}'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w800, color: GeoTheme.ink),
            ),
            const SizedBox(height: 3),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                value: map.qualifiedCount / map.totalCount,
                minHeight: 4,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The main call to action: a tall green pill with a white rim and a play
/// sign, like the v2 component sheet.
class _StartButton extends StatelessWidget {
  const _StartButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(54),
      shape: const StadiumBorder(
        side: BorderSide(color: Colors.white, width: 2.5),
      ),
      textStyle: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w700),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.play_arrow_rounded, size: 34),
        const SizedBox(width: 8),
        // Very large text shrinks the label instead of breaking a word.
        Flexible(
          child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
        ),
      ],
    ),
  );
}

/// Training tiles (v2.5 pack): the picture without text, the name as real
/// text on the tile's calm lower band, so it scales with the font size
/// (down to fit) and follows the area (Herby, maps of Poland and the USA).
class _TrainingRow extends ConsumerWidget {
  const _TrainingRow({required this.maxTile});
  final double maxTile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final area = ref.watch(selectedContinentProvider);
    final items = [
      (
        'Mapa',
        switch (area) {
          Continent.poland => 'mapa_polska',
          Continent.usa => 'mapa_usa',
          _ => 'mapa',
        },
        '/learn',
      ),
      // Short on the tile; the screen title says „Miasta wojewódzkie”.
      ('Stolice', 'stolice', '/capitals'),
      (
        area.symbolsLabel,
        switch (area) {
          Continent.poland => 'herby',
          Continent.europe => 'flagi_europa',
          Continent.usa => 'flagi_usa',
          _ => 'flagi_swiat',
        },
        '/flags',
      ),
    ];
    final label = Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.w800, color: GeoTheme.ink);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final (name, art, path) in items)
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxTile),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Semantics(
                  button: true,
                  label: 'Trening: $name',
                  excludeSemantics: true,
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      onTap: () => _openAndRefresh(context, ref, path),
                      // Square before the picture loads: no layout jump.
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              'assets/v2/tile_$art.webp',
                              cacheWidth: 432,
                            ),
                            // The lower band between the leaves is left
                            // free for the name.
                            FractionallySizedBox(
                              alignment: Alignment.bottomCenter,
                              heightFactor: .3,
                              widthFactor: .66,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(name, style: label),
                                ),
                              ),
                            ),
                          ],
                        ),
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

class _LevelRow extends ConsumerWidget {
  const _LevelRow({required this.continent, required this.activeSession});
  final Continent continent;
  final bool activeSession;

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    LearningDifficulty current,
  ) async {
    final chosen = await showModalBottomSheet<LearningDifficulty>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  'Poziom: ${continent.label}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final level in LearningDifficulty.values)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  title: Text(level.label),
                  subtitle: Text(level.description),
                  selected: level == current,
                  trailing: level == current ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.pop(context, level),
                ),
              if (activeSession)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Text(
                    'Rozpoczęta wyprawa zachowuje zapisany poziom; wybór '
                    'dotyczy następnej.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null || chosen == current) return;
    await ref
        .read(appPreferencesProvider.notifier)
        .setDifficulty(continent, chosen);
    ref.invalidate(dailyOverviewProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current =
        ref
            .watch(appPreferencesProvider)
            .asData
            ?.value
            .difficultyFor(continent) ??
        LearningDifficulty.normal;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      dense: true,
      leading: const Icon(Icons.tune),
      title: Text('Poziom dla ${continent.genitive}: ${current.label}'),
      subtitle: Text(current.description),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _choose(context, ref, current),
    );
  }
}

String _planText(BuildContext context, MemoryOverview overview) {
  final active = overview.activeSession;
  if (active != null) {
    final left =
        active.countryIds.length -
        active.index -
        (active.currentAttempt == null ? 0 : 1);
    final verb = _plural(left, 'Zostało', 'Zostały', 'Zostało');
    return '$verb $left ${_plural(left, 'pytanie', 'pytania', 'pytań')} '
        'w rozpoczętej serii.';
  }
  if (overview.plannedCount == 0) {
    final calm = _calmMessage(context, overview.nextDue);
    return overview.canStartExtra ? '$calm Możesz jeszcze poćwiczyć.' : calm;
  }
  final parts = [
    if (overview.plannedNewCount > 0)
      '${overview.plannedNewCount} '
          '${_plural(overview.plannedNewCount, 'nowe pytanie', 'nowe pytania', 'nowych pytań')}',
    if (overview.dueCount > 0)
      '${overview.dueCount} '
          '${_plural(overview.dueCount, 'powtórka', 'powtórki', 'powtórek')}',
  ];
  return '${parts.join(' i ')}.';
}

String _plural(int n, String one, String few, String many) {
  if (n == 1) return one;
  final tens = n % 100;
  if (n % 10 >= 2 && n % 10 <= 4 && (tens < 12 || tens > 14)) return few;
  return many;
}

/// One message for an empty plan: when the next review is due.
String _calmMessage(BuildContext context, DateTime? nextDue) {
  if (nextDue == null) {
    return 'Na dziś wszystko. Nowe pytania pojawią się jutro.';
  }
  final local = nextDue.toLocal();
  final now = DateTime.now();
  final time = MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: true);
  if (local.year == now.year &&
      local.month == now.month &&
      local.day == now.day) {
    return 'Na dziś wszystko. Kolejna powtórka o $time.';
  }
  final date = MaterialLocalizations.of(context).formatMediumDate(local);
  return 'Na dziś wszystko. Kolejna powtórka: $date o $time.';
}

/// The day after a missed day: the sad kuna offers a „Nieprzykunowanie”
/// token, so the streak survives. Hidden when nothing can be saved.
class _StreakRescueCard extends ConsumerStatefulWidget {
  const _StreakRescueCard({required this.continent});
  final Continent continent;

  @override
  ConsumerState<_StreakRescueCard> createState() => _StreakRescueCardState();
}

class _StreakRescueCardState extends ConsumerState<_StreakRescueCard> {
  bool _busy = false;

  Future<void> _decide(StreakRescue rescue, {required bool keep}) async {
    setState(() => _busy = true);
    try {
      await StreakStore(ref.read(databaseProvider))
          .decide(widget.continent, rescue, keep: keep);
      ref
        ..invalidate(streakProvider)
        ..invalidate(continentStreakProvider);
      if (mounted && keep) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Passa uratowana: ${daysLabel(rescue.streak)} i liczymy dalej!',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final streak = ref.watch(streakProvider).asData?.value;
    final rescue = streak?.rescue;
    if (streak == null || rescue == null) return const SizedBox.shrink();
    final missed = rescue.missedDays.length;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card.filled(
        color: GeoColors.of(context).speechBubble,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                // Wraps below the kuna when large text leaves no room.
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Image.asset(
                    'assets/v2/kuna_sad.webp',
                    width: 64,
                    height: 64,
                    cacheWidth: 192,
                    semanticLabel: 'Smutna kuna',
                  ),
                  Text(
                    missed == 1
                        ? 'Wczoraj Cię tu nie było!'
                        : 'Nie było Cię tu przez ${daysLabel(missed)}!',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Twoja passa (${daysLabel(rescue.streak)}) wisi na włosku. '
                'Żeton Nieprzykunowanie uratuje '
                '${missed == 1 ? 'opuszczony dzień' : 'każdy opuszczony dzień'}'
                '. Masz ${tokensLabel(streak.tokens)}.',
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy ? null : () => _decide(rescue, keep: true),
                icon: const TokenIcon(),
                label: Text(
                  missed == 1 ? 'Użyj żetonu' : 'Użyj żetonów: $missed',
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: _busy ? null : () => _decide(rescue, keep: false),
                child: const Text('Nie, zacznę passę od nowa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
