import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/home/atlas_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/learning/learning_screen.dart';
import '../features/learning/capital_setup_screen.dart';
import '../features/learning/capitals.dart';
import '../features/learning/flags.dart';
import '../features/learning/flags_setup_screen.dart';

GoRouter _createRouter() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: '/daily',
      builder: (_, _) => const LearningScreen(daily: true),
    ),
    GoRoute(path: '/progress', builder: (_, _) => const ProgressScreen()),
    GoRoute(path: '/flags', builder: (_, _) => const FlagsSetupScreen()),
    GoRoute(path: '/atlas', builder: (_, _) => const AtlasScreen()),
    GoRoute(path: '/capitals', builder: (_, _) => const CapitalSetupScreen()),
    GoRoute(
      path: '/learn',
      builder: (_, state) => LearningScreen(
        key: ValueKey(state.uri.toString()),
        flagDifficulty: state.uri.queryParameters['topic'] == 'flags'
            ? FlagDifficulty.values
                      .where(
                        (d) => d.name == state.uri.queryParameters['level'],
                      )
                      .firstOrNull ??
                  FlagDifficulty.choice
            : null,
        capitalDifficulty: state.uri.queryParameters['topic'] != 'capitals'
            ? null
            : CapitalDifficulty.values
                      .where(
                        (d) => d.name == state.uri.queryParameters['level'],
                      )
                      .firstOrNull ??
                  CapitalDifficulty.choice,
      ),
    ),
  ],
);

class GeoKunaApp extends StatefulWidget {
  const GeoKunaApp({super.key});
  @override
  State<GeoKunaApp> createState() => _GeoKunaAppState();
}

class _GeoKunaAppState extends State<GeoKunaApp> {
  late final _router = _createRouter();
  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'GeoKuna',
    debugShowCheckedModeBanner: false,
    locale: const Locale('pl'),
    supportedLocales: const [Locale('pl')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF335C45),
        surface: const Color(0xFFFAF8F0),
      ),
      scaffoldBackgroundColor: const Color(0xFFFAF8F0),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFAF8F0),
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    ),
    routerConfig: _router,
  );
}

class LoadError extends StatelessWidget {
  const LoadError({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40),
          const SizedBox(height: 16),
          const Text(
            'Nie udało się odczytać lokalnych danych. Spróbuj ponownie.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Ponów odczyt')),
        ],
      ),
    ),
  );
}
