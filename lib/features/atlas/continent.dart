enum Continent {
  europe('Europa', 'Europy', 'Europie'),
  africa('Afryka', 'Afryki', 'Afryce'),
  asia('Azja', 'Azji', 'Azji');

  const Continent(this.label, this.genitive, this.journey);
  final String label;
  final String genitive;
  final String journey;

  String contentPath(String file) =>
      this == europe ? 'assets/content/$file' : 'assets/content/$name/$file';
}
