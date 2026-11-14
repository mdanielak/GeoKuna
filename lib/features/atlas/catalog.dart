import 'dart:convert';

import 'continent.dart';

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

class Country {
  const Country(
    this.id,
    this.name,
    this.center,
    this.small, {
    required this.plural,
  });
  final String id;
  final String name;
  final LatLng center;
  final bool small;
  final bool plural;

  String get locationQuestion => 'Gdzie ${plural ? 'leżą' : 'leży'} $name?';
}

class CountryShape {
  const CountryShape(this.countryId, this.rings);
  final String countryId;
  final List<List<LatLng>> rings;
}

class Catalog {
  Catalog(
    this.countries,
    this.shapes, {
    this.continent = Continent.europe,
    this.version = 'custom',
  }) {
    if (countries.length != countries.map((c) => c.id).toSet().length ||
        countries.any((c) => !shapes.any((s) => s.countryId == c.id)) ||
        shapes.any((s) => !countries.any((c) => c.id == s.countryId))) {
      throw const FormatException('Niespójny katalog mapy');
    }
  }

  final Continent continent;
  final String version;
  final List<Country> countries;
  final List<CountryShape> shapes;
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
    return Catalog(
      countries,
      shapes,
      continent: continent,
      version: content['version'] as String,
    );
  }
}
