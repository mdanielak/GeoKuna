import 'dart:async';

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

/// log2(1.03): the atlas focus zooms in by about 3%.
const _focusZoomGain = 0.0426;

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

  /// Wrong-answer labels: true while shown, false while fading out. A label
  /// lives ~2 s, so it never hides the map for long; the red fill stays.
  final _labels = <String, bool>{};
  final _labelTimers = <Timer>[];
  static const _labelVisible = Duration(milliseconds: 1500);
  static const _labelFade = Duration(milliseconds: 400);

  void _showLabels(Iterable<String> ids) {
    for (final id in ids) {
      _labels[id] = true;
      _labelTimers.add(
        Timer(_labelVisible, () {
          if (!mounted || _labels[id] != true) return;
          setState(() => _labels[id] = false);
          _labelTimers.add(
            Timer(_labelFade, () {
              if (mounted) setState(() => _labels.remove(id));
            }),
          );
        }),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _showLabels(widget.wrongCountryIds);
  }

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
    Continent.northAmerica => LatLngBounds(
      const LatLng(5, -170),
      const LatLng(84, -50),
    ),
    Continent.southAmerica => LatLngBounds(
      const LatLng(-57, -95),
      const LatLng(15, -30),
    ),
    // Shifted longitudes: 110°E → -70, 150°W → 30.
    Continent.oceania => LatLngBounds(
      const LatLng(-50, -70),
      const LatLng(22, 30),
    ),
    // Must match tools/data_pipeline/build_subdivisions.py windows.
    Continent.poland => LatLngBounds(
      const LatLng(48.6, 13.5),
      const LatLng(55.3, 24.5),
    ),
    Continent.usa => LatLngBounds(
      const LatLng(16, -128),
      const LatLng(51, -64),
    ),
  };

  // On a portrait phone the whole continent leaves most of the screen as sea:
  // frame its core instead; outlying areas stay reachable by panning.
  LatLngBounds get _portraitBounds => switch (widget.catalog.continent) {
    Continent.europe => LatLngBounds(
      const LatLng(35, -11),
      const LatLng(71, 50),
    ),
    Continent.africa => LatLngBounds(
      const LatLng(-35, -18),
      const LatLng(37.5, 52),
    ),
    Continent.asia => LatLngBounds(
      const LatLng(-11, 26),
      const LatLng(56, 146),
    ),
    // Without Alaska and the far north, which a portrait phone cannot fit.
    Continent.northAmerica => LatLngBounds(
      const LatLng(7, -128),
      const LatLng(60, -58),
    ),
    Continent.southAmerica => LatLngBounds(
      const LatLng(-56, -82),
      const LatLng(13, -34),
    ),
    // Australia, New Guinea, New Zealand and Fiji; far atolls by panning.
    Continent.oceania => LatLngBounds(
      const LatLng(-47, -68),
      const LatLng(3, 5),
    ),
    Continent.poland => LatLngBounds(
      const LatLng(49, 14.1),
      const LatLng(54.9, 24.2),
    ),
    // Contiguous states plus the Alaska and Hawaii insets below them.
    Continent.usa => LatLngBounds(
      const LatLng(16.2, -128.6),
      const LatLng(49.5, -66),
    ),
  };

  Size? _viewport;
  LatLngBounds get _frameBounds =>
      widget.quizMode && _viewport != null && _viewport!.aspectRatio < 1
      ? _portraitBounds
      : _bounds;

  double get _minZoom => 1;

  // A tiny scale difference only; framing never depends on the answer.
  EdgeInsets get _initialPadding => EdgeInsets.all(widget.quizMode ? 16 : 24);

  @override
  void didUpdateWidget(CountryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _labels.removeWhere((id, _) => !widget.wrongCountryIds.contains(id));
    _showLabels(widget.wrongCountryIds.difference(oldWidget.wrongCountryIds));
    if (widget.catalog.continent != oldWidget.catalog.continent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resetView();
      });
    } else if (widget.focusId != oldWidget.focusId && widget.focusId != null) {
      // Centre the chosen country with a barely noticeable zoom (~3%), so
      // its neighbours stay in view.
      final camera = _controller.camera;
      _controller.move(
        widget.catalog.country(widget.focusId!).center,
        (camera.zoom + _focusZoomGain).clamp(_minZoom, 10),
      );
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
      bounds: _frameBounds,
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

  MapPalette get _palette => MapPalette(widget.appearance);

  Color _color(String id) {
    final palette = _palette;
    if (id == widget.correctId) return palette.correct;
    if (widget.wrongCountryIds.contains(id)) return palette.wrong;
    if (id == widget.selectedId) {
      return widget.correctId == null ? palette.selected : palette.wrong;
    }
    // Relief tiles show sea under the moved insets: they need a fill.
    return widget.appearance == MapAppearance.relief &&
            !widget.catalog.insetFrames.any((f) => f.areaId == id)
        ? Colors.transparent
        : widget.appearance == MapAppearance.relief
        ? _palette.insetLand
        : _palette.fills[countryColoring(
            widget.catalog,
            _palette.fills.length,
          )[id]!];
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
    CameraFit.bounds(bounds: _frameBounds, padding: _initialPadding),
  );

  @override
  void dispose() {
    for (final timer in _labelTimers) {
      timer.cancel();
    }
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
            label: 'Mapa. Klawisze strzałek przesuwają mapę, plus i minus zmieniają powiększenie, zero przywraca widok.',
            child: Stack(
              children: [
                Positioned.fill(
                  child: MapSurface(appearance: widget.appearance),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    _viewport = constraints.biggest;
                    return _map();
                  },
                ),
                if (widget.appearance == MapAppearance.paper)
                  const Positioned(left: 12, top: 12, child: CompassRose()),
                Positioned(
                  right: 8,
                  // In a quiz the top and bottom belong to the question and
                  // the feedback panel; keep the controls mid-height.
                  top: widget.quizMode ? 0 : 8,
                  bottom: widget.quizMode ? 0 : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                if (!widget.quizMode)
                  Positioned(
                    left: 10,
                    bottom: 8,
                    child: IgnorePointer(
                      child: Text(
                        'Natural Earth · ${widget.catalog.countries.length} ${widget.catalog.continent.areaNoun}',
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

  Widget _map() => FlutterMap(
    mapController: _controller,
    options: MapOptions(
      crs: const _RegionalMercator(),
      initialCameraFit: CameraFit.bounds(
        bounds: _frameBounds,
        padding: _initialPadding,
      ),
      minZoom: _minZoom,
      maxZoom: 10,
      backgroundColor: Colors.transparent,
      // initialCameraFit is applied after onMapReady; frame the
      // question once the continent fit is in place.
      onMapReady: () => WidgetsBinding.instance.addPostFrameCallback((_) {
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
            child: TileLayer(
              urlTemplate: reliefTileTemplate(widget.catalog.continent),
              tileProvider: AssetTileProvider(),
              minNativeZoom: 2,
              // Sharper ETOPO hillshade tiles exist for the subdivision maps
              // (tools/data_pipeline/build_relief_hd.py).
              maxNativeZoom: switch (widget.catalog.continent) {
                Continent.poland => 8,
                Continent.usa => 7,
                _ => 6,
              },
              tileBounds: _bounds,
            ),
          ),
        ),
      // Tiles overhang the window; outside it the map is plain sea again.
      if (widget.appearance == MapAppearance.relief)
        IgnorePointer(
          child: PolygonLayer(
            polygons: [
              for (final band in _outsideWindow())
                Polygon(
                  points: band,
                  color: _palette.ocean,
                  borderStrokeWidth: 0,
                ),
            ],
          ),
        ),
      if (widget.appearance == MapAppearance.paper) const MapGraticule(),
      for (final (width, color) in _palette.coastRings)
        IgnorePointer(
          child: PolygonLayer(
            polygons: [
              for (final rings in [
                ...widget.catalog.context,
                for (final shape in widget.catalog.shapes) shape.rings,
              ])
                Polygon(
                  points: rings.first,
                  color: Colors.transparent,
                  borderColor: color,
                  borderStrokeWidth: width,
                ),
            ],
          ),
        ),
      if (widget.catalog.context.isNotEmpty)
        IgnorePointer(
          child: PolygonLayer(
            polygons: [
              for (final polygon in widget.catalog.context)
                Polygon(
                  points: polygon.first,
                  holePointsList: polygon.skip(1).toList(),
                  color: _palette.contextLand,
                  borderColor: _palette.boundary.withValues(alpha: .35),
                  borderStrokeWidth: .6,
                ),
            ],
          ),
        ),
      if (widget.catalog.insetFrames.isNotEmpty) ..._insetFrames(),
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
                borderColor: _palette.boundary,
                borderStrokeWidth: _palette.boundaryWidth,
              ),
          ],
        ),
      ),
      IgnorePointer(child: PolygonLayer(polygons: _edgeFade())),
      if (widget.appearance == MapAppearance.paper) const PaperAtlasFrame(),
      MarkerLayer(
        markers: [
          for (final country in widget.catalog.countries.where((c) => c.small))
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
                    // A small dot inside a 48 dp touch target, so microstates
                    // do not hide their larger neighbours.
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _color(country.id) == Colors.transparent
                          ? MapPalette(widget.appearance).markerFill
                          : _color(country.id),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _palette.markerBorder,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      Builder(
        builder: (context) {
          final wrong = widget.catalog.countries
              .where((country) => _labels.containsKey(country.id))
              .toList();
          final points = _labelPoints(MapCamera.of(context), wrong);
          return MarkerLayer(
            markers: [
              for (final country in wrong)
                Marker(
                  point: points[country.id]!,
                  width: 150,
                  height: 48,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _labels[country.id] == true ? 1 : 0,
                      duration: _labelFade,
                      child: Semantics(
                        container: true,
                        liveRegion: true,
                        excludeSemantics: true,
                        label: 'Błędna odpowiedź: ${country.name}',
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _palette.wrongLabel,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: _palette.labelShadow,
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
                ),
            ],
          );
        },
      ),
    ],
  );

  /// Places wrong-answer labels on screen: clamped inside the map with room
  /// for the zoom controls, and pushed apart when two would overlap.
  Map<String, LatLng> _labelPoints(MapCamera camera, List<Country> countries) {
    const halfWidth = 75.0, halfHeight = 24.0, margin = 8.0, step = 44.0;
    final size = camera.size;
    final right = size.width - halfWidth - margin - 64;
    final left = halfWidth + margin;
    final top = halfHeight + margin, bottom = size.height - halfHeight - margin;
    if (right <= left || bottom <= top) {
      return {for (final c in countries) c.id: c.center};
    }
    final placed = <Offset>[];
    final result = <String, LatLng>{};
    for (final country in countries) {
      final raw = camera.latLngToScreenOffset(country.center);
      var offset = Offset(raw.dx.clamp(left, right), raw.dy.clamp(top, bottom));
      for (var tries = 0; tries < 6; tries++) {
        final clash = placed.any(
          (p) =>
              (p.dx - offset.dx).abs() < 2 * halfWidth &&
              (p.dy - offset.dy).abs() < step,
        );
        if (!clash) break;
        final down = offset.dy + step;
        offset = Offset(offset.dx, down <= bottom ? down : offset.dy - step);
      }
      placed.add(offset);
      result[country.id] = offset == raw
          ? country.center
          : camera.screenOffsetToLatLng(offset);
    }
    return result;
  }

  /// Framed boxes of the moved insets (Alaska, Hawaii) with a scale note.
  List<Widget> _insetFrames() => [
    IgnorePointer(
      child: PolygonLayer(
        polygons: [
          for (final frame in widget.catalog.insetFrames)
            Polygon(
              points: [
                frame.bounds.northWest,
                frame.bounds.northEast,
                frame.bounds.southEast,
                frame.bounds.southWest,
              ],
              color: _palette.ocean,
              borderColor: _palette.boundary.withValues(alpha: .7),
              borderStrokeWidth: 1.2,
            ),
        ],
      ),
    ),
    IgnorePointer(
      child: MarkerLayer(
        markers: [
          for (final frame in widget.catalog.insetFrames)
            Marker(
              point: frame.bounds.northWest,
              width: 150,
              height: 16,
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, top: 2),
                child: Text(
                  frame.label,
                  style: TextStyle(fontSize: 10, color: _palette.boundary),
                ),
              ),
            ),
        ],
      ),
    ),
  ];

  /// Sea around the data window, up to the edge of the world. Boxes stay
  /// under 180° wide: flutter_map unwraps wider ones as antimeridian-crossing.
  List<List<LatLng>> _outsideWindow() {
    final b = _bounds;
    final boxes = <List<LatLng>>[];
    void box(double s, double w, double n, double e) {
      for (var west = w; west < e; west += 60) {
        // Half a degree of overlap hides anti-aliasing seams.
        final east = west + 60 < e ? west + 60.5 : e;
        boxes.add([
          LatLng(n, west),
          LatLng(n, east),
          LatLng(s, east),
          LatLng(s, west),
        ]);
      }
    }

    box(b.north, -180, 85, 180);
    box(-85, -180, b.south, 180);
    box(b.south, -180, b.north, b.west);
    box(b.south, b.east, b.north, 180);
    return boxes;
  }

  /// Soft edge of the data window: stacked translucent sea bands so land cut
  /// by the window fades into the sea instead of ending in a straight line.
  List<Polygon> _edgeFade() {
    final b = _bounds;
    final latStep = (b.north - b.south) * .012;
    final lngStep = (b.east - b.west) * .01;
    final sea = MapPalette(widget.appearance).ocean.withValues(alpha: .3);
    LatLng at(double lat, double lng) =>
        LatLng(lat.clamp(-90, 90), lng.clamp(-180, 180));
    List<LatLng> rect(double inset) => [
      at(b.north - inset * latStep, b.west + inset * lngStep),
      at(b.north - inset * latStep, b.east - inset * lngStep),
      at(b.south + inset * latStep, b.east - inset * lngStep),
      at(b.south + inset * latStep, b.west + inset * lngStep),
    ];
    return [
      for (var band = 1; band <= 4; band++)
        Polygon(
          points: rect(-.5),
          holePointsList: [rect(band.toDouble())],
          color: sea,
          borderStrokeWidth: 0,
        ),
    ];
  }

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
