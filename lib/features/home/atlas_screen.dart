import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../atlas/catalog.dart';
import '../atlas/continent.dart';
import '../atlas/continent_chips.dart';
import '../atlas/country_map.dart';
import '../atlas/country_picker.dart';
import '../learning/widgets/quiz_shared_widgets.dart';
import '../settings/app_preferences.dart';

class AtlasScreen extends ConsumerStatefulWidget {
  const AtlasScreen({super.key});
  @override
  ConsumerState<AtlasScreen> createState() => _AtlasScreenState();
}

class _AtlasScreenState extends ConsumerState<AtlasScreen> {
  final _scrollController = ScrollController();
  String? _selected;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _selectFromList(String id, {required bool scrollToTop}) {
    setState(() => _selected = id);
    if (scrollToTop &&
        _scrollController.hasClients &&
        _scrollController.offset > 24) {
      final disableAnimations = MediaQuery.disableAnimationsOf(context);
      _scrollController.animateTo(
        0,
        duration: disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final continent = ref.watch(selectedContinentProvider);
    final appearance =
        ref.watch(appPreferencesProvider).asData?.value.appearance ??
        MapAppearance.relief;
    return Scaffold(
      appBar: regionAppBar(
        context,
        continent: continent,
        title: 'Atlas ${continent.genitive}',
      ),
      body: ref
          .watch(catalogProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                LoadError(onRetry: () => ref.invalidate(catalogProvider)),
            data: (catalog) {
              // A selection from another continent (e.g. 'HUN' after switching
              // to the voivodeships) does not exist in this catalog.
              final selected = catalog.countries.any((c) => c.id == _selected)
                  ? _selected
                  : null;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final wide =
                      constraints.maxWidth >= 780 &&
                      constraints.maxHeight >= 520;
                  if (wide) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ContinentChips(continent: continent),
                              const SizedBox(height: 14),
                              Expanded(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 6,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: CountryMap(
                                              catalog: catalog,
                                              appearance: appearance,
                                              selectedId: selected,
                                              focusId: selected,
                                              onSelected: (id) => setState(
                                                () => _selected = id,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            _sourceNote(catalog),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      flex: 5,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          _selectionHeader(
                                            context,
                                            catalog,
                                            selected,
                                          ),
                                          const SizedBox(height: 12),
                                          Expanded(
                                            child: CountryPicker(
                                              catalog: catalog,
                                              selectedId: selected,
                                              onSelected: (id) => setState(
                                                () => _selected = id,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final mapHeight = (constraints.maxHeight * .45).clamp(
                    220.0,
                    420.0,
                  );
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        children: [
                          ContinentChips(continent: continent),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: mapHeight,
                            child: CountryMap(
                              catalog: catalog,
                              appearance: appearance,
                              selectedId: selected,
                              focusId: selected,
                              onSelected: (id) =>
                                  setState(() => _selected = id),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _selectionHeader(context, catalog, selected),
                          const SizedBox(height: 14),
                          CountryPicker(
                            catalog: catalog,
                            selectedId: selected,
                            scrollable: false,
                            onSelected: (id) =>
                                _selectFromList(id, scrollToTop: true),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _sourceNote(catalog),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
    );
  }

  Widget _selectionHeader(
    BuildContext context,
    Catalog catalog,
    String? selected,
  ) {
    if (selected != null) {
      return _SelectedAreaCard(catalog: catalog, areaId: selected);
    }
    final continent = catalog.continent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dokąd dziś wyruszymy?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Dotknij ${continent.areaGenitive} na mapie lub wybierz z listy poniżej.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Compact area fact sheet shown in the Atlas when a country, state or
/// voivodeship is selected: symbol/flag, name, capital/seat and local facts.
class _SelectedAreaCard extends ConsumerStatefulWidget {
  const _SelectedAreaCard({required this.catalog, required this.areaId});
  final Catalog catalog;
  final String areaId;

  @override
  ConsumerState<_SelectedAreaCard> createState() => _SelectedAreaCardState();
}

class _SelectedAreaCardState extends ConsumerState<_SelectedAreaCard> {
  int _triviaIndex = 0;

  @override
  void didUpdateWidget(_SelectedAreaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.areaId != widget.areaId) {
      _triviaIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final areaId = widget.areaId;
    final area = widget.catalog.country(areaId);
    final theme = Theme.of(context);
    final continent = widget.catalog.continent;
    final capital = ref
        .watch(capitalsProvider)
        .asData
        ?.value
        .facts
        .where((f) => f.countryId == areaId)
        .firstOrNull;
    final flag = ref
        .watch(flagsProvider)
        .asData
        ?.value
        .facts
        .where((f) => f.countryId == areaId)
        .firstOrNull;
    final facts =
        ref.watch(countryTriviaProvider).asData?.value.factsFor(areaId) ??
        const [];
    final fact = facts.isEmpty ? null : facts[_triviaIndex % facts.length];

    return Card.filled(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (flag != null) ...[
                  FlagFrame(
                    assetPath: flag.assetPath,
                    semanticLabel: '${continent.symbolLabel}: ${area.name}',
                    width: 68,
                    height: 48,
                    padding: 4,
                    borderRadius: 10,
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(area.name, style: theme.textTheme.headlineSmall),
                      if (capital != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${continent.capitalSubject}: ${capital.name}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (capital != null && capital.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(capital.note, style: theme.textTheme.bodySmall),
            ],
            if (fact != null) ...[
              const SizedBox(height: 12),
              TriviaCard(text: fact.text, compact: true),
              if (facts.length > 1)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 40),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => setState(() => _triviaIndex++),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(
                      'Kolejna ciekawostka (${(_triviaIndex % facts.length) + 1}/${facts.length})',
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

String _sourceNote(Catalog catalog) => switch (catalog.continent) {
  Continent.africa =>
    'Afryka: ${catalog.countries.length} państw ONZ (lista KSNG). '
        'Terytoria zależne i Sahara Zachodnia są tłem mapy. '
        'Geometria: Natural Earth 1:50m, v5.1.2 · domena publiczna.',
  Continent.asia =>
    'Azja: ${catalog.countries.length} obszarów (państwa ONZ oraz Palestyna '
        'i Tajwan według KSNG; Cypr i Turcja wspólne z Europą). '
        'Geometria: Natural Earth 1:50m, v5.1.2 · domena publiczna.',
  Continent.poland =>
    'Polska: 16 województw (Dz.U. 1998 nr 96 poz. 603). '
        'Geometria: Natural Earth 1:10m, v5.1.2 · domena publiczna.',
  Continent.usa =>
    'Stany Zjednoczone: 50 stanów; polskie nazwy według KSNG. '
        'Alaska i Hawaje są pokazane we wstawkach w innej skali; '
        'Dystrykt Kolumbii jest tłem mapy. Geometria: Natural Earth 1:10m.',
  Continent.europe =>
    'Europa: ${catalog.countries.length} państw (państwa europejskie, Kosowo '
        'oraz wspólne z Azją Cypr i Turcja; Kaukaz i Kazachstan są lądem '
        'kontekstowym). Geometria: Natural Earth 1:50m, v5.1.2 · domena '
        'publiczna. Krym jest przypisany do Ukrainy, a północ Cypru do Cypru.',
  _ =>
    '${catalog.continent.label}: ${catalog.countries.length} państw (lista KSNG). '
        'Geometria: Natural Earth 1:50m. Terytoria zależne, '
        'np. Grenlandia czy Portoryko, są tłem mapy.',
};
