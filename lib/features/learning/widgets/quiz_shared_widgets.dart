import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';

/// Country/flag/capital fact card with the kuna-with-loupe badge.
class TriviaCard extends StatelessWidget {
  const TriviaCard({super.key, required this.text, this.compact = false});
  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = GeoColors.of(context);
    final imageSize = compact ? 40.0 : 52.0;
    return Semantics(
      container: true,
      label: 'Ciekawostka: $text',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.triviaContainer,
          borderRadius: BorderRadius.circular(compact ? 14 : 16),
          border: Border.all(color: colors.triviaBorder),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 10 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/v2/kuna_lupa.webp',
                width: imageSize,
                height: imageSize,
                cacheWidth: compact ? 120 : 156,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: compact
                    ? Text(
                        text,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colors.onTriviaContainer),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ciekawostka',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.triviaTitle,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            text,
                            style: TextStyle(color: colors.onTriviaContainer),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Flag/coat-of-arms frame with subtle grey fill so white fields stay visible.
class FlagFrame extends StatelessWidget {
  const FlagFrame({
    super.key,
    required this.assetPath,
    required this.semanticLabel,
    this.width,
    this.height = 156,
    this.padding = 8,
    this.borderRadius = 12,
  });

  final String assetPath;
  final String semanticLabel;
  final double? width;
  final double height;
  final double padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = GeoColors.of(context);
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colors.flagFrame,
        border: Border.all(color: colors.flagFrameBorder),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        semanticLabel: semanticLabel,
      ),
    );
  }
}

/// Outlined A–D radio card list shared between choice questions and practice.
class ChoiceOptionList extends StatelessWidget {
  const ChoiceOptionList({
    super.key,
    required this.options,
    required this.selected,
    required this.enabled,
    required this.onChanged,
    this.boldSelected = false,
  });

  final List<String> options;
  final String? selected;
  final bool enabled;
  final ValueChanged<String?> onChanged;
  final bool boldSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RadioGroup<String>(
      groupValue: selected,
      onChanged: onChanged,
      child: Column(
        children: [
          for (var i = 0; i < options.length; i++)
            Card.filled(
              margin: const EdgeInsets.only(bottom: 10),
              color: selected == options[i]
                  ? scheme.primaryContainer.withValues(alpha: .45)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: selected == options[i]
                      ? scheme.primary
                      : GeoTheme.border,
                  width: selected == options[i] ? 2 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: RadioListTile<String>(
                value: options[i],
                enabled: enabled,
                title: Text(
                  '${String.fromCharCode(65 + i)}. ${options[i]}',
                  style: boldSelected
                      ? TextStyle(
                          fontWeight: selected == options[i]
                              ? FontWeight.w700
                              : FontWeight.w500,
                        )
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Explains typo tolerance and diacritic normalization in written questions.
Future<void> showAnswerRulesDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: const Text('Jak sprawdzamy odpowiedzi?'),
    content: const Text(
      'Przy wpisywaniu akceptujemy jedną literówkę: zamianę, pominięcie, dodanie litery lub przestawienie dwóch sąsiednich liter. Wielkość liter i znaki diakrytyczne nie wpływają na wynik.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(),
        child: const Text('Rozumiem'),
      ),
    ],
  ),
);

/// Compact badge shown on questions temporarily served at an easier tier
/// in Automatyczny mode. [countryName] must be omitted on flag questions.
class AutoEasierChip extends StatelessWidget {
  const AutoEasierChip({super.key, this.countryName});
  final String? countryName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = countryName == null ? 'Łatwiej' : 'Łatwiej: $countryName';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
