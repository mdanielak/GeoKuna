import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';

/// Concise, plain-language guide to how GeoKuna schedules reviews, qualifies
/// countries, handles mistakes, awards medals and tracks streaks.
class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = GeoColors.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Jak działa GeoKuna?')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Card.filled(
                  margin: EdgeInsets.zero,
                  color: colors.triviaContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExcludeSemantics(
                          child: Image.asset(
                            'assets/v2/kuna_lupa.webp',
                            width: 56,
                            height: 56,
                            cacheWidth: 168,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Krótki przewodnik po nauce',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: colors.onTriviaContainer,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Nie pytamy w kółko o to, co już znasz — skupiamy się na trudnościach, a pewniaki sprawdzamy co jakiś czas.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onTriviaContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const _GuideSection(
                  icon: Icons.today_outlined,
                  title: 'Dzisiejsza wyprawa i powtórki',
                  paragraphs: [
                    'Każda wyprawa ma do 10 pytań. Najpierw wracają zaległe powtórki (trudne w pierwszej kolejności), a potem dochodzi do 3 nowych pytań dziennie wspólnie dla wszystkich obszarów.',
                    'Gdy zaległości jest dużo, zostawiamy miejsce na 1 nowe pytanie, aby nauka nie stanęła. Po ukończeniu planu możesz uruchomić „Kolejną rundę”, która dorzuca także pytania kontrolne z najsłabszych pewniaków.',
                    'Ręczny trening (Mapa, Stolice, Flagi i herby) jest zawsze dostępny i nie zużywa dziennego limitu nowości.',
                  ],
                ),
                const _GuideSection(
                  icon: Icons.verified_outlined,
                  title: 'Kiedy kraj jest zaliczony?',
                  paragraphs: [
                    'Zaliczony — po 2 poprawnych pierwszych odpowiedziach w różne dni, oddalonych o co najmniej 24 godziny i bez błędu pomiędzy nimi. Ten licznik widać na ekranie Dziś i w medalach.',
                    'W nauce — po pierwszej poprawnej odpowiedzi, gdy czekasz na kolejną powtórkę (jeśli od razu znasz odpowiedź na poziomie Normalnym, kolejna powtórka wypadnie za ok. 2 tygodnie).',
                    'Na bieżąco (w zakładce Moja nauka) — wszystkie umiejętności, na które odpowiedziano poprawnie i których termin powtórki jest w przyszłości. Gdy termin minie lub padnie błąd, trafiają do „Do powtórki”.',
                  ],
                ),
                const _GuideSection(
                  icon: Icons.psychology_outlined,
                  title: 'Błędy, trudne kraje i podpowiedzi',
                  paragraphs: [
                    'Błędne pytanie w Dzisiejszej wyprawie wraca po 3–5 innych pytaniach jako nieoceniana „powtórka błędu”.',
                    'Trudny kraj potrzebuje 3 ocenionych trafień z rzędu rozłożonych w czasie. Jeśli pomylisz go 2 razy, dostaniesz najpierw łatwiejszy krok „z podpowiedzią”, a przy często mylonych parach — oba miejsca do porównania jedno po drugim.',
                    'Na mapie masz do 3 prób (oceniane jest pierwsze wskazanie). Przy wpisywaniu akceptujemy jedną literówkę bez polskich znaków, a przycisk „Nie wiem, pomóż” pokazuje ćwiczenie A–D.',
                  ],
                ),
                const _GuideSection(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Poziomy trudności i medale',
                  paragraphs: [
                    'Każdy obszar ma osobny poziom: Bardzo łatwy (wybór A–D i bliski kadr), Łatwy (pierwsza litera i lekkie przybliżenie) oraz Normalny (samodzielne pisanie i pełna mapa).',
                    'Poziomy mają osobne powtórki — rozpoznawanie A–D nie zalicza samodzielnego pisania. Wyższy poziom zalicza jednak niższy na pasku postępu i w medalach.',
                    'Brązowy, srebrny i złoty medal zdobywasz po zaliczeniu 50%, 80% i 100% katalogu obszaru w danej kategorii. Zdobyte medale zostają na stałe.',
                  ],
                ),
                const _GuideSection(
                  icon: Icons.local_fire_department,
                  title: 'Passa i żetony Nieprzykunowanie',
                  paragraphs: [
                    'Każdy obszar ma własną passę dni z rzędu — liczy się od pierwszej zapisanej odpowiedzi danego dnia.',
                    'Za każde 7 dni passy zdobywasz 1 żeton Nieprzykunowanie (maksymalnie 3 na obszar). Jeśli opuścisz dzień, żeton może uratować passę przed przerwaniem.',
                    'Przerwa nie odbiera najlepszego rekordu ani zdobytych nagród za passę (od 3 do 90 dni).',
                  ],
                ),
                const _GuideSection(
                  icon: Icons.offline_pin_outlined,
                  title: 'Offline i kopia zapasowa',
                  paragraphs: [
                    'GeoKuna działa w pełni lokalnie na urządzeniu — bez konta, logowania i połączenia z siecią podczas nauki.',
                    'W Ustawieniach możesz zapisać całą naukę i ustawienia do pliku kopii zapasowej oraz wczytać je na innym urządzeniu.',
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.icon,
    required this.title,
    required this.paragraphs,
  });

  final IconData icon;
  final String title;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.filled(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < paragraphs.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              Text(paragraphs[i], style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
