import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'catalog.dart';

class CountryMap extends StatefulWidget {
  const CountryMap({
    super.key,
    required this.catalog,
    required this.onSelected,
    this.selectedId,
    this.correctId,
    this.focusId,
    this.questionRegionId,
    this.locked = false,
  });
  final Catalog catalog;
  final ValueChanged<String> onSelected;
  final String? selectedId;
  final String? correctId;
  final String? focusId;
  final String? questionRegionId;
  final bool locked;

  @override
  State<CountryMap> createState() => _CountryMapState();
}

class _CountryMapState extends State<CountryMap> {
  final _controller = MapController();
  final LayerHitNotifier<String> _hits = ValueNotifier(null);
  static final _bounds = LatLngBounds(
    const LatLng(34, -25),
    const LatLng(71.5, 55),
  );

  LatLngBounds get _initialBounds {
    final id = widget.questionRegionId;
    if (id == null) return _bounds;
    final center = widget.catalog.country(id).center;
    // A coarse regional center helps navigation without marking the answer.
    final latitude = (center.latitude / 5).round() * 5.0;
    final longitude = (center.longitude / 5).round() * 5.0;
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

  @override
  void dispose() {
    _hits.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
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
                if (hits != null && hits.isNotEmpty) _select(hits.first);
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
                          child: const Icon(Icons.place_outlined, size: 19),
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
              _control(
                Icons.add,
                'Przybliż mapę',
                () => _controller.move(
                  _controller.camera.center,
                  (_controller.camera.zoom + 1).clamp(2, 10),
                ),
              ),
              _control(
                Icons.remove,
                'Oddal mapę',
                () => _controller.move(
                  _controller.camera.center,
                  (_controller.camera.zoom - 1).clamp(2, 10),
                ),
              ),
              _control(
                Icons.fit_screen,
                'Pokaż cały obszar',
                () => _controller.fitCamera(
                  CameraFit.bounds(
                    bounds: _bounds,
                    padding: const EdgeInsets.all(24),
                  ),
                ),
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
