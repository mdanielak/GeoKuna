import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../learning/session_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider).asData?.value;
    final daily = ref.watch(dailyOverviewProvider);
    final overview = daily.asData?.value;
    return Scaffold(
      appBar: AppBar(title: const Text('Dziś')),
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
                    Text(
                      'Twoja dzisiejsza wyprawa',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      overview?.activeSession != null
                          ? 'Wróć do miejsca, w którym przerwano dzisiejszą serię.'
                          : 'Krótka seria powtórek i nowych pytań o Europę.',
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
                                  ),
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
                                ],
                              ),
                            ),
                          ),
                          if (overview.plannedCount == 0 &&
                              overview.activeSession == null) ...[
                            const SizedBox(height: 8),
                            _NextDueNote(nextDue: overview.nextDue),
                          ],
                        ],
                      ),
                    ),
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
                      label: const Text('Trening stolic · wybierz poziom'),
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
                      label: const Text('Trening flag · wybierz tryb'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/atlas'),
                      icon: const Icon(Icons.map_outlined),
                      label: Text(
                        catalog == null
                            ? 'Odkrywaj atlas'
                            : 'Odkrywaj atlas · ${catalog.countries.length} państw',
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/progress'),
                      icon: const Icon(Icons.insights_outlined),
                      label: const Text('Postępy'),
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
  });

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
                ? 'Na dziś nie ma pytań do powtórki.'
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

class _NextDueNote extends StatelessWidget {
  const _NextDueNote({required this.nextDue});

  final DateTime? nextDue;

  @override
  Widget build(BuildContext context) {
    final dueDate = nextDue;
    final message = dueDate == null
        ? 'Nowe pytania pojawią się w kolejnych dniach.'
        : 'Następna powtórka: ${MaterialLocalizations.of(context).formatMediumDate(dueDate.toLocal())} o ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(dueDate.toLocal()), alwaysUse24HourFormat: true)}.';
    return Semantics(
      liveRegion: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_outline),
              const SizedBox(width: 12),
              Expanded(child: Text('Na dziś wszystko. $message')),
            ],
          ),
        ),
      ),
    );
  }
}
