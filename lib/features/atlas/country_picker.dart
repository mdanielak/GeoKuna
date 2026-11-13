import 'package:diacritic/diacritic.dart';
import 'package:material_ui/material_ui.dart';

import 'catalog.dart';

/// Searchable, keyboard-friendly country list shared by the atlas and quiz.
class CountryPicker extends StatefulWidget {
  const CountryPicker({
    super.key,
    required this.catalog,
    required this.onSelected,
    this.selectedId,
  });

  final Catalog catalog;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  State<CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<CountryPicker> {
  final _searchController = TextEditingController();
  String _query = '';

  List<Country> get _filteredCountries {
    final query = _normalize(_query.trim());
    if (query.isEmpty) return widget.catalog.countries;
    return widget.catalog.countries
        .where((country) => _normalize(country.name).contains(query))
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countries = _filteredCountries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            labelText: 'Szukaj państwa',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Wyczyść wyszukiwanie',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close),
                  ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        if (countries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Nie znaleziono państwa. Zmień wyszukiwaną nazwę.',
              textAlign: TextAlign.center,
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: countries.length,
              itemBuilder: (context, index) {
                final country = countries[index];
                final selected = country.id == widget.selectedId;
                return Semantics(
                  selected: selected,
                  child: ListTile(
                    minTileHeight: 56,
                    selected: selected,
                    title: Text(country.name),
                    trailing: selected
                        ? const Icon(
                            Icons.check_circle,
                            semanticLabel: 'Wybrane',
                          )
                        : null,
                    onTap: () => widget.onSelected(country.id),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

String _normalize(String value) => removeDiacritics(value).toLowerCase();
