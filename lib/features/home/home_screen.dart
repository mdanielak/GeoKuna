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

/// Today (layout of assets_mockups reference_europa): continent chips, the
/// region illustration, the call to start, map progress, the streak and
/// three illustrated training tiles. Atlas and "Moja nauka" live in the
/// bottom navigation bar.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continent = ref.watch(selectedContinentProvider);
    final daily = ref.watch(dailyOverviewProvider);
    final compact =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(14) > 18;
    return Scaffold(
      appBar: AppBar(
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
                child: ListView(
                  padding: const EdgeInsets.only(top: 4, bottom: 24),
                  children: [
                    Padding(
                      padding: padded,
                      child: _ContinentPicker(continent: continent),
                    ),
                    const SizedBox(height: 8),
                    _Hero(continent: continent),
                    Padding(
                      padding: padded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _StreakRescueCard(continent: continent),
                          daily.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (_, _) => _LoadFailed(ref: ref),
                            data: (overview) => _Expedition(
                              continent: continent,
                              overview: overview,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _MapProgress(continent: continent),
                          const SizedBox(height: 12),
                          const _StreakCard(),
                          const SizedBox(height: 16),
                          _TrainingRow(compact: compact),
                          const SizedBox(height: 8),
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
            );
          },
        ),
      ),
    );
  }
}

/// Full-width illustration of the region; its lower edge is a soft wave
/// that fades into the page. Purely decorative.
class _Hero extends StatelessWidget {
  const _Hero({required this.continent});
  final Continent continent;

  @override
  Widget build(BuildContext context) {
    final page = Theme.of(context).scaffoldBackgroundColor;
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 941 / 404,
        child: ClipPath(
          clipper: const _WaveClipper(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/home/hero_${continent.artId}.webp',
                fit: BoxFit.cover,
                cacheWidth: 1200,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [.72, 1],
                    colors: [page.withValues(alpha: 0), page],
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

class _WaveClipper extends CustomClipper<Path> {
  const _WaveClipper();
  @override
  Path getClip(Size size) {
    final h = size.height, w = size.width;
    return Path()
      ..lineTo(w, 0)
      ..lineTo(w, h * .9)
      ..quadraticBezierTo(w * .75, h * .8, w * .5, h * .92)
      ..quadraticBezierTo(w * .25, h * 1.04, 0, h * .9)
      ..close();
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) => false;
}

/// App name with the same kuna as the launcher icon: one image, one name.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      header: true,
      label: 'GeoKuna',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: GeoColors.of(context).brandMint,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Image.asset(
                'assets/mascot/kuna-globe.png',
                width: 34,
                height: 34,
                cacheWidth: 102,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // A logo may shrink on narrow screens with very large text.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'GeoKuna',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
class _ContinentPicker extends ConsumerWidget {
  const _ContinentPicker({required this.continent});
  final Continent continent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hint = Theme.of(context).textTheme.bodySmall;
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
              Icon(Icons.west, size: 16, color: hint?.color),
              const SizedBox(width: 6),
              Icon(Icons.swipe, size: 18, color: hint?.color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Przesuń, aby zobaczyć więcej kontynentów',
                  style: hint,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.east, size: 16, color: hint?.color),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Headline(headline),
        const SizedBox(height: 4),
        Text(
          // The plan is one sentence; under the headline it reads as a tag.
          '${continent.label} · '
          '${_planText(context, overview).replaceFirst(RegExp(r'\.$'), '')}',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w400,
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
        if (overview.reservedNewElsewhere > 0 && active == null) ...[
          const SizedBox(height: 8),
          Text(
            'Nowe pytania czekają już w rozpoczętej wyprawie na innym '
            'kontynencie. Wróć do niej lub zakończ ją, aby zmienić zakres.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
        if (canStart || extra) ...[
          const SizedBox(height: 16),
          // The extra round is optional, so it never looks like the
          // day's main task.
          if (extra)
            FilledButton.tonalIcon(
              onPressed: () =>
                  _openAndRefresh(context, ref, '/daily?mode=extra'),
              icon: const Icon(Icons.replay),
              label: const Text('Kolejna runda'),
            )
          else
            _StartButton(
              label: active == null ? 'Rozpocznij wyprawę' : 'Wznów wyprawę',
              onPressed: () => _openAndRefresh(context, ref, '/daily'),
            ),
        ],
        // Placement helps at the start of a continent; later it is noise.
        if (active == null &&
            overview.newAvailable > 0 &&
            overview.learnedCount < placementUntilLearned)
          TextButton.icon(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () =>
                _openAndRefresh(context, ref, '/daily?mode=placement'),
            icon: const Icon(Icons.travel_explore),
            label: const Text('Kuna sprawdzi, co już wiesz'),
          ),
      ],
    );
  }
}

/// Big headline between two small bursts of sun rays.
class _Headline extends StatelessWidget {
  const _Headline(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final rays = GeoColors.of(context).sunRays;
    Widget burst(bool left) => ExcludeSemantics(
      child: CustomPaint(
        size: const Size(22, 30),
        painter: _RaysPainter(rays, mirrored: !left),
      ),
    );
    return Semantics(
      header: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          burst(true),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
          ),
          const SizedBox(width: 8),
          burst(false),
        ],
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  const _RaysPainter(this.color, {required this.mirrored});
  final Color color;
  final bool mirrored;

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = color
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final x0 = mirrored ? 2.0 : size.width - 2;
    final dir = mirrored ? 1.0 : -1.0;
    final mid = size.height / 2;
    canvas
      ..drawLine(Offset(x0, mid - 3), Offset(x0 + dir * 14, mid - 12), pen)
      ..drawLine(
        Offset(x0 + dir * 2, mid + 2),
        Offset(x0 + dir * 18, mid + 2),
        pen,
      )
      ..drawLine(Offset(x0, mid + 7), Offset(x0 + dir * 14, mid + 16), pen);
  }

  @override
  bool shouldRepaint(_RaysPainter oldDelegate) => oldDelegate.color != color;
}

/// The main call to action: a tall rounded green button with a compass and
/// a chevron, like the mockup.
class _StartButton extends StatelessWidget {
  const _StartButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(64),
      shape: const StadiumBorder(),
      textStyle: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w700),
    ),
    child: Row(
      children: [
        const Icon(Icons.explore_outlined, size: 30),
        const SizedBox(width: 12),
        Expanded(child: Text(label, textAlign: TextAlign.center)),
        const Icon(Icons.chevron_right, size: 28),
      ],
    ),
  );
}

/// Warm card with a soft border, shared by map progress and the tiles.
class _WarmCard extends StatelessWidget {
  const _WarmCard({
    required this.child,
    this.color,
    this.border,
    this.onTap,
    this.radius = 24,
  });
  final Widget child;
  final Color? color, border;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = GeoColors.of(context);
    return Material(
      color: color ?? colors.warmCard,
      elevation: 1,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: border ?? colors.warmCardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: child),
    );
  }
}

/// „Passa nauki”: the streak in a warm yellow card with a day counter.
class _StreakCard extends ConsumerWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = GeoColors.of(context);
    final theme = Theme.of(context);
    final streak = ref.watch(streakProvider).asData?.value;
    final current = streak?.current ?? 0;
    final today = streak?.practisedToday == true;
    final tokens = streak?.tokens ?? 0;
    final text = current == 0
        ? 'Zacznij dziś i zdobądź pierwsze dni!'
        : today
        ? 'Dzisiaj zaliczone — tak trzymaj!'
        : 'Odpowiedz dziś, aby jej nie stracić.';
    final next = streak?.nextReward;
    final reward = next == null
        ? null
        : 'Nagroda za $next dni z rzędu: '
              'jeszcze ${daysLabel(streak!.daysToNextReward!)}';
    return Semantics(
      liveRegion: true,
      label:
          'Passa nauki: ${daysLabel(current)}. $text '
          'Rekord: ${daysLabel(streak?.best ?? 0)}.'
          '${tokens > 0 ? ' Żetony Nieprzykunowanie: $tokens.' : ''}'
          '${reward == null ? '' : ' $reward.'}',
      excludeSemantics: true,
      child: _WarmCard(
        color: colors.streakCard,
        border: colors.streakCardBorder,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final title = Text(
                'Passa nauki',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              );
              final flame = Icon(
                Icons.local_fire_department,
                size: 40,
                color: colors.streak,
              );
              final counter = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  DecoratedBox(
                    decoration: ShapeDecoration(
                      color: colors.streakPill,
                      shape: const StadiumBorder(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: Text(
                        daysLabel(current),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  if (tokens > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [const TokenIcon(size: 18), Text(' $tokens')],
                    ),
                  ],
                ],
              );
              final details = [
                Text(text, style: theme.textTheme.bodyMedium),
                if (reward != null)
                  Text(reward, style: theme.textTheme.bodySmall),
              ];
              // Narrow screen or large text: the counter goes below.
              final narrow =
                  constraints.maxWidth <
                  MediaQuery.textScalerOf(context).scale(14) * 22;
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        flame,
                        const SizedBox(width: 8),
                        Expanded(child: title),
                      ],
                    ),
                    ...details,
                    const SizedBox(height: 8),
                    counter,
                  ],
                );
              }
              return Row(
                children: [
                  flame,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [title, ...details],
                    ),
                  ),
                  const SizedBox(width: 8),
                  counter,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TrainingRow extends ConsumerWidget {
  const _TrainingRow({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final area = ref.watch(selectedContinentProvider);
    final items = [
      ('Mapa', 'mapa', '/learn'),
      // Short on the tile; the screen title says „Miasta wojewódzkie”.
      ('Stolice', 'stolice', '/capitals'),
      (area.symbolsLabel, 'flagi', '/flags'),
    ];
    Widget tile((String, String, String) item) {
      final (label, art, path) = item;
      final image = ExcludeSemantics(
        // The art is 3:2 with a white margin; scale it to the tile width.
        child: AspectRatio(
          aspectRatio: 3 / 2,
          child: Transform.scale(
            scale: 1.25,
            child: Image.asset(
              'assets/home/tile_${area.artId}_$art.webp',
              fit: BoxFit.contain,
              cacheWidth: 384,
            ),
          ),
        ),
      );
      final text = Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      );
      return Semantics(
        button: true,
        label: 'Trening: $label',
        excludeSemantics: true,
        child: _WarmCard(
          radius: 22,
          onTap: () => _openAndRefresh(context, ref, path),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
            child: compact
                ? Row(
                    children: [
                      SizedBox(width: 96, child: image),
                      const SizedBox(width: 12),
                      Expanded(child: text),
                    ],
                  )
                : Column(children: [image, const SizedBox(height: 6), text]),
          ),
        ),
      );
    }

    if (compact) {
      return Column(
        children: [
          for (final item in items) ...[
            tile(item),
            if (item != items.last) const SizedBox(height: 8),
          ],
        ],
      );
    }
    return Row(
      children: [
        for (final item in items) ...[
          Expanded(child: tile(item)),
          if (item != items.last) const SizedBox(width: 10),
        ],
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

/// Map progress toward the next medal at the continent's current level.
class _MapProgress extends ConsumerWidget {
  const _MapProgress({required this.continent});
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
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      child: _WarmCard(
        onTap: () => context.push('/learning/${continent.name}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Image.asset(
                  'assets/home/icon_mountain.png',
                  width: 52,
                  height: 52,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 56,
                color: GeoColors.of(context).warmCardBorder,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${continent.label}: ${map.qualifiedCount}/'
                      '${map.totalCount} ${continent.areaNoun}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: map.qualifiedCount / map.totalCount,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
                      semanticsLabel: 'Postęp mapy',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (map.learningCount > 0)
                          'W nauce: ${map.learningCount}.',
                        next == null
                            ? 'Złoty medal zdobyty.'
                            : 'Do ${next.$2} medalu: jeszcze $missing.',
                      ].join(' '),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
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

/// The placement link disappears once this many cards have answers.
const placementUntilLearned = 10;

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
                    'assets/mascot/kuna-sad.png',
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
