import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../atlas/continent.dart';
import '../learning/learning_progress.dart';

/// A transparent practice indicator, not a claim of long-term mastery.
class KnowledgeSummary {
  KnowledgeSummary(Iterable<LearningProgressEntry> entries)
    : entries = entries.toList();
  final List<LearningProgressEntry> entries;
  int get ready => entries
      .where((e) => e.status == LearningProgressStatus.practising)
      .length;
  int get review =>
      entries.where((e) => e.status == LearningProgressStatus.review).length;
  int get unknown => entries
      .where((e) => e.status == LearningProgressStatus.insufficient)
      .length;
  int get percent =>
      entries.isEmpty ? 0 : (ready * 100 / entries.length).floor();
}

String _topicLabel(String topic) => switch (topic) {
  'map' => 'Państwo → mapa',
  'capitals' => 'Państwo → stolica',
  'flags' => 'Flaga → państwo',
  'flagMap' => 'Flaga → mapa',
  _ => topic,
};

String _medalLabel(int medal) => switch (medal) {
  1 => 'Brązowy',
  2 => 'Srebrny',
  3 => 'Złoty',
  _ => 'Jeszcze niezdobyty',
};

class LearningOverviewScreen extends ConsumerWidget {
  const LearningOverviewScreen({super.key, this.continent});
  final Continent? continent;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: Text(
        continent == null ? 'Moja nauka' : 'Nauka · ${continent!.label}',
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: continent == null
              ? ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Jak idzie nauka?',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Procent pokazuje umiejętności z poprawną ostatnią odpowiedzią i przyszłym terminem powtórki. A–D ma osobny harmonogram rozpoznawania. Z pomocą odpowiedź nie aktualizuje karty. To wskaźnik treningu, nie gwarancja trwałego zapamiętania.',
                    ),
                    const SizedBox(height: 20),
                    for (final region in Continent.values)
                      ref
                          .watch(continentProgressProvider(region))
                          .when(
                            loading: () => ListTile(
                              title: Text(region.label),
                              subtitle: const LinearProgressIndicator(),
                            ),
                            error: (_, _) => ListTile(
                              title: Text(region.label),
                              subtitle: const Text(
                                'Nie udało się odczytać postępu',
                              ),
                              trailing: IconButton(
                                tooltip: 'Ponów odczyt',
                                onPressed: () => ref.invalidate(
                                  continentProgressProvider(region),
                                ),
                                icon: const Icon(Icons.refresh),
                              ),
                            ),
                            data: (entries) {
                              final summary = KnowledgeSummary(entries);
                              return Card.filled(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(20),
                                  title: Text(
                                    '${region.label} · na bieżąco ${summary.percent}%',
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        LinearProgressIndicator(
                                          value: summary.percent / 100,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${summary.ready} / ${summary.entries.length} umiejętności na bieżąco\nDo powtórki: ${summary.review} · Niesprawdzone: ${summary.unknown}',
                                        ),
                                        const SizedBox(height: 8),
                                        ref
                                            .watch(
                                              continentAchievementsProvider(
                                                region,
                                              ),
                                            )
                                            .when(
                                              loading: () => const Text(
                                                'Medale: wczytywanie',
                                              ),
                                              error: (_, _) => const Text(
                                                'Medali nie udało się wczytać',
                                              ),
                                              data: (items) => Text(
                                                'Medale: ${items.fold<int>(0, (total, item) => total + item.earnedMedal)} z 36',
                                              ),
                                            ),
                                      ],
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () =>
                                      context.push('/learning/${region.name}'),
                                ),
                              );
                            },
                          ),
                  ],
                )
              : _details(context, ref, continent!),
        ),
      ),
    ),
  );

  Widget _details(BuildContext context, WidgetRef ref, Continent region) => ref
      .watch(continentProgressProvider(region))
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(continentProgressProvider(region)),
            child: const Text('Ponów odczyt'),
          ),
        ),
        data: (entries) {
          final groups = <String, List<LearningProgressEntry>>{};
          for (final entry in entries) {
            groups.putIfAbsent(entry.country.id, () => []).add(entry);
          }
          final countries = groups.values.toList()
            ..sort((a, b) {
              final x = KnowledgeSummary(a), y = KnowledgeSummary(b);
              final review = y.review.compareTo(x.review);
              if (review != 0) return review;
              final percentage = x.percent.compareTo(y.percent);
              return percentage != 0
                  ? percentage
                  : a.first.country.name.compareTo(b.first.country.name);
            });
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Gdzie warto wrócić?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Najpierw kraje z powtórkami, potem te z najmniejszą liczbą sprawdzonych umiejętności. Dotknij kraju, aby zobaczyć szczegóły.',
              ),
              const SizedBox(height: 16),
              _medalsSection(ref, region),
              const SizedBox(height: 12),
              for (final country in countries)
                Builder(
                  builder: (context) {
                    final summary = KnowledgeSummary(country);
                    return ListTile(
                      minTileHeight: 72,
                      title: Text(
                        '${country.first.country.name} · ${summary.percent}%',
                      ),
                      subtitle: Text(
                        'Do powtórki: ${summary.review} · Niesprawdzone: ${summary.unknown}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ref
                            .read(selectedContinentProvider.notifier)
                            .select(region);
                        context.push(
                          Uri(
                            path: '/progress',
                            queryParameters: {
                              'country': country.first.country.name,
                            },
                          ).toString(),
                        );
                      },
                    );
                  },
                ),
            ],
          );
        },
      );

  Widget _medalsSection(WidgetRef ref, Continent region) => ref
      .watch(continentAchievementsProvider(region))
      .when(
        loading: () => const Card.filled(
          child: ListTile(
            title: Text('Medale za naukę'),
            subtitle: LinearProgressIndicator(),
          ),
        ),
        error: (_, _) => const Card.filled(
          child: ListTile(
            title: Text('Medale za naukę'),
            subtitle: Text('Nie udało się ich wczytać.'),
          ),
        ),
        data: (achievements) {
          final earned = achievements
              .where((item) => item.earnedMedal > 0)
              .length;
          return Card.filled(
            child: ExpansionTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('Medale za naukę'),
              subtitle: Text('$earned z 36 zdobytych · progi 50%, 80% i 100%'),
              children: [
                for (final topic in ['map', 'capitals', 'flags', 'flagMap'])
                  ExpansionTile(
                    key: PageStorageKey('medals-$topic-${region.name}'),
                    title: Text(_topicLabel(topic)),
                    children: [
                      for (final level in achievements.where(
                        (achievement) => achievement.topic == topic,
                      ))
                        ListTile(
                          leading: Icon(
                            level.earnedMedal == 0
                                ? Icons.workspace_premium_outlined
                                : Icons.workspace_premium,
                            color: switch (level.earnedMedal) {
                              1 => const Color(0xFF9A6339),
                              2 => const Color(0xFF6F777D),
                              3 => const Color(0xFF9A7420),
                              _ => null,
                            },
                          ),
                          title: Text(
                            '${level.level.label} · ${_medalLabel(level.earnedMedal)}',
                          ),
                          subtitle: Text(
                            '${level.qualifiedCount} / ${level.totalCount} krajów zaliczonych'
                            '${level.inheritedCount > 0 ? ' · ${level.inheritedCount} z trudniejszego poziomu' : ''}',
                          ),
                          trailing: Text('${level.percent}%'),
                        ),
                    ],
                  ),
              ],
            ),
          );
        },
      );
}
