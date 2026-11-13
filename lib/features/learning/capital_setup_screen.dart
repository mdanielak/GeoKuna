import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../app/providers.dart';
import 'capitals.dart';

class CapitalSetupScreen extends ConsumerStatefulWidget {
  const CapitalSetupScreen({super.key});
  @override
  ConsumerState<CapitalSetupScreen> createState() => _CapitalSetupScreenState();
}

class _CapitalSetupScreenState extends ConsumerState<CapitalSetupScreen> {
  CapitalDifficulty _difficulty = CapitalDifficulty.choice;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Stolice Europy')),
    body: ref
        .watch(capitalsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              LoadError(onRetry: () => ref.invalidate(capitalsProvider)),
          data: (capitals) => ref
              .watch(dashboardProvider)
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) =>
                    LoadError(onRetry: () => ref.invalidate(dashboardProvider)),
                data: (data) {
                  final pending = data.capitalSessions
                      .where((s) => s.row.difficulty == _difficulty.name)
                      .firstOrNull;
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          Text(
                            'Wybierz poziom trudności',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${capitals.facts.length} państw · 10 pytań w sesji · offline',
                          ),
                          const SizedBox(height: 20),
                          RadioGroup<CapitalDifficulty>(
                            groupValue: _difficulty,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _difficulty = value);
                              }
                            },
                            child: Column(
                              children: [
                                for (final difficulty
                                    in CapitalDifficulty.values)
                                  Card.filled(
                                    child: RadioListTile<CapitalDifficulty>(
                                      value: difficulty,
                                      title: Text(difficulty.label),
                                      subtitle: Text(difficulty.description),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Przy wpisywaniu akceptujemy jedną literówkę: zamianę, pominięcie, '
                            'dodanie litery lub przestawienie dwóch sąsiednich liter. '
                            'Wielkość liter i znaki diakrytyczne nie wpływają na wynik.',
                          ),
                          const SizedBox(height: 20),
                          if (pending != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Na tym poziomie czeka sesja: pytanie ${pending.index + 1} z ${pending.countryIds.length}.',
                              ),
                            ),
                          FilledButton(
                            onPressed: () async {
                              await context.push(
                                '/learn?topic=capitals&level=${_difficulty.name}',
                              );
                              if (context.mounted) {
                                ref.invalidate(dashboardProvider);
                              }
                            },
                            child: Text(
                              pending == null
                                  ? 'Rozpocznij trening stolic'
                                  : 'Wznów trening stolic',
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
