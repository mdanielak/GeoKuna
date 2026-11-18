import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../atlas/continent.dart';
import '../learning/learning_progress.dart';
import '../learning/streaks.dart';
import '../learning/token_icon.dart';

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

String _topicLabel(String topic, Continent area) => switch (topic) {
  'map' => 'Lokalizacja na mapie',
  'capitals' => area.capitalsLabel,
  'flags' => '${area.symbolsLabel} · nazwy',
  'flagMap' => '${area.symbolLabel} na mapie',
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
    appBar: continent == null
        ? AppBar(title: const Text('Moja nauka'))
        : regionAppBar(
            context,
            continent: continent!,
            title: 'Nauka · ${continent!.label}',
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
                    const SizedBox(height: 8),
                    Text(
                      'Procent pokazuje umiejętności z poprawną ostatnią odpowiedzią i przyszłym terminem powtórki. A–D ma osobny harmonogram rozpoznawania. To wskaźnik treningu, nie gwarancja trwałego zapamiętania.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final region in Continent.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RegionOverviewCard(region: region),
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
                'Najpierw obszary z powtórkami, potem te z najmniejszą liczbą sprawdzonych umiejętności. Dotknij wiersza, aby zobaczyć szczegóły.',
              ),
              const SizedBox(height: 16),
              _medalsSection(ref, region),
              const SizedBox(height: 12),
              _StreakRewards(region: region),
              const SizedBox(height: 16),
              Card.outlined(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (index, country) in countries.indexed) ...[
                      if (index > 0) const Divider(height: 1),
                      Builder(
                        builder: (context) {
                          final summary = KnowledgeSummary(country);
                          return ListTile(
                            minTileHeight: 68,
                            title: Text(
                              '${country.first.country.name} · ${summary.percent}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
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
                  ],
                ),
              ),
            ],
          );
        },
      );

  Widget _medalsSection(WidgetRef ref, Continent region) => ref
      .watch(continentAchievementsProvider(region))
      .when(
        loading: () => const Card.filled(
          margin: EdgeInsets.zero,
          child: ListTile(
            title: Text('Medale za naukę'),
            subtitle: LinearProgressIndicator(),
          ),
        ),
        error: (_, _) => const Card.filled(
          margin: EdgeInsets.zero,
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
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('Medale za naukę'),
              subtitle: Text('$earned z 36 zdobytych · progi 50%, 80% i 100%'),
              children: [
                for (final topic in ['map', 'capitals', 'flags', 'flagMap'])
                  ExpansionTile(
                    key: PageStorageKey('medals-$topic-${region.name}'),
                    title: Text(_topicLabel(topic, region)),
                    children: [
                      for (final level in achievements.where(
                        (achievement) => achievement.topic == topic,
                      ))
                        ListTile(
                          leading: level.earnedMedal == 0
                              ? const Icon(Icons.workspace_premium_outlined)
                              : Image.asset(
                                  'assets/v2/medal_${const ['braz', 'srebro', 'zloto'][level.earnedMedal - 1]}.webp',
                                  width: 36,
                                  height: 36,
                                  cacheWidth: 108,
                                ),
                          title: Text(
                            '${level.level.label} · ${_medalLabel(level.earnedMedal)}',
                          ),
                          subtitle: Text(
                            '${level.qualifiedCount} / ${level.totalCount} ${region.areaNoun} zaliczonych'
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

/// Look v2 region progress card with the region's miniature illustration,
/// practice bar, medals and streak rewards.
class _RegionOverviewCard extends ConsumerWidget {
  const _RegionOverviewCard({required this.region});
  final Continent region;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = GeoColors.of(context);
    return ref
        .watch(continentProgressProvider(region))
        .when(
          loading: () => Card.filled(
            margin: EdgeInsets.zero,
            child: ListTile(
              title: Text(region.label),
              subtitle: const LinearProgressIndicator(),
            ),
          ),
          error: (_, _) => Card.filled(
            margin: EdgeInsets.zero,
            child: ListTile(
              title: Text(region.label),
              subtitle: const Text('Nie udało się odczytać postępu'),
              trailing: IconButton(
                tooltip: 'Ponów odczyt',
                onPressed: () =>
                    ref.invalidate(continentProgressProvider(region)),
                icon: const Icon(Icons.refresh),
              ),
            ),
          ),
          data: (entries) {
            final summary = KnowledgeSummary(entries);
            final streakRewardsEarned =
                ref
                    .watch(continentStreakProvider(region))
                    .asData
                    ?.value
                    .earnedRewards
                    .length ??
                0;
            return Card.filled(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/learning/${region.name}'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 60,
                            height: 68,
                            child: Image(
                              image: ResizeImage(
                                AssetImage(
                                  'assets/v2/banner_${region.artId}_1.webp',
                                ),
                                width: 180,
                              ),
                              fit: BoxFit.cover,
                              alignment: const Alignment(0, -.25),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${region.label} · na bieżąco ${summary.percent}%',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 22),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: summary.percent / 100,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${summary.ready} / ${summary.entries.length} umiejętności na bieżąco\n'
                              'Do powtórki: ${summary.review} · Niesprawdzone: ${summary.unknown}',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.workspace_premium_outlined,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    ref
                                        .watch(
                                          continentAchievementsProvider(region),
                                        )
                                        .when(
                                          loading: () => Text(
                                            'Medale: …',
                                            style: theme.textTheme.labelMedium,
                                          ),
                                          error: (_, _) => Text(
                                            'Medale: błąd',
                                            style: theme.textTheme.labelMedium,
                                          ),
                                          data: (items) => Text(
                                            'Medale: ${items.fold<int>(0, (total, item) => total + item.earnedMedal)} z 36',
                                            style: theme.textTheme.labelMedium,
                                          ),
                                        ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.local_fire_department,
                                      size: 16,
                                      color: streakRewardsEarned > 0
                                          ? colors.streak
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Nagrody za passę: $streakRewardsEarned z ${streakRewards.length}',
                                      style: theme.textTheme.labelMedium,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
  }
}

/// Streak rewards of one continent: earned ones lit, the rest outlined.
class _StreakRewards extends ConsumerWidget {
  const _StreakRewards({required this.region});
  final Continent region;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(continentStreakProvider(region)).asData?.value;
    final earned = streak?.earnedRewards ?? const <int>[];
    final tokens = streak?.tokens ?? 0;
    final toNext = streak == null ? tokenEveryDays : streak.daysToNextToken;
    final colors = GeoColors.of(context);
    return Card.filled(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nagrody za passę',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${earned.length} z ${streakRewards.length} · '
              'rekord: ${daysLabel(streak?.best ?? 0)}',
            ),
            const SizedBox(height: 4),
            Semantics(
              label:
                  'Żetony Nieprzykunowanie: $tokens z $maxTokens. '
                  '${toNext == null ? 'Komplet.' : 'Następny za ${daysLabel(toNext)} passy.'}',
              excludeSemantics: true,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  const Text('Nieprzykunowanie:'),
                  for (var i = 0; i < tokens; i++) const TokenIcon(),
                  Text(
                    '$tokens z $maxTokens · '
                    '${toNext == null ? 'komplet' : 'następny za ${daysLabel(toNext)} passy'}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final days in streakRewards)
                  Semantics(
                    label:
                        '$days dni z rzędu: '
                        '${earned.contains(days) ? 'zdobyta' : 'jeszcze nie'}',
                    excludeSemantics: true,
                    child: Chip(
                      backgroundColor: earned.contains(days)
                          ? colors.triviaContainer
                          : null,
                      avatar: Icon(
                        earned.contains(days)
                            ? Icons.local_fire_department
                            : Icons.local_fire_department_outlined,
                        color: earned.contains(days)
                            ? colors.streak
                            : Theme.of(context).colorScheme.outline,
                      ),
                      label: Text('$days'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
