import 'package:material_ui/material_ui.dart';

/// GeoKuna design tokens. Material roles come from one forest-green seed on
/// warm paper; [GeoColors] holds the few app-specific roles Material lacks
/// (answer states, trivia, medals, streak). Map palettes live in
/// `map_style.dart`, because each map style has its own cartographic colours.
abstract final class GeoTheme {
  static const seed = Color(0xFF335C45);
  static const paper = Color(0xFFFAF8F0);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: seed, surface: paper);
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    // Type scale: Roboto (bundled, offline). Headings that carry the
    // question or a screen's subject are bold; app bar titles stay regular.
    final text = base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: paper,
      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontSize: 22,
          color: scheme.onSurface,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      extensions: const [GeoColors.light],
    );
  }
}

/// App-specific colour roles; read with `GeoColors.of(context)`.
@immutable
class GeoColors extends ThemeExtension<GeoColors> {
  const GeoColors({
    required this.correct,
    required this.correctContainer,
    required this.onCorrectContainer,
    required this.wrong,
    required this.wrongContainer,
    required this.onWrongContainer,
    required this.typoContainer,
    required this.onTypoContainer,
    required this.triviaContainer,
    required this.triviaBorder,
    required this.triviaIcon,
    required this.triviaTitle,
    required this.onTriviaContainer,
    required this.flagFrame,
    required this.flagFrameBorder,
    required this.speechBubble,
    required this.streak,
    required this.bronze,
    required this.silver,
    required this.gold,
    required this.brandMint,
  });

  static const light = GeoColors(
    correct: Color(0xFF2E7D57),
    correctContainer: Color(0xFFE2F1E5),
    onCorrectContainer: Color(0xFF185B2A),
    wrong: Color(0xFFA63A2B),
    wrongContainer: Color(0xFFFCE8E6),
    onWrongContainer: Color(0xFF8C1D18),
    typoContainer: Color(0xFFFFF1C2),
    onTypoContainer: Color(0xFF624700),
    triviaContainer: Color(0xFFFCF0CF),
    triviaBorder: Color(0xFFE5C46B),
    triviaIcon: Color(0xFFB07800),
    triviaTitle: Color(0xFF5C3F00),
    onTriviaContainer: Color(0xFF3B2F12),
    // Barely grey so white flag fields (Netherlands, Poland) stay visible.
    flagFrame: Color(0xFFE9E8E3),
    flagFrameBorder: Color(0xFF7C887E),
    speechBubble: Color(0xFFEFECE3),
    streak: Color(0xFFC25A00),
    bronze: Color(0xFF9A6339),
    silver: Color(0xFF6F777D),
    gold: Color(0xFF9A7420),
    // Launcher icon background (tools/build_icons.py) and the wordmark.
    brandMint: Color(0xFFD6EEDC),
  );

  final Color correct, correctContainer, onCorrectContainer;
  final Color wrong, wrongContainer, onWrongContainer;
  final Color typoContainer, onTypoContainer;
  final Color triviaContainer, triviaBorder, triviaIcon, triviaTitle;
  final Color onTriviaContainer;
  final Color flagFrame, flagFrameBorder, speechBubble, streak;
  final Color bronze, silver, gold, brandMint;

  static GeoColors of(BuildContext context) =>
      Theme.of(context).extension<GeoColors>() ?? light;

  /// Medal colour for 1–3, null when not earned.
  Color? medal(int level) => switch (level) {
    1 => bronze,
    2 => silver,
    3 => gold,
    _ => null,
  };

  @override
  GeoColors copyWith() => this;

  @override
  GeoColors lerp(GeoColors? other, double t) => t < .5 ? this : other ?? this;
}
