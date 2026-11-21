import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/version.dart';
import '../atlas/catalog.dart';
import '../atlas/continent.dart';
import 'app_preferences.dart';
import 'progress_backup.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _all = false;
  bool _busy = false;
  String? _error;

  void _invalidateProgress() {
    ref.invalidate(dashboardProvider);
    ref.invalidate(dailyOverviewProvider);
    ref.invalidate(learningProgressProvider);
    ref.invalidate(continentProgressProvider);
    ref.invalidate(streakProvider);
    ref.invalidate(achievementsProvider);
    ref.invalidate(continentAchievementsProvider);
  }

  /// Runs one backup action with the shared busy/error state.
  Future<void> _backupAction(Future<String?> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await action();
      if (message != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } on BackupException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Nie udało się obsłużyć pliku kopii.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() => _backupAction(() async {
    final backup = ref.read(backupProvider);
    final saved = await FilePicker.saveFile(
      fileName: backup.fileName(DateTime.now()),
      bytes: utf8.encode(await backup.export()),
      mimeType: 'application/json',
      dialogTitle: 'Zapisz kopię postępu',
    );
    return saved == null ? null : 'Kopia postępu zapisana.';
  });

  Future<void> _import() => _backupAction(() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Wybierz kopię postępu',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null || !mounted) return null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wczytać kopię?'),
        content: const Text(
          'Obecny postęp na tym urządzeniu zostanie zastąpiony postępem z '
          'kopii. Tego nie da się cofnąć.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Wczytaj kopię'),
          ),
        ],
      ),
    );
    if (confirmed != true) return null;
    final summary = await ref
        .read(backupProvider)
        .import(utf8.decode(await file.readAsBytes()));
    ref.invalidate(appPreferencesProvider);
    _invalidateProgress();
    return 'Wczytano kopię: ${summary.answers} odpowiedzi, '
        '${summary.days} dni nauki.';
  });

  Future<void> _setAppearance(MapAppearance value) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(appPreferencesProvider.notifier).setAppearance(value);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Nie udało się zapisać ustawienia mapy.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setDifficulty(
    Continent continent,
    LearningDifficulty value,
  ) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(appPreferencesProvider.notifier)
          .setDifficulty(continent, value);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Nie udało się zapisać poziomu trudności.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    final continent = ref.read(selectedContinentProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Rozpocząć naukę od nowa?'),
        content: Text(
          _all
              ? 'Usuniemy wszystkie wyniki, historię, rozpoczęte quizy i terminy powtórek ze wszystkich kontynentów. Tego nie można cofnąć.'
              : 'Usuniemy sesje z zakresu ${continent.label} i postęp jej krajów. Kraje wspólne z innymi kontynentami także stracą postęp. Tego nie można cofnąć.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zachowaj naukę'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usuń postęp'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final reset = ref.read(resetProvider);
      if (_all) {
        await reset.all();
      } else {
        final catalog = await Catalog.load(continent: continent);
        await reset.continent(
          continent,
          catalog.countries.map((c) => c.id).toSet(),
        );
      }
      _invalidateProgress();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Postęp zresetowany. Możesz zacząć od nowa.'),
          ),
        );
        context.go('/');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Nie udało się zresetować nauki. Spróbuj ponownie.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final continent = ref.watch(selectedContinentProvider);
    final preferences = ref.watch(appPreferencesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Text(
                  'Wygląd mapy',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Wybierz styl używany na mapach w atlasie i quizach.',
                ),
                const SizedBox(height: 12),
                preferences.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => const Text(
                    'Nie udało się wczytać ustawień. Spróbuj ponownie później.',
                  ),
                  data: (value) => Column(
                    children: [
                      RadioGroup<MapAppearance>(
                        groupValue: value.appearance,
                        onChanged: (appearance) {
                          if (!_busy &&
                              appearance != null &&
                              appearance != value.appearance) {
                            _setAppearance(appearance);
                          }
                        },
                        child: AbsorbPointer(
                          absorbing: _busy,
                          child: Column(
                            children: [
                              for (final appearance in MapAppearance.values)
                                _AppearanceCard(
                                  appearance: appearance,
                                  selected: value.appearance == appearance,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Poziom nauki',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Dotyczy nowych quizów mapy, stolic i flag na wybranym kontynencie. Zaplanowane powtórki zachowują ćwiczony poziom.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final region in Continent.values)
                        _DifficultyPreference(
                          continent: region,
                          value: value.difficultyFor(region),
                          enabled: !_busy,
                          onChanged: (difficulty) =>
                              _setDifficulty(region, difficulty),
                        ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                Card.filled(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kopia zapasowa',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Cała nauka w jednym pliku: postęp, powtórki, passa, medale i '
                          'ustawienia. Przyda się przy zmianie telefonu lub przeglądarki.',
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: _busy ? null : _export,
                              icon: const Icon(Icons.save_alt),
                              label: const Text('Zapisz kopię'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _busy ? null : _import,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Wczytaj kopię'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card.filled(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nowy początek',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Reset usuwa zapisane postępy na tym urządzeniu i nie da się go cofnąć. Przed resetem możesz zapisać kopię.',
                        ),
                        const SizedBox(height: 8),
                        RadioGroup<bool>(
                          groupValue: _all,
                          onChanged: (value) {
                            if (!_busy && value != null) {
                              setState(() => _all = value);
                            }
                          },
                          child: Column(
                            children: [
                              RadioListTile<bool>(
                                contentPadding: EdgeInsets.zero,
                                value: false,
                                title: Text('Tylko ${continent.label}'),
                                subtitle: const Text(
                                  'Także wspólne karty krajów transkontynentalnych.',
                                ),
                              ),
                              const RadioListTile<bool>(
                                contentPadding: EdgeInsets.zero,
                                value: true,
                                title: Text('Cała nauka'),
                                subtitle: Text(
                                  'Wszystkie kontynenty i wszystkie rozpoczęte quizy.',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _reset,
                          icon: _busy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.restart_alt),
                          label: Text(_busy ? 'Zapisuję…' : 'Zresetuj naukę'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const _AboutApp(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({required this.appearance, required this.selected});
  final MapAppearance appearance;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final (icon, description) = switch (appearance) {
      MapAppearance.atlas => (
        Icons.public,
        'Żywe kolory państw i miękki cień wybrzeży.',
      ),
      MapAppearance.paper => (
        Icons.map_outlined,
        'Stary druk: sepia, linie wody i róża wiatrów.',
      ),
      MapAppearance.relief => (
        Icons.terrain,
        'Góry, rzeki i jeziora jak na mapie terenu.',
      ),
    };
    return Card.filled(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: RadioListTile<MapAppearance>(
        value: appearance,
        title: Text(appearance.label),
        subtitle: Text(description),
        secondary: Icon(icon, size: 30),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        selected: selected,
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }
}

class _DifficultyPreference extends StatelessWidget {
  const _DifficultyPreference({
    required this.continent,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });
  final Continent continent;
  final LearningDifficulty value;
  final bool enabled;
  final ValueChanged<LearningDifficulty> onChanged;

  @override
  Widget build(BuildContext context) => Card.filled(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(continent.label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<LearningDifficulty>(
            key: ValueKey('${continent.name}-${value.name}'),
            initialValue: value,
            decoration: const InputDecoration(labelText: 'Poziom quizów'),
            isExpanded: true,
            items: [
              for (final difficulty in LearningDifficulty.values)
                DropdownMenuItem(
                  value: difficulty,
                  child: Text(difficulty.label),
                ),
            ],
            onChanged: enabled
                ? (difficulty) {
                    if (difficulty != null && difficulty != value) {
                      onChanged(difficulty);
                    }
                  }
                : null,
          ),
          const SizedBox(height: 8),
          Text(value.description),
        ],
      ),
    ),
  );
}

/// App and content versions, so a reported mistake can be traced to a pack.
class _AboutApp extends ConsumerWidget {
  const _AboutApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String pack(String? version) =>
        version == null ? '…' : version.split('-').last;
    final continent = ref.watch(selectedContinentProvider);
    final small = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GeoKuna $appVersion ($appBuild)',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Ciekawostki: o krajach '
          '${pack(ref.watch(countryTriviaProvider).asData?.value.version)}, '
          'o stolicach '
          '${pack(ref.watch(capitalTriviaProvider).asData?.value.version)}, '
          'o flagach '
          '${pack(ref.watch(flagTriviaProvider).asData?.value.version)}.',
          style: small,
        ),
        Text(
          '${continent.label}: mapa '
          '${pack(ref.watch(catalogProvider).asData?.value.version)}, '
          'stolice ${pack(ref.watch(capitalsProvider).asData?.value.version)}, '
          'flagi ${pack(ref.watch(flagsProvider).asData?.value.version)}.',
          style: small,
        ),
        const SizedBox(height: 6),
        Text('Autor: Maciej Danielak', style: small),
      ],
    );
  }
}
