import 'dart:convert';

import 'continent.dart';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:latlong2/latlong.dart';

class Country {
  const Country(
    this.id,
    this.name,
    this.center,
    this.small, {
    required this.plural,
    String? questionName,
  }) : questionName = questionName ?? name;
  final String id;
  final String name;

  /// Name in the question, e.g. „województwo mazowieckie”, „stan Nowy Jork”.
  final String questionName;
  final LatLng center;
  final bool small;
  final bool plural;

  String get locationQuestion =>
      'Gdzie ${plural ? 'leżą' : 'leży'} $questionName?';
}

class CountryShape {
  const CountryShape(this.countryId, this.rings);
  final String countryId;
  final List<List<LatLng>> rings;
}

/// A framed inset with its own scale (Alaska, Hawaii), in map coordinates.
class InsetFrame {
  const InsetFrame(this.areaId, this.label, this.bounds);
  final String areaId;
  final String label;
  final LatLngBounds bounds;
}

/// Lightweight area metadata shared by [Catalog] and [CatalogMeta].
abstract interface class AreaCatalog {
  Continent get continent;
  String get version;
  List<Country> get countries;
  Country country(String id);
}

/// Cached countries metadata loaded from `countries.json` without parsing GeoJSON.
class CatalogMeta implements AreaCatalog {
  CatalogMeta(
    this.countries, {
    this.continent = Continent.europe,
    this.version = 'custom',
  });

  static final _cache = <Continent, Future<CatalogMeta>>{};

  @visibleForTesting
  static void clearCache() => _cache.clear();

  @override
  final Continent continent;
  @override
  final String version;
  @override
  final List<Country> countries;

  @override
  Country country(String id) => countries.firstWhere((c) => c.id == id);

  static Future<CatalogMeta> load({Continent continent = Continent.europe}) =>
      _cache[continent] ??= _loadUncached(continent);

  static Future<CatalogMeta> _loadUncached(Continent continent) async {
    final content = jsonDecode(
      await rootBundle.loadString(continent.contentPath('countries.json')),
    ) as Map<String, dynamic>;
    final countries = (content['countries'] as List).map((raw) {
      final c = raw as Map<String, dynamic>;
      return Country(
        c['id'] as String,
        c['name'] as String,
        LatLng(
          (c['latitude'] as num).toDouble(),
          (c['longitude'] as num).toDouble(),
        ),
        c['small'] as bool,
        plural: c['plural'] as bool,
        questionName: c['question_name'] as String?,
      );
    }).toList();
    return CatalogMeta(
      List.unmodifiable(countries),
      continent: continent,
      version: content['version'] as String,
    );
  }
}

class Catalog implements AreaCatalog {
  Catalog(
    this.countries,
    this.shapes, {
    this.continent = Continent.europe,
    this.version = 'custom',
    this.context = const [],
    this.insetFrames = const [],
  }) {
    if (countries.length != countries.map((c) => c.id).toSet().length ||
        countries.any((c) => !shapes.any((s) => s.countryId == c.id)) ||
        shapes.any((s) => !countries.any((c) => c.id == s.countryId))) {
      throw const FormatException('Niespójny katalog mapy');
    }
  }

  @override
  final Continent continent;
  @override
  final String version;
  @override
  final List<Country> countries;
  final List<CountryShape> shapes;

  /// Neutral land around the quiz countries (never selectable): polygons as
  /// rings, outer first.
  final List<List<List<LatLng>>> context;
  final List<InsetFrame> insetFrames;
  @override
  Country country(String id) => countries.firstWhere((c) => c.id == id);

  static Future<Catalog> load({Continent continent = Continent.europe}) async {
    final content = jsonDecode(
      await rootBundle.loadString(continent.contentPath('countries.json')),
    ) as Map<String, dynamic>;
    final geometry = jsonDecode(
      await rootBundle.loadString('assets/maps/${continent.name}.geojson'),
    ) as Map<String, dynamic>;
    final countries = (content['countries'] as List).map((raw) {
      final c = raw as Map<String, dynamic>;
      return Country(
        c['id'] as String,
        c['name'] as String,
        LatLng(
          (c['latitude'] as num).toDouble(),
          (c['longitude'] as num).toDouble(),
        ),
        c['small'] as bool,
        plural: c['plural'] as bool,
        questionName: c['question_name'] as String?,
      );
    }).toList();
    final shapes = <CountryShape>[];
    for (final feature in geometry['features'] as List) {
      for (final polygon in feature['geometry']['coordinates'] as List) {
        shapes.add(
          CountryShape(
            feature['id'] as String,
            (polygon as List)
                .map(
                  (ring) => (ring as List)
                      .map(
                        (point) => LatLng(
                          (point[1] as num).toDouble(),
                          (point[0] as num).toDouble(),
                        ),
                      )
                      .toList(),
                )
                .toList(),
          ),
        );
      }
    }
    final contextData = jsonDecode(
      await rootBundle.loadString(
        'assets/maps/context/${continent.name}.geojson',
      ),
    ) as Map<String, dynamic>;
    return Catalog(
      countries,
      shapes,
      continent: continent,
      version: content['version'] as String,
      insetFrames: [
        for (final f in (content['inset_frames'] as List?) ?? const [])
          InsetFrame(
            f['id'] as String,
            f['label'] as String,
            LatLngBounds(
              LatLng(
                (f['bounds_wsen'][1] as num).toDouble(),
                (f['bounds_wsen'][0] as num).toDouble(),
              ),
              LatLng(
                (f['bounds_wsen'][3] as num).toDouble(),
                (f['bounds_wsen'][2] as num).toDouble(),
              ),
            ),
          ),
      ],
      context: [
        for (final feature in contextData['features'] as List)
          for (final polygon in feature['geometry']['coordinates'] as List)
            [
              for (final ring in polygon as List)
                [
                  for (final point in ring as List)
                    LatLng(
                      (point[1] as num).toDouble(),
                      (point[0] as num).toDouble(),
                    ),
                ],
            ],
      ],
    );
  }
}
