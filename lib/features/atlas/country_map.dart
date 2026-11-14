import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'catalog.dart';
import 'continent.dart';
import 'map_style.dart';
import 'quiz_map_frame.dart';
import '../settings/app_preferences.dart';

// The offline regional map needs one Mercator world, without repeated copies.
class _RegionalMercator extends Epsg3857 {
  const _RegionalMercator();
  @override
  bool get replicatesWorldLongitude => false;
}

const _revealZoomGain = 1.5;

class CountryMap extends StatefulWidget {
  const CountryMap({
    super.key,
    required this.catalog,
    required this.onSelected,
    this.selectedId,
    this.correctId,
    this.focusId,
    this.revealId,
    this.wrongCountryIds = const {},
    this.targetId,
    this.supportLevel = 'normal',
    this.questionSeed = '',
    this.quizMode = false,
    this.appearance = MapAppearance.relief,
    this.locked = false,
  });
  final Catalog catalog;
  final ValueChanged<String> onSelected;
  final String? selectedId;
  final String? correctId;
  final String? focusId;
  final String? revealId;
  final Set<String> wrongCountryIds;
  final String? targetId;
  final String supportLevel;
  final String questionSeed;
  final bool quizMode;
  final MapAppearance appearance;
  final bool locked;

  @override
  State<CountryMap> createState() => _CountryMapState();
}

class _CountryMapState extends State<CountryMap> {
  final _controller = MapController();
  bool _hasKeyboardFocus = false;
  final LayerHitNotifier<String> _hits = ValueNotifier(null);
  bool _initialQuizFrameApplied = false;
  String? _handledRevealId;
  LatLngBounds get _bounds => switch (widget.catalog.continent) {
    Continent.europe => LatLngBounds(
      const LatLng(34, -32),
      const LatLng(72, 65),
    ),
    Continent.africa => LatLngBounds(
      const LatLng(-36, -26),
      const LatLng(38, 65),
    ),
    Continent.asia => LatLngBounds(
      const LatLng(-12, 20),
      const LatLng(82, 180),
    ),
  };

  double get _minZoom => 1;

  // A tiny scale difference only; framing never depends on the answer.
  EdgeInsets get _initialPadding => EdgeInsets.all(widget.quizMode ? 16 : 24);

  @override
  void didUpdateWidget(CountryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.catalog.continent != oldWidget.catalog.continent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resetView();
      });
    } else if (widget.focusId != oldWidget.focusId && widget.focusId != null) {
      _controller.move(widget.catalog.country(widget.focusId!).center, 6);
    }
    if (widget.revealId != oldWidget.revealId && widget.revealId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _revealCountry(widget.revealId!);
      });
    }
  }

  void _applyQuizFrame() {
    final shouldApplyHint =
        widget.quizMode &&
        widget.supportLevel != 'normal' &&
        widget.questionSeed.isNotEmpty &&
        widget.targetId != null &&
        widget.revealId == null &&
        !_initialQuizFrameApplied;
    if (shouldApplyHint) {
      _initialQuizFrameApplied = true;
      final camera = _controller.camera;
      final frame = QuizMapFrame.forTarget(
        continentCenter: camera.center,
        target: widget.catalog.country(widget.targetId!).center,
        continentZoom: camera.zoom,
        viewport: camera.size,
        supportLevel: widget.supportLevel,
        seed: widget.questionSeed,
      );
      _controller.move(frame.center, frame.zoom);
    }
    if (widget.revealId != null) _revealCountry(widget.revealId!);
  }

  void _revealCountry(String id) {
    if (_handledRevealId == id) return;
    _handledRevealId = id;
    final allCountryPoints = widget.catalog.shapes
        .where((shape) => shape.countryId == id)
        .expand((shape) => shape.rings)
        .expand((ring) => ring)
        .toList();
    if (allCountryPoints.isEmpty) {
      _controller.move(widget.catalog.country(id).center, 5);
      return;
    }
    final target = widget.catalog.country(id).center;
    final nearbyPoints = allCountryPoints.where((point) {
      var longitudeDelta = (point.longitude - target.longitude).abs();
      if (longitudeDelta > 180) longitudeDelta = 360 - longitudeDelta;
      return (point.latitude - target.latitude).abs() <= 14 &&
          longitudeDelta <= 20;
    }).toList();
    // Show the answer within its region, not a close-up: at most
    // [_revealZoomGain] above the continent overview.
    final overviewZoom = CameraFit.bounds(
      bounds: _bounds,
      padding: _initialPadding,
    ).fit(_controller.camera).zoom;
    _controller.fitCamera(
      CameraFit.coordinates(
        coordinates: nearbyPoints.length >= 3 ? nearbyPoints : allCountryPoints,
        padding: const EdgeInsets.all(80),
        maxZoom: overviewZoom + _revealZoomGain,
        minZoom: _minZoom,
      ),
    );
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
      _controller.move(country.center, (camera.zoom + 2).clamp(_minZoom, 10));
      return;
    }
    _select(country.id);
  }

  Color _color(String id) {
    if (id == widget.correctId) return const Color(0xFF458461);
    if (widget.wrongCountryIds.contains(id)) return const Color(0xFFB85A48);
    if (id == widget.selectedId) {
      return widget.correctId == null
          ? const Color(0xFFD0A751)
          : const Color(0xFFB85A48);
    }
    return widget.appearance == MapAppearance.relief
        ? Colors.transparent
        : MapPalette(widget.appearance).country(id);
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
    (_controller.camera.zoom + amount).clamp(_minZoom, 10),
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
                Positioned.fill(
                  child: MapSurface(appearance: widget.appearance),
                ),
                FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    crs: const _RegionalMercator(),
                    initialCameraFit: CameraFit.bounds(
                      bounds: _bounds,
                      padding: _initialPadding,
                    ),
                    minZoom: _minZoom,
                    maxZoom: 10,
                    backgroundColor: Colors.transparent,
                    // initialCameraFit is applied after onMapReady; frame the
                    // question once the continent fit is in place.
                    onMapReady: () =>
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _applyQuizFrame();
                        }),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    if (widget.appearance == MapAppearance.relief)
                      IgnorePointer(
                        child: ExcludeSemantics(
                          child: OverlayImageLayer(
                            overlayImages: [
                              OverlayImage(
                                bounds: _bounds,
                                imageProvider: AssetImage(
                                  'assets/maps/styles/relief/${widget.catalog.continent.name}.png',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (widget.appearance == MapAppearance.paper)
                      const MapGraticule(),
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
                              borderColor: MapPalette(widget.appearance)
                                  .boundary,
                              borderStrokeWidth: .9,
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
                                    color:
                                        _color(country.id) == Colors.transparent
                                        ? MapPalette(widget.appearance)
                                              .markerFill
                                        : _color(country.id),
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
                    MarkerLayer(
                      markers: [
                        for (final country in widget.catalog.countries.where(
                          (country) =>
                              widget.wrongCountryIds.contains(country.id),
                        ))
                          Marker(
                            point: country.center,
                            width: 150,
                            height: 48,
                            child: IgnorePointer(
                              child: Semantics(
                                container: true,
                                liveRegion: true,
                                excludeSemantics: true,
                                label: 'Błędna odpowiedź: ${country.name}',
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8C1D18),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x55000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      child: Text(
                                        country.name,
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
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
