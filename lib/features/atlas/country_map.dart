import 'dart:math';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'catalog.dart';

// The offline regional map needs one Mercator world, without repeated copies.
class _RegionalMercator extends Epsg3857 {
  const _RegionalMercator();
  @override
  bool get replicatesWorldLongitude => false;
}

class CountryMap extends StatefulWidget {
  const CountryMap({
    super.key,
    required this.catalog,
    required this.onSelected,
    this.selectedId,
    this.correctId,
    this.wrongIds = const {},
    this.focusId,
    this.questionRegionId,
    this.questionSeed,
    this.locked = false,
  });
  final Catalog catalog;
  final ValueChanged<String> onSelected;
  final String? selectedId;
  final String? correctId;
  final Set<String> wrongIds;
  final String? focusId;
  final String? questionRegionId;
  final String? questionSeed;
  final bool locked;

  @override
  State<CountryMap> createState() => _CountryMapState();
}

class _CountryMapState extends State<CountryMap> {
  final _controller = MapController();
  bool _hasKeyboardFocus = false;
  // Session + question seed keeps framing stable across rebuilds and resumes.
  late final _framingRandom = Random(
    widget.questionSeed?.codeUnits.fold<int>(
      0,
      (seed, unit) => (seed * 31 + unit) & 0x3fffffff,
    ),
  );
  late final _latitudeShift =
      (1.5 + _framingRandom.nextDouble() * 2) *
      (_framingRandom.nextBool() ? 1 : -1);
  late final _longitudeShift =
      (2.5 + _framingRandom.nextDouble() * 3) *
      (_framingRandom.nextBool() ? 1 : -1);
  final LayerHitNotifier<String> _hits = ValueNotifier(null);
  static final _bounds = LatLngBounds(
    const LatLng(34, -25),
    const LatLng(71.5, 55),
  );

  LatLngBounds get _initialBounds {
    final id = widget.questionRegionId;
    if (id == null) return _bounds;
    final center = widget.catalog.country(id).center;
    // Keep the region helpful without placing the answer at the viewport centre.
    final latitude = center.latitude + _latitudeShift;
    final longitude = center.longitude + _longitudeShift;
    return LatLngBounds(
      LatLng(latitude - 10, longitude - 16),
      LatLng(latitude + 10, longitude + 16),
    );
  }

  @override
  void didUpdateWidget(CountryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusId != oldWidget.focusId && widget.focusId != null) {
      _controller.move(widget.catalog.country(widget.focusId!).center, 6);
    }
  }

  void _selectMarker(Country country) {
    if (widget.locked) return;
    final camera = _controller.camera;
    final position = camera.latLngToScreenOffset(country.center);
    final overlaps = widget.catalog.countries.any(
      (other) =>
          other.small &&
          other.id != country.id &&
          (camera.latLngToScreenOffset(other.center) - position).distance < 48,
    );
    if (overlaps && camera.zoom < 10) {
      _controller.move(country.center, (camera.zoom + 2).clamp(2, 10));
      return;
    }
    _select(country.id);
  }

  Color _color(String id) {
    if (id == widget.correctId) return const Color(0xFF458461);
    if (widget.wrongIds.contains(id)) return const Color(0xFFB85A48);
    if (id == widget.selectedId) {
      return widget.correctId == null
          ? const Color(0xFFD0A751)
          : const Color(0xFFB85A48);
    }
    return const Color(0xFFDCE3CC);
  }

  void _select(String id) {
    if (!widget.locked) widget.onSelected(id);
  }

  void _pan(double latitude, double longitude) {
    final camera = _controller.camera;
    final step = 12 / camera.zoom;
    _controller.move(
      LatLng(
        (camera.center.latitude + latitude * step).clamp(-80, 80),
        camera.center.longitude + longitude * step,
      ),
      camera.zoom,
    );
  }

  void _zoom(double amount) => _controller.move(
    _controller.camera.center,
    (_controller.camera.zoom + amount).clamp(2, 10),
  );

  void _resetView() => _controller.fitCamera(
    CameraFit.bounds(bounds: _bounds, padding: const EdgeInsets.all(24)),
  );

  @override
  void dispose() {
    _hits.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.arrowUp): () => _pan(1, 0),
      const SingleActivator(LogicalKeyboardKey.arrowDown): () => _pan(-1, 0),
      const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _pan(0, -1),
      const SingleActivator(LogicalKeyboardKey.arrowRight): () => _pan(0, 1),
      const SingleActivator(LogicalKeyboardKey.add): () => _zoom(1),
      const SingleActivator(LogicalKeyboardKey.equal): () => _zoom(1),
      const SingleActivator(LogicalKeyboardKey.equal, shift: true): () =>
          _zoom(1),
      const SingleActivator(LogicalKeyboardKey.numpadAdd): () => _zoom(1),
      const SingleActivator(LogicalKeyboardKey.minus): () => _zoom(-1),
      const SingleActivator(LogicalKeyboardKey.numpadSubtract): () => _zoom(-1),
      const SingleActivator(LogicalKeyboardKey.digit0): _resetView,
      const SingleActivator(LogicalKeyboardKey.numpad0): _resetView,
    },
    child: Focus(
      onFocusChange: (focused) {
        if (_hasKeyboardFocus != focused) {
          setState(() => _hasKeyboardFocus = focused);
        }
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: _hasKeyboardFocus
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                )
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            focusable: true,
            label: 'Mapa państw. Klawisze strzałek przesuwają mapę, plus i minus zmieniają powiększenie, zero przywraca widok.',
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    crs: const _RegionalMercator(),
                    initialCameraFit: CameraFit.bounds(
                      bounds: _initialBounds,
                      padding: const EdgeInsets.all(24),
                    ),
                    minZoom: 2,
                    maxZoom: 10,
                    backgroundColor: const Color(0xFFE2EEF0),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    GestureDetector(
                      onTap: () {
                        final hits = _hits.value?.hitValues;
                        if (hits != null && hits.isNotEmpty) {
                          _select(hits.first);
                        }
                      },
                      child: PolygonLayer<String>(
                        hitNotifier: _hits,
                        polygons: [
                          for (final shape in widget.catalog.shapes)
                            Polygon<String>(
                              points: shape.rings.first,
                              holePointsList: shape.rings.skip(1).toList(),
                              hitValue: shape.countryId,
                              color: _color(shape.countryId),
                              borderColor: const Color(0xFF72846D),
                              borderStrokeWidth: 1.2,
                            ),
                        ],
                      ),
                    ),
                    MarkerLayer(
                      markers: [
                        for (final country in widget.catalog.countries.where(
                          (c) => c.small,
                        ))
                          Marker(
                            point: country.center,
                            width: 48,
                            height: 48,
                            child: Semantics(
                              key: ValueKey('country-marker-${country.id}'),
                              label: 'Małe państwo — znacznik',
                              button: true,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _selectMarker(country),
                                child: Container(
                                  margin: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: _color(country.id),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF365643),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.place_outlined,
                                    size: 19,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Column(
                    children: [
                      _control(Icons.add, 'Przybliż mapę', () => _zoom(1)),
                      _control(Icons.remove, 'Oddal mapę', () => _zoom(-1)),
                      _control(
                        Icons.fit_screen,
                        'Pokaż cały obszar',
                        _resetView,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 8,
                  child: IgnorePointer(
                    child: Text(
                      'Natural Earth · ${widget.catalog.countries.length} państw',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _control(IconData icon, String tooltip, VoidCallback action) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: IconButton.filledTonal(
          onPressed: action,
          tooltip: tooltip,
          icon: Icon(icon),
        ),
      );
}
