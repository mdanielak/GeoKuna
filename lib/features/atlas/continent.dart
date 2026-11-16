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

  // Words of the questions: countries, voivodeships (coats of arms, seats
  // of the regional authorities) or US states (flags, state capitals).
  bool get _poland => this == poland;
  bool get _usa => this == usa;

  /// „Wskaż to państwo”, „Wpisz całą nazwę województwa”.
  String get areaAccusative =>
      _poland ? 'województwo' : (_usa ? 'stan' : 'państwo');
  String get areaGenitive =>
      _poland ? 'województwa' : (_usa ? 'stanu' : 'państwa');

  /// Feedback label of the correct area: „Państwo: Czechy”.
  String get areaSubject =>
      _poland ? 'Województwo' : (_usa ? 'Stan' : 'Państwo');
  String get symbolsLabel => _poland ? 'Herby' : 'Flagi';
  String get symbolLabel => _poland ? 'Herb' : 'Flaga';
  String get symbolQuestion => _poland
      ? 'Którego województwa to herb?'
      : (_usa ? 'Którego stanu to flaga?' : 'Jakie to państwo?');
  String get capitalsLabel =>
      _poland ? 'Miasta wojewódzkie' : (_usa ? 'Stolice stanów' : 'Stolice');
  String get capitalSubject => _poland ? 'Miasto wojewódzkie' : 'Stolica';

  /// Short prompt under the area name in a capital question.
  String get capitalPrompt =>
      _poland ? 'Miasto wojewódzkie?' : (_usa ? 'Stolica stanu?' : 'Stolica?');

  /// Area of an id: voivodeship, US state or (all alike) a country.
  static Continent ofArea(String id) =>
      id.startsWith('PL-') ? poland : (id.startsWith('US-') ? usa : europe);

  String contentPath(String file) =>
      this == europe ? 'assets/content/$file' : 'assets/content/$name/$file';
}
