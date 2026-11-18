import 'package:diacritic/diacritic.dart';
import 'package:material_ui/material_ui.dart';

import 'catalog.dart';

/// Searchable, keyboard-friendly area list used in the Atlas.
/// When [scrollable] is false, renders items inline inside a card so an outer
/// page scroll view can scroll without nested gesture conflicts on mobile.
class CountryPicker extends StatefulWidget {
  const CountryPicker({
    super.key,
    required this.catalog,
    required this.onSelected,
    this.selectedId,
    this.scrollable = true,
  });

  final Catalog catalog;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final bool scrollable;

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

  Widget _tile(Country country) {
    final selected = country.id == widget.selectedId;
    return Semantics(
      selected: selected,
      child: ListTile(
        minTileHeight: 52,
        selected: selected,
        title: Text(
          country.name,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        trailing: selected
            ? const Icon(Icons.check_circle, semanticLabel: 'Wybrane')
            : const Icon(Icons.chevron_right, size: 18),
        onTap: () => widget.onSelected(country.id),
      ),
    );
  }

  Widget _emptyState() => Card.filled(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: Image.asset(
              'assets/v2/kuna_lupa.webp',
              width: 44,
              height: 44,
              cacheWidth: 132,
            ),
          ),
          const SizedBox(width: 12),
          const Flexible(
            child: Text('Nic nie znaleziono. Zmień wyszukiwaną nazwę.'),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final countries = _filteredCountries;
    return Column(
      mainAxisSize: widget.scrollable ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            labelText: 'Szukaj na mapie',
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
          ),
        ),
        const SizedBox(height: 10),
        if (countries.isEmpty)
          _emptyState()
        else if (widget.scrollable)
          Expanded(
            child: Card.filled(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                itemCount: countries.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) => _tile(countries[index]),
              ),
            ),
          )
        else
          Card.filled(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (index, country) in countries.indexed) ...[
                  if (index > 0) const Divider(height: 1),
                  _tile(country),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

String _normalize(String value) => removeDiacritics(value).toLowerCase();
