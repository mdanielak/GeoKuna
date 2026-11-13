import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app.dart';
import '../../app/providers.dart';
import '../atlas/country_map.dart';

class AtlasScreen extends ConsumerStatefulWidget {
  const AtlasScreen({super.key});
  @override
  ConsumerState<AtlasScreen> createState() => _AtlasScreenState();
}

class _AtlasScreenState extends ConsumerState<AtlasScreen> {
  String? _selected;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Atlas Europy')),
    body: ref
        .watch(catalogProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              LoadError(onRetry: () => ref.invalidate(catalogProvider)),
          data: (catalog) => Center(
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
                      selectedId: _selected,
                      focusId: _selected,
                      onSelected: (id) => setState(() => _selected = id),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selected == null
                        ? 'Dokąd dziś wyruszymy?'
                        : catalog.country(_selected!).name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final country in catalog.countries)
                        ChoiceChip(
                          label: Text(country.name),
                          selected: _selected == country.id,
                          onSelected: (_) =>
                              setState(() => _selected = country.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Geometria: Natural Earth 1:50m, v5.1.2 · domena publiczna. '
                    '51 państw w szerokim zakresie edukacyjnym: Europa, Kosowo, Cypr, '
                    'Turcja, Gruzja, Armenia, Azerbejdżan i Kazachstan. '
                    'Mapa pokazuje europejski wycinek świata; odległe części państw '
                    'i terytoria zależne nie są osobnymi zadaniami. '
                    'Krym jest przypisany do Ukrainy, a północ Cypru do Cypru.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
  );
}
