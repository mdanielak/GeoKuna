import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../app/providers.dart';
import '../atlas/continent.dart';
import '../settings/app_preferences.dart';
import 'flags.dart';

class FlagsSetupScreen extends ConsumerWidget {
  const FlagsSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continent = ref.watch(selectedContinentProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('${continent.symbolsLabel} ${continent.genitive}'),
      ),
      body: SafeArea(
        top: false,
        child: ref
            .watch(appPreferencesProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => LoadError(
                onRetry: () => ref.invalidate(appPreferencesProvider),
              ),
              data: (preferences) => ref
                  .watch(flagsProvider)
                  .when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) =>
                        LoadError(onRetry: () => ref.invalidate(flagsProvider)),
                    data: (flags) => ref
                        .watch(dashboardProvider)
                        .when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, _) => LoadError(
                            onRetry: () => ref.invalidate(dashboardProvider),
                          ),
                          data: (data) {
                            final selectedDifficulty = preferences
                                .difficultyFor(continent);
                            final pending = data.flagsSessions.any(
                              (s) =>
                                  s.row.difficulty == selectedDifficulty.mode,
                            );
                            final pendingMap = data.flagsSessions.any(
                              (s) => s.row.difficulty == 'map',
                            );
                            return Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 620,
                                ),
                                child: ListView(
                                  padding: const EdgeInsets.all(24),
                                  children: [
                                    Text(
                                      continent == Continent.poland
                                          ? 'Rozpoznawaj herby województw.'
                                          : 'Rozpoznawaj flagi ${continent.areaNoun}.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${flags.facts.length} ${continent == Continent.poland ? 'herbów' : 'flag'} · lokalne grafiki · 10 pytań',
                                    ),
                                    const SizedBox(height: 16),
                                    Card.filled(
                                      child: ListTile(
                                        leading: const Icon(Icons.tune),
                                        title: Text(
                                          'Poziom: ${selectedDifficulty.label}',
                                        ),
                                        subtitle: Text(
                                          selectedDifficulty.description
                                              .replaceAll(
                                                'państwo',
                                                continent.areaAccusative,
                                              ),
                                        ),
                                        trailing: const Icon(
                                          Icons.chevron_right,
                                        ),
                                        onTap: () => context.push('/settings'),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: () =>
                                            context.push('/settings'),
                                        icon: const Icon(
                                          Icons.settings_outlined,
                                        ),
                                        label: const Text(
                                          'Zmień poziom w ustawieniach',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Przy wpisywaniu dopuszczamy jedną literówkę. Polskie znaki nie są wymagane.',
                                    ),
                                    const SizedBox(height: 16),
                                    FilledButton(
                                      onPressed: () => _start(
                                        context,
                                        ref,
                                        selectedDifficulty.mode,
                                      ),
                                      child: Text(
                                        pending
                                            ? 'Wznów quiz: ${continent.symbolsLabel.toLowerCase()}'
                                            : 'Rozpocznij quiz: ${continent.symbolsLabel.toLowerCase()}',
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    Text(
                                      '${continent.symbolLabel} → mapa',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Rozpoznaj ${continent == Continent.poland ? 'herb' : 'flagę'} i wskaż ${continent.areaAccusative} na mapie. Masz trzy próby.',
                                    ),
                                    const SizedBox(height: 12),
                                    FilledButton.tonalIcon(
                                      onPressed: () => _start(
                                        context,
                                        ref,
                                        FlagDifficulty.map.name,
                                      ),
                                      icon: const Icon(Icons.public),
                                      label: Text(
                                        pendingMap
                                            ? 'Wznów: flaga → mapa'
                                            : 'Rozpocznij: flaga → mapa',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  ),
            ),
      ),
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref, String mode) async {
    await context.push('/learn?topic=flags&level=$mode');
    if (context.mounted) {
      ref.invalidate(dashboardProvider);
      ref.invalidate(dailyOverviewProvider);
      ref.invalidate(learningProgressProvider);
    }
  }
}
