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
  oceania('Australia i Oceania', 'Australii i Oceanii', 'Australii i Oceanii');

  const Continent(this.label, this.genitive, this.journey);
  final String label;
  final String genitive;
  final String journey;

  String contentPath(String file) =>
      this == europe ? 'assets/content/$file' : 'assets/content/$name/$file';
}
