import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../app/providers.dart';
import '../atlas/continent.dart';
import '../settings/app_preferences.dart';

class CapitalSetupScreen extends ConsumerWidget {
  const CapitalSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continent = ref.watch(selectedContinentProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('${continent.capitalsLabel} ${continent.genitive}'),
      ),
      body: ref
          .watch(appPreferencesProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => LoadError(
              onRetry: () => ref.invalidate(appPreferencesProvider),
            ),
            data: (preferences) => ref
                .watch(capitalsProvider)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => LoadError(
                    onRetry: () => ref.invalidate(capitalsProvider),
                  ),
                  data: (capitals) => ref
                      .watch(dashboardProvider)
                      .when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, _) => LoadError(
                          onRetry: () => ref.invalidate(dashboardProvider),
                        ),
                        data: (data) {
                          final selectedDifficulty = preferences.difficultyFor(
                            continent,
                          );
                          final pending = data.capitalSessions
                              .where(
                                (s) =>
                                    s.row.difficulty == selectedDifficulty.mode,
                              )
                              .firstOrNull;
                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 620),
                              child: ListView(
                                padding: const EdgeInsets.all(24),
                                children: [
                                  Text(
                                    continent == Continent.poland
                                        ? 'Trenuj miasta wojewódzkie.'
                                        : continent == Continent.usa
                                        ? 'Trenuj stolice stanów.'
                                        : 'Trenuj przypominanie stolic państw.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${capitals.facts.length} ${continent.areaNoun} · 10 pytań w sesji · offline',
                                  ),
                                  const SizedBox(height: 20),
                                  Card.filled(
                                    child: ListTile(
                                      leading: const Icon(Icons.tune),
                                      title: Text(
                                        'Poziom: ${selectedDifficulty.label}',
                                      ),
                                      subtitle: Text(
                                        selectedDifficulty.description,
                                      ),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () => context.push('/settings'),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: () =>
                                          context.push('/settings'),
                                      icon: const Icon(Icons.settings_outlined),
                                      label: const Text(
                                        'Zmień poziom w ustawieniach',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'W odpowiedziach pisanych dopuszczamy jedną literówkę; wielkość liter i polskie znaki nie zmieniają wyniku.',
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton(
                                      onPressed: () =>
                                          _showAnswerRules(context),
                                      child: const Text(
                                        'Jak sprawdzamy odpowiedzi?',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (pending != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Text(
                                        'Na tym poziomie czeka sesja: pytanie ${pending.index + 1} z ${pending.countryIds.length}.',
                                      ),
                                    ),
                                  FilledButton(
                                    onPressed: () async {
                                      await context.push(
                                        '/learn?topic=capitals&level=${selectedDifficulty.mode}',
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
          ),
    );
  }

  Future<void> _showAnswerRules(BuildContext context) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Jak sprawdzamy odpowiedzi?'),
      content: const Text(
        'Przy wpisywaniu akceptujemy jedną literówkę: zamianę, pominięcie, dodanie litery lub przestawienie dwóch sąsiednich liter. Wielkość liter i znaki diakrytyczne nie wpływają na wynik.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Rozumiem'),
        ),
      ],
    ),
  );
}
