import 'package:diacritic/diacritic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../atlas/continent.dart';
import '../learning/learning_progress.dart';
import '../learning/memory.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({
    super.key,
    this.continent,
    this.initialCountry,
    this.initialHardOnly = false,
  });
  final Continent? continent;
  final String? initialCountry;
  final bool initialHardOnly;
  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  late final _search = TextEditingController(text: widget.initialCountry);
  LearningProgressStatus? _status;
  late bool _hardOnly = widget.initialHardOnly;
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
    _hardOnly = false;
    _skill = 'all';
  });

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedContinentProvider);
    final continent = widget.continent ?? selected;
    final progressAsync = widget.continent != null
        ? ref.watch(continentProgressProvider(widget.continent!))
        : ref.watch(learningProgressProvider);
    return Scaffold(
      appBar: regionAppBar(
        context,
        continent: continent,
        title: 'Postępy · ${continent.label}',
      ),
      body: SafeArea(
        top: false,
        child: progressAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => LoadError(
            onRetry: () => ref.invalidate(
              widget.continent != null
                  ? continentProgressProvider(widget.continent!)
                  : learningProgressProvider,
            ),
          ),
          data: (entries) {
            final visible = entries
                .where(
                  (e) =>
                      (_status == null || e.status == _status) &&
                      (!_hardOnly || e.isHard) &&
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
            final hardCount = entries.where((e) => e.isHard).length;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _search,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: 'Szukaj ${continent.areaGenitive}',
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
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilterChip(
                                  label: const Text('Wszystkie'),
                                  selected: _status == null && !_hardOnly,
                                  showCheckmark: false,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.padded,
                                  onSelected: (_) => setState(() {
                                    _status = null;
                                    _hardOnly = false;
                                  }),
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
                                    onSelected: (selected) => setState(() {
                                      _status = selected ? status : null;
                                      if (selected) _hardOnly = false;
                                    }),
                                  ),
                                FilterChip(
                                  label: Text('Trudne: $hardCount'),
                                  selected: _hardOnly,
                                  showCheckmark: false,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.padded,
                                  onSelected: (selected) => setState(() {
                                    _hardOnly = selected;
                                    if (selected) _status = null;
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              key: ValueKey(_skill),
                              initialValue: _skill,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Umiejętność',
                                isDense: true,
                              ),
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
                          ],
                        ),
                      ),
                    ),
                    if (countries.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                                  '${skills.first.country.id}:$_status:$_hardOnly:$_skill:${_search.text}',
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
                                    _status != null ||
                                    _hardOnly,
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
  Widget build(BuildContext context) {
    final icon =
        entry.qualified && entry.status == LearningProgressStatus.practising
        ? Icons.verified_outlined
        : switch (entry.status) {
            LearningProgressStatus.review => Icons.replay,
            LearningProgressStatus.practising => Icons.school_outlined,
            LearningProgressStatus.insufficient => Icons.help_outline,
          };
    return ListTile(
      leading: Icon(icon),
      title: Text(entry.skillLabel),
      subtitle: Text(
        entry.reviewCount == 0
            ? 'Jeszcze niećwiczone'
            : [
                '${entry.status.label}${entry.qualified ? ' · Zaliczono' : ''}',
                if (entry.isHard)
                  'Trudne: ${entry.recoveryProgress} z $recoveryTarget trafień z rzędu',
                if (entry.due != null)
                  'Następna powtórka: ${_date(context, entry.due!)}',
                'Ocenione próby: ${entry.reviewCount}',
              ].join('\n'),
      ),
      isThreeLine: false,
    );
  }
}
