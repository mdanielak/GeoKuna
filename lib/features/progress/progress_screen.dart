import 'package:diacritic/diacritic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../learning/learning_progress.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key, this.initialCountry});
  final String? initialCountry;
  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  late final _search = TextEditingController(text: widget.initialCountry);
  LearningProgressStatus? _status;
  String _skill = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _normalize(String value) =>
      removeDiacritics(value).toLowerCase().trim();

  void _clearFilters() => setState(() {
    _search.clear();
    _status = null;
    _skill = 'all';
  });

  @override
  Widget build(BuildContext context) {
    final continent = ref.watch(selectedContinentProvider);
    return Scaffold(
      appBar: regionAppBar(
        context,
        continent: continent,
        title: 'Postępy · ${continent.label}',
      ),
      body: SafeArea(
        top: false,
        child: ref
            .watch(learningProgressProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => LoadError(
                onRetry: () => ref.invalidate(learningProgressProvider),
              ),
              data: (entries) {
                final visible = entries
                    .where(
                      (e) =>
                          (_status == null || e.status == _status) &&
                          (_skill == 'all' || e.skillKey == _skill) &&
                          _normalize(e.country.name)
                              .contains(_normalize(_search.text)),
                    )
                    .toList();
                final groups = <String, List<LearningProgressEntry>>{};
                for (final entry in visible) {
                  groups.putIfAbsent(entry.country.id, () => []).add(entry);
                }
                final countries = groups.values.toList();
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: CustomScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Każda umiejętność osobno',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Każdy poziom ma własne powtórki. A–D ćwiczy rozpoznawanie; nie zalicza samodzielnego wpisywania. Historyczne odpowiedzi z pomocą nie oceniają pamięci.',
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    FilterChip(
                                      label: const Text('Wszystkie'),
                                      selected: _status == null,
                                      showCheckmark: false,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.padded,
                                      onSelected: (_) =>
                                          setState(() => _status = null),
                                    ),
                                    for (final status
                                        in LearningProgressStatus.values)
                                      FilterChip(
                                        label: Text(
                                          '${status.label}: ${entries.where((e) => e.status == status).length}',
                                        ),
                                        selected: _status == status,
                                        showCheckmark: false,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.padded,
                                        onSelected: (selected) => setState(
                                          () => _status = selected
                                              ? status
                                              : null,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Umiejętność',
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _skill,
                                      isExpanded: true,
                                      items: [
                                        const DropdownMenuItem(
                                          value: 'all',
                                          child: Text('Wszystkie'),
                                        ),
                                        for (final skill in <String, String>{
                                          for (final entry in entries)
                                            entry.skillKey: entry.skillLabel,
                                        }.entries)
                                          DropdownMenuItem(
                                            value: skill.key,
                                            child: Text(skill.value),
                                          ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() => _skill = value);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _search,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    labelText:
                                        'Szukaj ${continent.areaGenitive} w postępach',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: _search.text.isEmpty
                                        ? null
                                        : IconButton(
                                            tooltip: 'Wyczyść wyszukiwanie',
                                            icon: const Icon(Icons.clear),
                                            onPressed: () =>
                                                setState(_search.clear),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Rozwiń ${continent.areaAccusative}, aby zobaczyć umiejętności. „Do powtórki” obejmuje także ostatni błąd, nawet gdy termin jeszcze nie nadszedł.',
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (countries.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              child: Card.filled(
                                margin: EdgeInsets.zero,
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      ExcludeSemantics(
                                        child: Image.asset(
                                          'assets/v2/kuna_lupa.webp',
                                          width: 56,
                                          height: 56,
                                          cacheWidth: 168,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Brak umiejętności pasujących do filtrów.',
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      OutlinedButton(
                                        onPressed: _clearFilters,
                                        child: const Text('Wyczyść filtry'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          sliver: SliverList.builder(
                            itemCount: countries.length,
                            itemBuilder: (context, i) {
                              final skills = countries[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Card.filled(
                                  margin: EdgeInsets.zero,
                                  clipBehavior: Clip.antiAlias,
                                  child: ExpansionTile(
                                    key: ValueKey(
                                      '${skills.first.country.id}:$_status:$_skill:${_search.text}',
                                    ),
                                    title: Text(
                                      skills.first.country.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      skills
                                          .map((e) => e.status)
                                          .toSet()
                                          .map((s) => s.label)
                                          .join(' · '),
                                    ),
                                    initiallyExpanded:
                                        _search.text.isNotEmpty ||
                                        _status != null,
                                    children: [
                                      for (final entry in skills)
                                        _SkillProgress(entry: entry),
                                    ],
                                  ),
                                ),
                              );
                            },
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
}

class _SkillProgress extends StatelessWidget {
  const _SkillProgress({required this.entry});
  final LearningProgressEntry entry;

  String _date(BuildContext context, DateTime date) {
    final local = date.toLocal();
    final l10n = MaterialLocalizations.of(context);
    return '${l10n.formatMediumDate(local)}, ${l10n.formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: true)}';
  }

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(switch (entry.status) {
      LearningProgressStatus.review => Icons.replay,
      LearningProgressStatus.practising => Icons.school_outlined,
      LearningProgressStatus.insufficient => Icons.help_outline,
    }),
    title: Text(entry.skillLabel),
    subtitle: Text(
      [
        entry.status.label,
        if (entry.reviewCount == 0) 'Brak ocenianych odpowiedzi.',
        if (entry.reviewCount > 0) 'Ocenione próby: ${entry.reviewCount}',
        if (entry.lastReview != null)
          'Ostatnia ocena: ${_date(context, entry.lastReview!)}',
        if (entry.due != null) 'Termin: ${_date(context, entry.due!)}',
      ].join('\n'),
    ),
    isThreeLine: false,
  );
}
