import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../atlas/continent.dart';
import '../learning/achievements.dart';
import '../learning/learning_progress.dart';
import '../learning/streaks.dart';
import '../learning/token_icon.dart';
import '../settings/app_preferences.dart';

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
  int get hard => entries.where((e) => e.isHard).length;
  int get qualified => entries.where((e) => e.qualified).length;
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
        ? AppBar(
            title: const Text('Moja nauka'),
            actions: [
              IconButton(
                tooltip: 'Jak to działa?',
                onPressed: () => context.push('/how-it-works'),
                icon: const Icon(Icons.help_outline),
              ),
            ],
          )
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
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
          final level =
              ref
                  .watch(appPreferencesProvider)
                  .asData
                  ?.value
                  .difficultyFor(region) ??
              LearningDifficulty.normal;
          final levelEntries = effectiveEntriesForLevel(entries, level);
          final areaSummary = KnowledgeSummary(levelEntries);
          final groups = <String, List<LearningProgressEntry>>{};
          for (final entry in levelEntries) {
            groups.putIfAbsent(entry.country.id, () => []).add(entry);
          }
          final countries = groups.values.toList()
            ..sort((a, b) {
              final x = KnowledgeSummary(a), y = KnowledgeSummary(b);
              final hard = y.hard.compareTo(x.hard);
              if (hard != 0) return hard;
              final review = y.review.compareTo(x.review);
              if (review != 0) return review;
              final percentage = x.percent.compareTo(y.percent);
              return percentage != 0
                  ? percentage
                  : a.first.country.name.compareTo(b.first.country.name);
            });
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _RegionSummaryCard(
                region: region,
                level: level,
                summary: areaSummary,
              ),
              const SizedBox(height: 12),
              _medalsSection(ref, region),
              const SizedBox(height: 12),
              _StreakRewards(region: region),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    '${region.label} (${countries.length})',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () => context.push(
                      Uri(
                        path: '/progress',
                        queryParameters: {'continent': region.name},
                      ).toString(),
                    ),
                    child: const Text('Wszystkie umiejętności'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
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
                            minTileHeight: 56,
                            title: Text(
                              country.first.country.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(_countryStatus(summary)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${summary.percent}%',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () {
                              context.push(
                                Uri(
                                  path: '/progress',
                                  queryParameters: {
                                    'continent': region.name,
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
          final earned = achievements.fold<int>(
            0,
            (total, item) => total + item.earnedMedal,
          );
          return Card.filled(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('Medale za naukę'),
              subtitle: Text(
                '$earned z $maxMedalPoints zdobytych · progi 50%, 80% i 100%',
              ),
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

String _countryStatus(KnowledgeSummary summary) {
  if (summary.hard > 0 && summary.review > 0) {
    return 'Trudne · Do powtórki: ${summary.review}';
  }
  if (summary.hard > 0) {
    return 'Trudne · Na bieżąco: ${summary.ready}/${summary.entries.length}';
  }
  if (summary.review > 0) return 'Do powtórki: ${summary.review}';
  if (summary.entries.isNotEmpty && summary.ready == summary.entries.length) {
    return 'Wszystko na bieżąco';
  }
  if (summary.ready > 0) {
    return 'Na bieżąco: ${summary.ready}/${summary.entries.length}';
  }
  return 'Jeszcze niećwiczone';
}

class _RegionSummaryCard extends ConsumerWidget {
  const _RegionSummaryCard({
    required this.region,
    required this.level,
    required this.summary,
  });

  final Continent region;
  final LearningDifficulty level;
  final KnowledgeSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final map = ref
        .watch(continentAchievementsProvider(region))
        .asData
        ?.value
        .where((a) => a.topic == 'map' && a.level == level)
        .firstOrNull;
    return Card.filled(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(label: Text('Poziom: ${level.label}')),
            if (map != null && map.totalCount > 0)
              Chip(
                label: Text(
                  'Mapa: ${map.qualifiedCount}/${map.totalCount} zaliczonych',
                ),
              ),
            Chip(label: Text('Na bieżąco: ${summary.percent}%')),
            if (summary.review > 0)
              Chip(label: Text('Do powtórki: ${summary.review}')),
            if (summary.hard > 0)
              ActionChip(
                avatar: const Icon(Icons.warning_amber_rounded, size: 18),
                label: Text('Trudne: ${summary.hard}'),
                onPressed: () => context.push(
                  Uri(
                    path: '/progress',
                    queryParameters: {'continent': region.name, 'hard': '1'},
                  ).toString(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Look v2 region progress card with miniature, dual progress bar (map
/// qualified + practice on track), medals and streak summary.
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
            final level =
                ref
                    .watch(appPreferencesProvider)
                    .asData
                    ?.value
                    .difficultyFor(region) ??
                LearningDifficulty.normal;
            final summary = KnowledgeSummary(
              effectiveEntriesForLevel(entries, level),
            );
            final achievements = ref
                .watch(continentAchievementsProvider(region))
                .asData
                ?.value;
            final map = achievements
                ?.where((a) => a.topic == 'map' && a.level == level)
                .firstOrNull;
            final earned = achievements?.fold<int>(
              0,
              (total, item) => total + item.earnedMedal,
            );
            final streak = ref
                .watch(continentStreakProvider(region))
                .asData
                ?.value;
            final streakRewardsEarned = streak?.earnedRewards.length ?? 0;
            final practisingRatio = (summary.percent / 100).clamp(0.0, 1.0);
            final qualifiedRatio = map != null && map.totalCount > 0
                ? (map.qualifiedCount / map.totalCount).clamp(0.0, 1.0)
                : 0.0;
            final statusParts = [
              if (map != null && map.totalCount > 0)
                'Mapa: ${map.qualifiedCount}/${map.totalCount} zaliczonych',
              'Na bieżąco ${summary.percent}%',
              if (summary.review > 0) 'Do powtórki: ${summary.review}',
              if (summary.hard > 0) 'Trudne: ${summary.hard}',
            ];

            return Card.filled(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/learning/${region.name}'),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 56,
                            height: 64,
                            child: Image(
                              image: ResizeImage(
                                AssetImage(
                                  'assets/v2/banner_${region.artId}_1.webp',
                                ),
                                width: 168,
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
                                  child: Wrap(
                                    spacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        region.label,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      Text(
                                        level.label,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 22),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                height: 6,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ColoredBox(
                                      color: GeoTheme.border.withValues(
                                        alpha: .55,
                                      ),
                                    ),
                                    if (practisingRatio > 0)
                                      FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: practisingRatio,
                                        child: ColoredBox(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: .35),
                                        ),
                                      ),
                                    if (qualifiedRatio > 0)
                                      FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: qualifiedRatio,
                                        child: ColoredBox(
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              statusParts.join(' · '),
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Semantics(
                                  label: earned == null
                                      ? 'Medale: ładowanie'
                                      : 'Medale: $earned z $maxMedalPoints',
                                  excludeSemantics: true,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.workspace_premium_outlined,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          earned == null
                                              ? '…'
                                              : '$earned/$maxMedalPoints',
                                          style: theme.textTheme.labelMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Semantics(
                                  label:
                                      'Nagrody za passę: $streakRewardsEarned z ${streakRewards.length}'
                                      '${(streak?.current ?? 0) > 0 ? ', aktualna passa ${daysLabel(streak!.current)}' : ''}',
                                  excludeSemantics: true,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.local_fire_department,
                                        size: 16,
                                        color:
                                            streakRewardsEarned > 0 ||
                                                (streak?.current ?? 0) > 0
                                            ? colors.streak
                                            : theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          '$streakRewardsEarned/${streakRewards.length}'
                                          '${(streak?.current ?? 0) > 0 ? ' · ${daysLabel(streak!.current)}' : ''}',
                                          style: theme.textTheme.labelMedium,
                                        ),
                                      ),
                                    ],
                                  ),
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

/// Streak rewards of one continent as a collapsible panel matching medals.
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
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(
          Icons.local_fire_department,
          color: earned.isNotEmpty || (streak?.current ?? 0) > 0
              ? colors.streak
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: const Text('Passa i nagrody'),
        subtitle: Text(
          'Rekord: ${daysLabel(streak?.best ?? 0)} · '
          'Nagrody: ${earned.length}/${streakRewards.length} · '
          'Żetony: $tokens/$maxTokens',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
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
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
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
          ),
        ],
      ),
    );
  }
}
