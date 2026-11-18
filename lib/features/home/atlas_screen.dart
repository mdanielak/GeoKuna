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
import '../settings/app_preferences.dart';

class AtlasScreen extends ConsumerStatefulWidget {
  const AtlasScreen({super.key});
  @override
  ConsumerState<AtlasScreen> createState() => _AtlasScreenState();
}

class _AtlasScreenState extends ConsumerState<AtlasScreen> {
  String? _selected;

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
                            onSelected: (id) => setState(() => _selected = id),
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
/// voivodeship is selected: symbol/flag, name, capital/seat and one local fact.
class _SelectedAreaCard extends ConsumerWidget {
  const _SelectedAreaCard({required this.catalog, required this.areaId});
  final Catalog catalog;
  final String areaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final area = catalog.country(areaId);
    final colors = GeoColors.of(context);
    final theme = Theme.of(context);
    final continent = catalog.continent;
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
    final trivia = ref
        .watch(countryTriviaProvider)
        .asData
        ?.value
        .pick(areaId, seed: 'atlas:$areaId');

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
                  Container(
                    width: 68,
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors.flagFrame,
                      border: Border.all(color: colors.flagFrameBorder),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      flag.assetPath,
                      fit: BoxFit.contain,
                      semanticLabel: '${continent.symbolLabel}: ${area.name}',
                    ),
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
            if (trivia != null) ...[
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.triviaContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.triviaBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/v2/kuna_lupa.webp',
                        width: 40,
                        height: 40,
                        cacheWidth: 120,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          trivia.text,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onTriviaContainer,
                          ),
                        ),
                      ),
                    ],
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
    'Afryka: ${catalog.countries.length} państw. '
        'Terytoria zależne nie są osobnymi zadaniami; '
        'szczegóły granic i źródeł: dokumentacja Afryki.',
  Continent.asia =>
    'Azja: ${catalog.countries.length} państw. '
        'Szczegóły granic i źródeł: dokumentacja Azji.',
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
