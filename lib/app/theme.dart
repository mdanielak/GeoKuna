import 'package:material_ui/material_ui.dart';

/// GeoKuna design tokens (look v2: GeoKuna_Production_v2_1
/// `design/color_tokens.json`). Material roles come from the brand green on
/// cream paper; [GeoColors] holds the few app-specific roles Material lacks
/// (answer states, trivia, streak). Map palettes live in
/// `map_style.dart`, because each map style has its own cartographic colours.
abstract final class GeoTheme {
  static const seed = Color(0xFF0B6B3A);
  static const paper = Color(0xFFFFF9E9);
  static const ink = Color(0xFF0F3D27);
  static const border = Color(0xFFCFE4B2);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      surface: paper,
    ).copyWith(primary: seed, onSurface: ink, outlineVariant: border);
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
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(side: BorderSide(color: border)),
        backgroundColor: const Color(0xFFFFFDF5),
        selectedColor: seed,
        secondarySelectedColor: seed,
        labelStyle: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: WidgetStateColor.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? Colors.white : ink,
          ),
        ),
      ),
      // Compact bottom bar: icons and labels, without the tall M3 default.
      navigationBarTheme: NavigationBarThemeData(
        height: 56,
        backgroundColor: const Color(0xFFF6EFD9),
        indicatorColor: const Color(0xFFDDEFC6),
        labelPadding: const EdgeInsets.only(top: 2),
        labelTextStyle: WidgetStatePropertyAll(
          base.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
        iconTheme: const WidgetStatePropertyAll(
          IconThemeData(size: 22, color: ink),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF6DB33F),
        linearTrackColor: Color(0xFFE9E4D2),
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
    required this.triviaTitle,
    required this.onTriviaContainer,
    required this.flagFrame,
    required this.flagFrameBorder,
    required this.speechBubble,
    required this.streak,
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
    triviaTitle: Color(0xFF5C3F00),
    onTriviaContainer: Color(0xFF3B2F12),
    // Barely grey so white flag fields (Netherlands, Poland) stay visible.
    flagFrame: Color(0xFFE9E8E3),
    flagFrameBorder: Color(0xFF7C887E),
    speechBubble: Color(0xFFEFECE3),
    streak: Color(0xFFC25A00),
  );

  final Color correct, correctContainer, onCorrectContainer;
  final Color wrong, wrongContainer, onWrongContainer;
  final Color typoContainer, onTypoContainer;
  final Color triviaContainer, triviaBorder, triviaTitle;
  final Color onTriviaContainer;
  final Color flagFrame, flagFrameBorder, speechBubble, streak;

  static GeoColors of(BuildContext context) =>
      Theme.of(context).extension<GeoColors>() ?? light;

  @override
  GeoColors copyWith() => this;

  @override
  GeoColors lerp(GeoColors? other, double t) => t < .5 ? this : other ?? this;
}
