import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import 'continent.dart';

/// Horizontally scrollable row of area chips shared by Today and Atlas.
/// Keeps the active chip scrolled into view and respects reduced-motion.
class ContinentChips extends ConsumerStatefulWidget {
  const ContinentChips({super.key, required this.continent});
  final Continent continent;

  @override
  ConsumerState<ContinentChips> createState() => _ContinentChipsState();
}

class _ContinentChipsState extends ConsumerState<ContinentChips> {
  final _chips = {for (final c in Continent.values) c: GlobalKey()};

  @override
  void didUpdateWidget(ContinentChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.continent == widget.continent) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chip = _chips[widget.continent]!.currentContext;
      if (chip != null && chip.mounted) {
        final disableAnimations = MediaQuery.disableAnimationsOf(context);
        Scrollable.ensureVisible(
          chip,
          alignment: .5,
          duration: disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 250),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final continent = widget.continent;
    return Semantics(
      label: 'Wybierz kontynent',
      container: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: [
            for (final option in Continent.values) ...[
              ChoiceChip(
                key: _chips[option],
                label: Text(option.label),
                selected: continent == option,
                showCheckmark: false,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: (_) =>
                    ref.read(selectedContinentProvider.notifier).select(option),
              ),
              if (option != Continent.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}
