enum Continent {
  europe('Europa', 'Europy', 'Europie'),
  africa('Afryka', 'Afryki', 'Afryce'),
  asia('Azja', 'Azji', 'Azji'),
  northAmerica('Ameryka Północna', 'Ameryki Północnej', 'Ameryce Północnej'),
  southAmerica(
    'Ameryka Południowa',
    'Ameryki Południowej',
    'Ameryce Południowej',
  ),

  /// Its map data uses longitudes shifted by 180° (tools: build_map.shift_lon),
  /// so the islands on both sides of the 180° meridian form one map.
  oceania('Australia i Oceania', 'Australii i Oceanii', 'Australii i Oceanii'),

  /// Voivodeships (ISO 3166-2 / TERYT ids `PL-02`…), map questions only.
  poland('Polska', 'Polski', 'Polsce', areaNoun: 'województw'),

  /// US states (`US-AL`…), Alaska and Hawaii as framed insets; map only.
  usa(
    'Stany Zjednoczone',
    'Stanów Zjednoczonych',
    'Stanach Zjednoczonych',
    areaNoun: 'stanów',
  );

  const Continent(
    this.label,
    this.genitive,
    this.journey, {
    this.areaNoun = 'państw',
  });
  final String label;
  final String genitive;
  final String journey;

  /// Genitive plural of what the map holds, e.g. „16 województw”.
  final String areaNoun;

  /// Countries have capital and flag packs; subdivisions are map-only
  /// until stage 2.
  bool get hasCapitalsAndFlags => this != poland && this != usa;

  String contentPath(String file) =>
      this == europe ? 'assets/content/$file' : 'assets/content/$name/$file';
}
