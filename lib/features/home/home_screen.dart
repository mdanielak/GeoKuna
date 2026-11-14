import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../atlas/continent.dart';
import '../learning/session_repository.dart';
import '../learning/streaks.dart';
import '../settings/app_preferences.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _openDaily(
    BuildContext context,
    WidgetRef ref,
    String mode,
  ) async {
    await context.push('/daily?mode=$mode');
    if (context.mounted) ref.invalidate(dailyOverviewProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider).asData?.value;
    final continent = ref.watch(selectedContinentProvider);
    final daily = ref.watch(dailyOverviewProvider);
    final streak = ref.watch(streakProvider).asData?.value;
    final difficulty = ref
        .watch(appPreferencesProvider)
        .asData
        ?.value
        .difficultyFor(continent);
    final overview = daily.asData?.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dziś'),
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
            final horizontalPadding = constraints.maxWidth >= 600 ? 32.0 : 20.0;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    32,
                  ),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Kuna wie, gdzie!',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Image.asset(
                          'assets/mascot/kuna-globe.png',
                          width: 72,
                          height: 72,
                          cacheWidth: 216,
                          semanticLabel: 'Kuna z globusem',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Wybierz kontynent',
                      child:
                          MediaQuery.sizeOf(context).width < 360 ||
                              MediaQuery.textScalerOf(context).scale(14) > 18
                          ? Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final option in Continent.values)
                                  ChoiceChip(
                                    label: Text(option.label),
                                    selected: continent == option,
                                    showCheckmark: false,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.padded,
                                    onSelected: (_) => ref
                                        .read(
                                          selectedContinentProvider.notifier,
                                        )
                                        .select(option),
                                  ),
                              ],
                            )
                          : SegmentedButton<Continent>(
                              segments: [
                                for (final option in Continent.values)
                                  ButtonSegment<Continent>(
                                    value: option,
                                    label: Text(option.label),
                                    icon: Icon(switch (option) {
                                      Continent.europe => Icons.public_outlined,
                                      Continent.africa =>
                                        Icons.landscape_outlined,
                                      Continent.asia =>
                                        Icons.travel_explore_outlined,
                                    }),
                                  ),
                              ],
                              selected: {continent},
                              showSelectedIcon: false,
                              onSelectionChanged: (selection) {
                                if (selection.isNotEmpty &&
                                    selection.single != continent) {
                                  ref
                                      .read(selectedContinentProvider.notifier)
                                      .select(selection.single);
                                }
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      liveRegion: true,
                      label:
                          'Passa: ${daysLabel(streak?.current ?? 0)} z rzędu. Rekord: ${daysLabel(streak?.best ?? 0)}.',
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        leading: const Icon(
                          Icons.local_fire_department_outlined,
                        ),
                        title: Text(
                          'Passa: ${daysLabel(streak?.current ?? 0)} z rzędu',
                        ),
                        subtitle: Text(
                          streak?.practisedToday == true
                              ? 'Dzisiejsza nauka zaliczona. Rekord: ${daysLabel(streak?.best ?? 0)}.'
                              : (streak?.current ?? 0) == 0
                              ? 'Odpowiedz dziś na jedno pytanie, aby zacząć passę.'
                              : 'Odpowiedz dziś, aby jej nie przerwać. Rekord: ${daysLabel(streak?.best ?? 0)}.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Wyprawa po ${continent.journey}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      overview?.activeSession != null
                          ? 'Wróć do miejsca, w którym przerwano dzisiejszą serię.'
                          : 'Krótka seria powtórek i nowych pytań.',
                    ),
                    const SizedBox(height: 20),
                    daily.when(
                      loading: () => const Card.filled(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      error: (_, _) => Card.filled(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Semantics(
                            liveRegion: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Nie udało się wczytać dzisiejszej wyprawy.',
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: () {
                                    if (ref.read(catalogProvider).hasError) {
                                      ref.invalidate(catalogProvider);
                                    }
                                    if (ref.read(capitalsProvider).hasError) {
                                      ref.invalidate(capitalsProvider);
                                    }
                                    if (ref.read(flagsProvider).hasError) {
                                      ref.invalidate(flagsProvider);
                                    }
                                    try {
                                      ref.read(databaseProvider);
                                    } catch (_) {
                                      ref.invalidate(databaseProvider);
                                    }
                                    ref.invalidate(dailyOverviewProvider);
                                  },
                                  child: const Text('Ponów odczyt'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      data: (overview) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card.filled(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _DailyCounts(
                                    due: overview.dueCount,
                                    newCards: overview.plannedNewCount,
                                    total: overview.plannedCount,
                                    activeSession: overview.activeSession,
                                    nextDue: overview.nextDue,
                                  ),
                                  if (overview.otherDueCount > 0) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Na innych poziomach: ${overview.otherDueCount} powtórek.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                  if (overview.reservedNewElsewhere > 0 &&
                                      overview.activeSession == null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Nowe pytania czekają już w rozpoczętej '
                                      'wyprawie na innym kontynencie. Wróć do '
                                      'niej lub zakończ ją, aby zmienić zakres.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                  if (overview.plannedCount > 0 ||
                                      overview.activeSession != null) ...[
                                    const SizedBox(height: 18),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed: () async {
                                          await context.push('/daily');
                                          if (context.mounted) {
                                            ref.invalidate(
                                              dailyOverviewProvider,
                                            );
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.explore_outlined,
                                        ),
                                        label: Text(
                                          overview.activeSession == null
                                              ? 'Rozpocznij dzisiejszą wyprawę'
                                              : 'Wznów dzisiejszą wyprawę',
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (overview.activeSession == null) ...[
                                    if (overview.plannedCount == 0 &&
                                        overview.canStartExtra) ...[
                                      const SizedBox(height: 18),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton.icon(
                                          onPressed: () =>
                                              _openDaily(context, ref, 'extra'),
                                          icon: const Icon(Icons.replay),
                                          label: const Text('Kolejna runda'),
                                        ),
                                      ),
                                    ],
                                    if (overview.newAvailable > 0) ...[
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () => _openDaily(
                                            context,
                                            ref,
                                            'placement',
                                          ),
                                          icon: const Icon(
                                            Icons.travel_explore,
                                          ),
                                          label: const Text(
                                            'Kuna sprawdzi, co już wiesz',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Kraje, które już znasz, od razu '
                                        'pominiesz.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Poziom wyprawy',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final level in LearningDifficulty.values)
                          ChoiceChip(
                            label: Text(level.label),
                            selected:
                                (difficulty ?? LearningDifficulty.normal) ==
                                level,
                            showCheckmark: false,
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            onSelected: (selected) async {
                              if (!selected || difficulty == level) return;
                              await ref
                                  .read(appPreferencesProvider.notifier)
                                  .setDifficulty(continent, level);
                              ref.invalidate(dailyOverviewProvider);
                            },
                          ),
                      ],
                    ),
                    if (overview?.activeSession != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Rozpoczęta wyprawa zachowuje zapisane poziomy; wybór tutaj dotyczy następnej.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Wybierz własny trening',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        await context.push('/learn');
                        if (context.mounted) {
                          ref.invalidate(dailyOverviewProvider);
                        }
                      },
                      icon: const Icon(Icons.public_outlined),
                      label: const Text('Trening mapy'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        await context.push('/capitals');
                        if (context.mounted) {
                          ref.invalidate(dailyOverviewProvider);
                        }
                      },
                      icon: const Icon(Icons.location_city_outlined),
                      label: const Text('Trening stolic'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        await context.push('/flags');
                        if (context.mounted) {
                          ref.invalidate(dailyOverviewProvider);
                        }
                      },
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('Trening flag'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/atlas'),
                      icon: const Icon(Icons.map_outlined),
                      label: Text(
                        catalog == null
                            ? 'Atlas'
                            : 'Atlas: ${catalog.countries.length} państw',
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/learning'),
                      icon: const Icon(Icons.insights_outlined),
                      label: const Text('Moja nauka'),
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

class _DailyCounts extends StatelessWidget {
  const _DailyCounts({
    required this.due,
    required this.newCards,
    required this.total,
    required this.activeSession,
    this.nextDue,
  });

  final DateTime? nextDue;

  final int due;
  final int newCards;
  final int total;
  final LearningSession? activeSession;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium;
    final active = activeSession;
    final remaining = active == null
        ? null
        : active.countryIds.length -
              active.index -
              (active.currentAttempt == null ? 0 : 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (remaining != null) ...[
          Text(
            'Seria w toku',
            style: textStyle?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text('Pozostało $remaining ${_questionWord(remaining)}'),
        ] else ...[
          Text(
            total == 0
                ? _calmMessage(context, nextDue)
                : '$total ${_questionWord(total)} w dzisiejszej serii',
            style: textStyle?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (total > 0) ...[
            const SizedBox(height: 8),
            Text('$due ${_reviewWord(due)} · $newCards nowych w serii'),
          ],
        ],
      ],
    );
  }

  String _questionWord(int count) {
    if (count == 1) return 'pytanie';
    if (count % 10 >= 2 &&
        count % 10 <= 4 &&
        (count % 100 < 12 || count % 100 > 14)) {
      return 'pytania';
    }
    return 'pytań';
  }

  String _reviewWord(int count) {
    if (count == 1) return 'powtórka';
    if (count % 10 >= 2 &&
        count % 10 <= 4 &&
        (count % 100 < 12 || count % 100 > 14)) {
      return 'powtórki';
    }
    return 'powtórek';
  }
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
    return 'Kolejna powtórka dziś o $time.';
  }
  final date = MaterialLocalizations.of(context).formatMediumDate(local);
  return 'Na dziś wszystko. Kolejna powtórka: $date o $time.';
}
