import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../atlas/continent.dart';
import 'app_preferences.dart';

/// Opens a modal bottom sheet to choose the learning difficulty for [continent]
/// in place, without navigating away to Settings.
Future<void> showDifficultySheet(
  BuildContext context,
  WidgetRef ref, {
  required Continent continent,
  required LearningDifficulty current,
  bool activeSession = false,
  String activeNotice =
      'Rozpoczęta wyprawa zachowuje zapisany poziom; wybór dotyczy następnej.',
}) async {
  final chosen = await showModalBottomSheet<LearningDifficulty>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Poziom: ${continent.label}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final level in LearningDifficulty.menuOrder)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(level.label),
                subtitle: Text(level.description),
                selected: level == current,
                trailing: level == current ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, level),
              ),
            if (activeSession)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Text(
                  activeNotice,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    ),
  );
  if (chosen == null || chosen == current) return;
  await ref
      .read(appPreferencesProvider.notifier)
      .setDifficulty(continent, chosen);
  ref.invalidate(dailyOverviewProvider);
  ref.invalidate(dashboardProvider);
}
