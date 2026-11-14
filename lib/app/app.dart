import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import '../features/settings/app_preferences.dart';

import '../features/home/home_screen.dart';
import '../features/home/atlas_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/progress/learning_overview_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/atlas/continent.dart';
import '../features/learning/learning_screen.dart';
import '../features/learning/session_repository.dart';
import '../features/learning/capital_setup_screen.dart';
import '../features/learning/capitals.dart';
import '../features/learning/flags.dart';
import '../features/learning/flags_setup_screen.dart';

GoRouter _createRouter() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: '/daily',
      builder: (_, state) => LearningScreen(
        key: ValueKey(state.uri.toString()),
        daily: true,
        dailyMode:
            DailyMode.values.asNameMap()[state.uri.queryParameters['mode']] ??
            DailyMode.regular,
      ),
    ),
    GoRoute(
      path: '/progress',
      builder: (_, state) =>
          ProgressScreen(initialCountry: state.uri.queryParameters['country']),
    ),
    GoRoute(
      path: '/learning',
      builder: (_, _) => const LearningOverviewScreen(),
    ),
    GoRoute(
      path: '/learning/:continent',
      builder: (_, state) => LearningOverviewScreen(
        continent:
            Continent.values
                .where((c) => c.name == state.pathParameters['continent'])
                .firstOrNull ??
            Continent.europe,
      ),
    ),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    GoRoute(path: '/flags', builder: (_, _) => const FlagsSetupScreen()),
    GoRoute(path: '/atlas', builder: (_, _) => const AtlasScreen()),
    GoRoute(path: '/capitals', builder: (_, _) => const CapitalSetupScreen()),
    GoRoute(
      path: '/learn',
      builder: (_, state) {
        Widget screen(String? preferredMode) => LearningScreen(
          key: ValueKey(state.uri.toString()),
          flagDifficulty: state.uri.queryParameters['topic'] == 'flags'
              ? FlagDifficulty.values
                        .where(
                          (d) =>
                              d.name ==
                              (state.uri.queryParameters['level'] ??
                                  preferredMode),
                        )
                        .firstOrNull ??
                    FlagDifficulty.write
              : null,
          capitalDifficulty: state.uri.queryParameters['topic'] == 'capitals'
              ? CapitalDifficulty.values
                        .where(
                          (d) =>
                              d.name ==
                              (state.uri.queryParameters['level'] ??
                                  preferredMode),
                        )
                        .firstOrNull ??
                    CapitalDifficulty.write
              : null,
        );
        final topic = state.uri.queryParameters['topic'];
        if ((topic != 'capitals' && topic != 'flags') ||
            state.uri.queryParameters.containsKey('level')) {
          return screen(null);
        }
        return Consumer(
          builder: (context, ref, _) {
            final continent = ref.watch(selectedContinentProvider);
            return ref
                .watch(appPreferencesProvider)
                .when(
                  loading: () => const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => LoadError(
                    onRetry: () => ref.invalidate(appPreferencesProvider),
                  ),
                  data: (preferences) =>
                      screen(preferences.difficultyFor(continent).mode),
                );
          },
        );
      },
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
