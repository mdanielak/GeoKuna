import '../settings/app_preferences.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app.dart';
import '../../app/providers.dart';
import '../atlas/country_map.dart';
import '../atlas/country_picker.dart';
import '../atlas/continent.dart';

class AtlasScreen extends ConsumerStatefulWidget {
  const AtlasScreen({super.key});
  @override
  ConsumerState<AtlasScreen> createState() => _AtlasScreenState();
}

class _AtlasScreenState extends ConsumerState<AtlasScreen> {
  String? _selected;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Atlas ${ref.watch(selectedContinentProvider).genitive}'),
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
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Dotknij państwa lub wybierz je z listy, aby je przybliżyć. '
                      'Dotknięcie blisko położonych znaczników przybliża mapę.',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * .52,
                      child: CountryMap(
                        catalog: catalog,
                        appearance:
                            ref
                                .watch(appPreferencesProvider)
                                .asData
                                ?.value
                                .appearance ??
                            MapAppearance.relief,
                        selectedId: selected,
                        focusId: selected,
                        onSelected: (id) => setState(() => _selected = id),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      selected == null
                          ? 'Dokąd dziś wyruszymy?'
                          : catalog.country(selected).name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 360,
                      child: CountryPicker(
                        catalog: catalog,
                        selectedId: selected,
                        onSelected: (id) => setState(() => _selected = id),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      catalog.continent == Continent.africa
                          ? 'Afryka: ${catalog.countries.length} państw. '
                                'Terytoria zależne nie są osobnymi zadaniami; '
                                'szczegóły granic i źródeł: dokumentacja Afryki.'
                          : catalog.continent == Continent.asia
                          ? 'Azja: ${catalog.countries.length} państw. '
                                'Szczegóły granic i źródeł: dokumentacja Azji.'
                          : catalog.continent == Continent.poland
                          ? 'Polska: 16 województw (Dz.U. 1998 nr 96 poz. 603). '
                                'Geometria: Natural Earth 1:10m, v5.1.2 · domena publiczna.'
                          : catalog.continent == Continent.usa
                          ? 'Stany Zjednoczone: 50 stanów; polskie nazwy według KSNG. '
                                'Alaska i Hawaje są pokazane we wstawkach w innej skali; '
                                'Dystrykt Kolumbii jest tłem mapy. Geometria: Natural Earth 1:10m.'
                          : catalog.continent != Continent.europe
                          ? '${catalog.continent.label}: '
                                '${catalog.countries.length} państw (lista KSNG). '
                                'Geometria: Natural Earth 1:50m. Terytoria zależne, '
                                'np. Grenlandia czy Portoryko, są tłem mapy.'
                          : 'Geometria: Natural Earth 1:50m, v5.1.2 · domena publiczna. '
                                '51 państw w szerokim zakresie edukacyjnym: Europa, Kosowo, Cypr, '
                                'Turcja, Gruzja, Armenia, Azerbejdżan i Kazachstan. '
                                'Mapa pokazuje europejski wycinek świata; odległe części państw '
                                'i terytoria zależne nie są osobnymi zadaniami. '
                                'Krym jest przypisany do Ukrainy, a północ Cypru do Cypru.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
  );
}
