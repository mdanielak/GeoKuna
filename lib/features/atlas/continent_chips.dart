import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import 'continent.dart';

/// Horizontally scrollable row of area chips shared by Today and Atlas.
/// Keeps the active chip scrolled into view, shows edge fade affordances when
/// content extends beyond the viewport, and respects reduced-motion.
class ContinentChips extends ConsumerStatefulWidget {
  const ContinentChips({super.key, required this.continent});
  final Continent continent;

  @override
  ConsumerState<ContinentChips> createState() => _ContinentChipsState();
}

class _ContinentChipsState extends ConsumerState<ContinentChips> {
  final _scrollController = ScrollController();
  final _chips = {for (final c in Continent.values) c: GlobalKey()};
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateFade);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFade());
  }

  @override
  void didUpdateWidget(ContinentChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFade());
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
  void dispose() {
    _scrollController
      ..removeListener(_updateFade)
      ..dispose();
    super.dispose();
  }

  void _updateFade() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final left = position.pixels > 2;
    final right = position.pixels < position.maxScrollExtent - 2;
    if (left != _canScrollLeft || right != _canScrollRight) {
      setState(() {
        _canScrollLeft = left;
        _canScrollRight = right;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final continent = widget.continent;
    final list = NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        _updateFade();
        return false;
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.hardEdge,
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
    return Semantics(
      label: 'Wybierz kontynent',
      container: true,
      child: !_canScrollLeft && !_canScrollRight
          ? list
          : ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) {
                final fade = bounds.width <= 0
                    ? 0.0
                    : (24.0 / bounds.width).clamp(0.0, 0.15);
                return LinearGradient(
                  colors: [
                    _canScrollLeft ? Colors.transparent : Colors.white,
                    Colors.white,
                    Colors.white,
                    _canScrollRight ? Colors.transparent : Colors.white,
                  ],
                  stops: [
                    0.0,
                    _canScrollLeft ? fade : 0.0,
                    _canScrollRight ? 1.0 - fade : 1.0,
                    1.0,
                  ],
                ).createShader(bounds);
              },
              child: list,
            ),
    );
  }
}
