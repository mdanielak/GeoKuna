import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../atlas/continent.dart';
import '../atlas/continent_chips.dart';
import '../learning/session_repository.dart';
import '../learning/streaks.dart';
import '../learning/token_icon.dart';
import '../settings/app_preferences.dart';
import '../settings/difficulty_sheet.dart';

/// Today (look v2): continent chips, a full-height portrait region banner with
/// the day's call to start, map progress and streak, the region's difficulty
/// row and three illustrated training tiles anchored above the bottom bar.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continent = ref.watch(selectedContinentProvider);
    final daily = ref.watch(dailyOverviewProvider);
    final overview = daily.asData?.value;
    final hasPlacementSkip =
        overview != null &&
        overview.firstVisit &&
        overview.activeSession == null &&
        overview.newAvailable > 0 &&
        overview.plannedCount > 0;
    final hasOtherDue = overview != null && overview.otherDueCount > 0;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 46,
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
            final side = constraints.maxWidth >= 600 ? 32.0 : 18.0;
            final maxContentWidth = math.min(constraints.maxWidth, 720.0);
            final innerWidth = (maxContentWidth - 2 * side).clamp(180.0, 680.0);
            final textScale = MediaQuery.textScalerOf(context).scale(1.0);
            final landscape = constraints.maxHeight < 520;
            final maxTile = landscape ? 72.0 : 146.0;
            final tileHeight = ((innerWidth - 18) / 3).clamp(60.0, maxTile);

            // Size the 1080×1350 (4:5) portrait banner to stretch top-to-bottom
            // across the available viewport while remaining scrollable on small
            // screens or at 200% text scale.
            final chipsHeight = 46.0 * textScale.clamp(1.0, 1.3);
            final titleHeight = 64.0 * textScale;
            final levelHeight = 52.0 * textScale.clamp(1.0, 1.35);
            final extrasHeight =
                (hasPlacementSkip ? 36.0 * textScale.clamp(1.0, 1.3) : 0.0) +
                (hasOtherDue ? 24.0 * textScale.clamp(1.0, 1.3) : 0.0);
            final chrome =
                chipsHeight +
                titleHeight +
                levelHeight +
                tileHeight +
                extrasHeight +
                28.0;
            final minBanner = landscape
                ? 185.0
                : (innerWidth * 0.88 + math.max(0.0, textScale - 1.0) * 52.0)
                      .clamp(245.0, 360.0);
            final maxBanner = innerWidth * 1.32;
            final bannerHeight = (constraints.maxHeight - chrome).clamp(
              minBanner,
              maxBanner,
            );

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(side, 2, side, 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ContinentChips(continent: continent),
                              const SizedBox(height: 8),
                              _StreakRescueCard(continent: continent),
                              daily.when(
                                loading: () => const _CardShell(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 32),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                ),
                                error: (_, _) => _LoadFailed(ref: ref),
                                data: (data) => _Expedition(
                                  continent: continent,
                                  overview: data,
                                  bannerHeight: bannerHeight,
                                  bannerWidth: innerWidth,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 4),
                              _LevelRow(
                                continent: continent,
                                activeSession: overview?.activeSession != null,
                              ),
                              const SizedBox(height: 2),
                              _TrainingRow(maxTile: maxTile),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
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

/// Light green panel shared by load and error states of Today's expedition.
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
  const _Expedition({
    required this.continent,
    required this.overview,
    required this.bannerHeight,
    required this.bannerWidth,
  });
  final Continent continent;
  final MemoryOverview overview;
  final double bannerHeight;
  final double bannerWidth;

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
        : '${continent.label} · '
              '${_planText(context, overview).replaceFirst('Na dziś wszystko. ', '').replaceFirst(RegExp(r'\.$'), '')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Banner(
          continent: continent,
          headline: headline,
          subtitle: subtitle,
          height: bannerHeight,
          width: bannerWidth,
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
              : extra
              ? FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: GeoTheme.paper.withValues(alpha: .94),
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
        if (placement && overview.plannedCount > 0)
          Align(
            child: TextButton(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
              onPressed: () => _openAndRefresh(context, ref, '/daily'),
              child: const Text(
                'Zacznij zwykłą wyprawę',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        if (overview.otherDueCount > 0) ...[
          const SizedBox(height: 6),
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

/// Region banner (look v2): the headline and plan above the tall portrait
/// region picture (1080×1350). On the picture: the streak (top right), map
/// progress and the main button (bottom over a subtle dark scrim).
class _Banner extends StatelessWidget {
  const _Banner({
    required this.continent,
    required this.headline,
    required this.subtitle,
    required this.height,
    required this.width,
    required this.onSwipe,
    this.action,
  });
  final Continent continent;
  final String headline, subtitle;
  final double height, width;
  final ValueChanged<Continent> onSwipe;
  final Widget? action;

  static String art(Continent area) {
    final day = DateTime.now().difference(DateTime(2026)).inDays;
    return 'assets/v2/banner_${area.artId}_${day % 2 + 1}.webp';
  }

  /// [step]: +1 for a swipe to the left (next area), -1 to the right.
  void _swiped(int step) {
    final next = continent.index + step;
    if (next < 0 || next >= Continent.values.length) return;
    onSwipe(Continent.values[next]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decodeWidth = (width * MediaQuery.devicePixelRatioOf(context))
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
    // Tall portrait frames show the full illustration from sky to meadow;
    // compact frames keep the kuna's face clear of the bottom CTA.
    final alignment = Alignment(0, width / height > 1.05 ? -.32 : -.14);

    return _HorizontalSwipe(
      onSwipe: _swiped,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: SizedBox(
              height: height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ExcludeSemantics(
                    child: Image(
                      image: provider(continent),
                      fit: BoxFit.cover,
                      alignment: alignment,
                      gaplessPlayback: true,
                    ),
                  ),
                  const IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [.58, 1],
                          colors: [Colors.transparent, GeoTheme.bannerScrim],
                        ),
                      ),
                    ),
                  ),
                  const Positioned(top: 12, right: 12, child: _StreakBadge()),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MapBadge(continent: continent),
                        if (action != null) ...[
                          const SizedBox(height: 10),
                          SizedBox(width: double.infinity, child: action),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
    color: GeoTheme.paper.withValues(alpha: .92),
    shape: const StadiumBorder(),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
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
        '${continent.areaNoun} zaliczonych';
    return Semantics(
      button: true,
      label:
          'Medale mapy: $label. '
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

/// Detects a left/right swipe by speed or by distance, so a slow swipe that
/// pauses before the finger lifts (common on phones) still counts.
class _HorizontalSwipe extends StatefulWidget {
  const _HorizontalSwipe({required this.onSwipe, required this.child});
  final ValueChanged<int> onSwipe;
  final Widget child;

  @override
  State<_HorizontalSwipe> createState() => _HorizontalSwipeState();
}

class _HorizontalSwipeState extends State<_HorizontalSwipe> {
  static const _minDistance = 60.0, _minVelocity = 200.0;
  double _dx = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onHorizontalDragStart: (_) => _dx = 0,
    onHorizontalDragUpdate: (details) => _dx += details.delta.dx,
    onHorizontalDragEnd: (details) {
      final velocity = details.primaryVelocity ?? 0;
      final towards = velocity.abs() >= _minVelocity
          ? velocity
          : _dx.abs() >= _minDistance
          ? _dx
          : 0.0;
      if (towards != 0) widget.onSwipe(towards < 0 ? 1 : -1);
    },
    child: widget.child,
  );
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
        Flexible(
          child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
        ),
      ],
    ),
  );
}

/// Training tiles (v2.5 pack): the picture without text, the name as real
/// text on the tile's calm lower band.
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
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              'assets/v2/tile_$art.webp',
                              cacheWidth: 432,
                            ),
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
      visualDensity: VisualDensity.compact,
      dense: true,
      leading: const Icon(Icons.tune, size: 20),
      title: Text(
        'Poziom dla ${continent.genitive}: ${current.label}',
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        current.description.replaceAll('państwo', continent.areaAccusative),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () => showDifficultySheet(
        context,
        ref,
        continent: continent,
        current: current,
        activeSession: activeSession,
      ),
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
    return _calmMessage(context, overview.nextDue);
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Card.filled(
        color: GeoColors.of(context).speechBubble,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
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
