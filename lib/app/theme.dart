import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../features/atlas/continent.dart';

/// GeoKuna design tokens (look v2: GeoKuna_Production_v2_1
/// `design/color_tokens.json`). Material roles come from the brand green on
/// cream paper; [GeoColors] holds the few app-specific roles Material lacks
/// (answer states, trivia, streak). Map palettes live in
/// `map_style.dart`, because each map style has its own cartographic colours.
abstract final class GeoTheme {
  static const systemOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: paper,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

  static const seed = Color(0xFF0B6B3A);
  static const paper = Color(0xFFFFF9E9);
  static const ivory = Color(0xFFFFFDF6);
  static const creamCard = Color(0xFFF6EFD9);
  static const creamElevated = Color(0xFFFCF5E1);
  static const ink = Color(0xFF0F3D27);
  static const mutedInk = Color(0xFF3A5745);
  static const border = Color(0xFFCFE4B2);
  static const bannerScrim = Color(0x59082616);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: seed, surface: paper)
        .copyWith(
          primary: seed,
          onSurface: ink,
          onSurfaceVariant: mutedInk,
          outline: const Color(0xFF8AA878),
          outlineVariant: border,
          surfaceContainerLowest: ivory,
          surfaceContainerLow: creamElevated,
          surfaceContainer: creamCard,
          surfaceContainerHigh: creamCard,
          surfaceContainerHighest: creamCard,
        );
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
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: systemOverlayStyle,
        centerTitle: false,
        iconTheme: const IconThemeData(color: ink),
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ivory,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ivory,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border.withValues(alpha: .7),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ivory,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(side: BorderSide(color: border)),
        backgroundColor: ivory,
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
        backgroundColor: creamCard,
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
        linearTrackColor: Color(0xFFE5DEC8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      extensions: const [GeoColors.light],
    );
  }
}

/// AppBar with the region's v2 landscape banner and a warm left paper fade so
/// the back button and title stay legible at any text size.
AppBar regionAppBar(
  BuildContext context, {
  required Continent continent,
  required String title,
  List<Widget> actions = const [],
}) => AppBar(
  toolbarHeight: 52,
  systemOverlayStyle: GeoTheme.systemOverlayStyle,
  flexibleSpace: ExcludeSemantics(
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/v2/quiz_header_${continent.artId}.webp',
          fit: BoxFit.cover,
          alignment: Alignment.bottomRight,
          cacheWidth: 1080,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              stops: const [0, .58, .92],
              colors: [
                GeoTheme.paper.withValues(alpha: .96),
                GeoTheme.paper.withValues(alpha: .88),
                GeoTheme.paper.withValues(alpha: .15),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, .42],
              colors: [
                GeoTheme.paper.withValues(alpha: .7),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    ),
  ),
  title: Text(
    title,
    style: Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.w700),
  ),
  actions: actions,
);

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
    speechBubble: Color(0xFFFFFDF6),
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
