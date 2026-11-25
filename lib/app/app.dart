import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'theme.dart';
import '../features/settings/app_preferences.dart';

import '../features/home/home_screen.dart';
import '../features/home/atlas_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/progress/learning_overview_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/atlas/continent.dart';
import '../features/learning/learning_screen.dart';
import '../features/learning/session_repository.dart';
import '../features/learning/capitals.dart';
import '../features/learning/flags.dart';
import '../features/learning/flags_setup_screen.dart';

GoRouter _createRouter() => GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => _TabShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/atlas', builder: (_, _) => const AtlasScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/learning',
              builder: (_, _) => const LearningOverviewScreen(),
            ),
          ],
        ),
      ],
    ),
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
      builder: (_, state) {
        final continentParam = state.uri.queryParameters['continent'];
        final continent = Continent.values
            .where((c) => c.name == continentParam)
            .firstOrNull;
        return ProgressScreen(
          continent: continent,
          initialCountry: state.uri.queryParameters['country'],
        );
      },
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
    GoRoute(path: '/capitals', redirect: (_, _) => '/learn?topic=capitals'),
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

class GeoKunaApp extends ConsumerStatefulWidget {
  const GeoKunaApp({super.key});
  @override
  ConsumerState<GeoKunaApp> createState() => _GeoKunaAppState();
}

class _GeoKunaAppState extends ConsumerState<GeoKunaApp>
    with WidgetsBindingObserver {
  late final _router = _createRouter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref
        ..invalidate(dailyOverviewProvider)
        ..invalidate(streakProvider)
        ..invalidate(continentStreakProvider)
        ..invalidate(learningProgressProvider)
        ..invalidate(continentProgressProvider);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    theme: GeoTheme.light(),
    routerConfig: _router,
  );
}

/// Bottom navigation for the three top-level places; Back returns to Today.
class _TabShell extends StatelessWidget {
  const _TabShell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: shell.currentIndex == 0,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) shell.goBranch(0);
    },
    child: Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Dziś',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Atlas',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Moja nauka',
          ),
        ],
      ),
    ),
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
