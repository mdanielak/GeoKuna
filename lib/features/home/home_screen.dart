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

/// Today: one expedition card with the kuna, its level, map progress and
/// free training.
/// Atlas and "Moja nauka" live in the bottom navigation bar.
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
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(side, 4, side, 24),
                  children: [
                    _ContinentPicker(continent: continent),
                    const SizedBox(height: 16),
                    _StreakRescueCard(continent: continent),
                    daily.when(
                      loading: () => const _CardShell(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      error: (_, _) => _LoadFailed(ref: ref),
                      data: (overview) => _ExpeditionCard(
                        continent: continent,
                        overview: overview,
                        compact: compact,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _LevelRow(
                      continent: continent,
                      activeSession: daily.asData?.value.activeSession != null,
                    ),
                    _MapProgress(continent: continent),
                    const SizedBox(height: 20),
                    Text(
                      'Trening dowolny',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Wybierz temat. Odpowiedzi liczą się do passy i powtórek.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    _TrainingRow(compact: compact),
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

/// Continents without content yet, shown greyed out as a promise.
const _upcomingContinents = <String>[];

/// One scrollable row of chips: the three playable continents, then the
/// upcoming ones disabled. Chips keep one row at any width and text size.
class _ContinentPicker extends ConsumerWidget {
  const _ContinentPicker({required this.continent});
  final Continent continent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
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
                onSelected: (_) =>
                    ref.read(selectedContinentProvider.notifier).select(option),
              ),
              const SizedBox(width: 8),
            ],
            for (final name in _upcomingContinents) ...[
              Tooltip(
                message: '$name: wkrótce',
                child: Semantics(
                  label: '$name, wkrótce',
                  excludeSemantics: true,
                  child: ChoiceChip(
                    label: Text(name),
                    selected: false,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    onSelected: null,
                  ),
                ),
              ),
              if (name != _upcomingContinents.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
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

class _ExpeditionCard extends ConsumerWidget {
  const _ExpeditionCard({
    required this.continent,
    required this.overview,
    required this.compact,
  });
  final Continent continent;
  final MemoryOverview overview;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final active = overview.activeSession;
    final canStart = overview.plannedCount > 0 || active != null;
    final extra =
        active == null && overview.plannedCount == 0 && overview.canStartExtra;
    final mascot = compact ? 56.0 : 88.0;
    final details = [
      const SizedBox(height: 4),
      Text(_planText(context, overview)),
      const SizedBox(height: 8),
      const _StreakLine(),
    ];
    final title = Text(
      'Wyprawa po ${continent.journey}',
      style: theme.textTheme.titleLarge,
    );
    final kuna = Image.asset(
      'assets/mascot/kuna-globe.png',
      width: mascot,
      height: mascot,
      cacheWidth: 264,
      semanticLabel: 'Kuna z globusem',
    );
    return _CardShell(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Very large text: the kuna goes above the title, so words never
          // break mid-word in a narrow column beside her.
          final stacked =
              constraints.maxWidth - mascot - 14 <
              MediaQuery.textScalerOf(context).scale(22) * 6;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (stacked) ...[
                Align(alignment: Alignment.centerLeft, child: kuna),
                const SizedBox(height: 8),
                title,
                ...details,
              ] else
                Row(
                  crossAxisAlignment: compact
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    kuna,
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          title,
                          // Narrow screens keep the details full width below.
                          if (!compact) ...details,
                        ],
                      ),
                    ),
                  ],
                ),
              if (compact && !stacked) ...details,
              if (overview.otherDueCount > 0) ...[
                const SizedBox(height: 12),
                Text(
                  'Na innych poziomach: ${overview.otherDueCount} '
                  '${_plural(overview.otherDueCount, 'powtórka', 'powtórki', 'powtórek')}.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (overview.reservedNewElsewhere > 0 && active == null) ...[
                const SizedBox(height: 12),
                Text(
                  'Nowe pytania czekają już w rozpoczętej wyprawie na innym '
                  'kontynencie. Wróć do niej lub zakończ ją, aby zmienić zakres.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (canStart || extra) ...[
                const SizedBox(height: 18),
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
                  FilledButton.icon(
                    onPressed: () => _openAndRefresh(context, ref, '/daily'),
                    icon: const Icon(Icons.explore_outlined),
                    label: Text(
                      active == null ? 'Rozpocznij wyprawę' : 'Wznów wyprawę',
                    ),
                  ),
              ],
              // Placement helps at the start of a continent; later it is noise.
              if (active == null &&
                  overview.newAvailable > 0 &&
                  overview.learnedCount < placementUntilLearned) ...[
                const SizedBox(height: 4),
                TextButton.icon(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: () =>
                      _openAndRefresh(context, ref, '/daily?mode=placement'),
                  icon: const Icon(Icons.travel_explore),
                  label: const Text('Kuna sprawdzi, co już wiesz'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StreakLine extends ConsumerWidget {
  const _StreakLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider).asData?.value;
    final current = streak?.current ?? 0;
    final today = streak?.practisedToday == true;
    final tokens = streak?.tokens ?? 0;
    final text = current == 0
        ? 'Zacznij dziś passę'
        : today
        ? 'Passa: ${daysLabel(current)}'
        : 'Passa: ${daysLabel(current)}, odpowiedz dziś';
    final spoken = today ? '$text, dzisiaj zaliczona' : text;
    final next = streak?.nextReward;
    final reward = next == null
        ? null
        : 'Nagroda za $next dni z rzędu: '
              'jeszcze ${daysLabel(streak!.daysToNextReward!)}';
    return Semantics(
      liveRegion: true,
      label:
          '$spoken. '
          'Rekord: ${daysLabel(streak?.best ?? 0)}.'
          '${tokens > 0 ? ' Żetony Nieprzykunowanie: $tokens.' : ''}'
          '${reward == null ? '' : ' $reward.'}',
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(
            today
                ? Icons.local_fire_department
                : Icons.local_fire_department_outlined,
            size: 20,
            color: today ? GeoColors.of(context).streak : null,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: text,
                    children: [
                      if (tokens > 0) ...[
                        const TextSpan(text: '  '),
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: TokenIcon(size: 18),
                        ),
                        TextSpan(text: ' $tokens'),
                      ],
                    ],
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (reward != null)
                  Text(reward, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingRow extends ConsumerWidget {
  const _TrainingRow({required this.compact});
  final bool compact;

  static const _items = [
    ('Mapa', Icons.public_outlined, '/learn'),
    ('Stolice', Icons.location_city_outlined, '/capitals'),
    ('Flagi', Icons.flag_outlined, '/flags'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    // Voivodeships and US states have no capital/flag packs yet (stage 2).
    final items = ref.watch(selectedContinentProvider).hasCapitalsAndFlags
        ? _items
        : _items.take(1).toList();
    Widget tile((String, IconData, String) item) {
      final (label, icon, path) = item;
      final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      );
      return Semantics(
        button: true,
        label: 'Trening: $label',
        excludeSemantics: true,
        child: Material(
          color: scheme.surface,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openAndRefresh(context, ref, path),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: compact ? 12 : 16,
                horizontal: 12,
              ),
              child: compact
                  ? Row(
                      children: [
                        Icon(icon, color: scheme.primary),
                        const SizedBox(width: 12),
                        Expanded(child: Text(label)),
                      ],
                    )
                  : Column(
                      children: [
                        Icon(icon, size: 28, color: scheme.primary),
                        const SizedBox(height: 6),
                        Text(label, maxLines: 1),
                      ],
                    ),
            ),
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
                  subtitle: Text(level.descriptionFor(continent)),
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
      leading: const Icon(Icons.tune),
      title: Text('Poziom dla ${continent.genitive}: ${current.label}'),
      subtitle: Text(current.descriptionFor(continent)),
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: const Icon(Icons.emoji_events_outlined),
      title: Text(
        'Mapa ${continent.genitive}: ${map.qualifiedCount} z ${map.totalCount}',
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: map.qualifiedCount / map.totalCount,
            borderRadius: BorderRadius.circular(4),
            semanticsLabel: 'Postęp mapy',
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (map.learningCount > 0)
                'W nauce: ${map.learningCount} '
                    '${_plural(map.learningCount, 'kraj', 'kraje', 'krajów')}.',
              next == null
                  ? 'Złoty medal zdobyty.'
                  : 'Do ${next.$2} medalu: jeszcze $missing.',
            ].join(' '),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/learning/${continent.name}'),
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
