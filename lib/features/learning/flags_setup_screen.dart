import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../app/providers.dart';
import 'flags.dart';

class FlagsSetupScreen extends ConsumerStatefulWidget {
  const FlagsSetupScreen({super.key});
  @override
  ConsumerState<FlagsSetupScreen> createState() => _FlagsSetupScreenState();
}

class _FlagsSetupScreenState extends ConsumerState<FlagsSetupScreen> {
  FlagDifficulty _difficulty = FlagDifficulty.choice;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Flagi Europy')),
    body: SafeArea(
      top: false,
      child: ref
          .watch(flagsProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
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
                    final pending = data.flagsSessions.any(
                      (s) => s.row.difficulty == _difficulty.name,
                    );
                    final pendingMap = data.flagsSessions.any(
                      (s) => s.row.difficulty == 'map',
                    );
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            Text(
                              'Jakie to państwo?',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${flags.facts.length} flag · lokalne grafiki · 10 pytań',
                            ),
                            const SizedBox(height: 16),
                            RadioGroup<FlagDifficulty>(
                              groupValue: _difficulty,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _difficulty = value);
                                }
                              },
                              child: Column(
                                children: [
                                  for (final difficulty
                                      in FlagDifficulty.values.where(
                                        (d) => d != FlagDifficulty.map,
                                      ))
                                    Card.filled(
                                      child: RadioListTile<FlagDifficulty>(
                                        value: difficulty,
                                        title: Text(difficulty.label),
                                        subtitle: Text(difficulty.description),
                                        contentPadding: const EdgeInsets.all(
                                          12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Przy wpisywaniu dopuszczamy jedną literówkę. Polskie znaki nie są wymagane.',
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => _start(_difficulty),
                              child: Text(
                                pending
                                    ? 'Wznów quiz flag'
                                    : 'Rozpocznij quiz flag',
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'Flaga → mapa',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Rozpoznaj flagę i wskaż państwo na mapie. Masz trzy próby.',
                            ),
                            const SizedBox(height: 12),
                            FilledButton.tonalIcon(
                              onPressed: () => _start(FlagDifficulty.map),
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
  );
  Future<void> _start(FlagDifficulty difficulty) async {
    await context.push('/learn?topic=flags&level=${difficulty.name}');
    if (mounted) {
      ref.invalidate(dashboardProvider);
      ref.invalidate(dailyOverviewProvider);
      ref.invalidate(learningProgressProvider);
    }
  }
}
