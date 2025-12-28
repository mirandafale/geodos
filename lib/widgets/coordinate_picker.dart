import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Widget reusable to pick coordinates using a small FlutterMap.
class CoordinatePicker extends StatefulWidget {
  final TextEditingController latCtrl;
  final TextEditingController lonCtrl;
  final LatLng? initialPoint;

  const CoordinatePicker({
    super.key,
    required this.latCtrl,
    required this.lonCtrl,
    this.initialPoint,
  });

  @override
  State<CoordinatePicker> createState() => _CoordinatePickerState();
}

class _CoordinatePickerState extends State<CoordinatePicker> {
  static const _defaultCenter = LatLng(28.2916, -16.6291);
  final _mapCtrl = MapController();
  LatLng? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialPoint;
    if (_selected != null) {
      _setControllersFromPoint(_selected!, moveCamera: false);
    }
    widget.latCtrl.addListener(_updateFromControllers);
    widget.lonCtrl.addListener(_updateFromControllers);
  }

  @override
  void dispose() {
    widget.latCtrl.removeListener(_updateFromControllers);
    widget.lonCtrl.removeListener(_updateFromControllers);
    super.dispose();
  }

  void _setControllersFromPoint(LatLng point, {bool moveCamera = true}) {
    final latText = point.latitude.toStringAsFixed(6);
    final lonText = point.longitude.toStringAsFixed(6);
    if (widget.latCtrl.text != latText) widget.latCtrl.text = latText;
    if (widget.lonCtrl.text != lonText) widget.lonCtrl.text = lonText;
    setState(() => _selected = point);
    if (moveCamera) {
      _mapCtrl.move(point, 12);

    }
  }

  void _updateFromControllers() {
    final lat = double.tryParse(widget.latCtrl.text.replaceAll(',', '.'));
    final lon = double.tryParse(widget.lonCtrl.text.replaceAll(',', '.'));
    if (lat == null || lon == null) return;
    final next = LatLng(lat, lon);
    if (_selected != null &&
        (_selected!.latitude - next.latitude).abs() < 1e-6 &&
        (_selected!.longitude - next.longitude).abs() < 1e-6) {
      return;
    }
    setState(() => _selected = next);
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      if (_selected != null)
        Marker(
          point: _selected!,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_pin, color: Colors.red, size: 36),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 240,
          child: FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _selected ?? _defaultCenter,
              initialZoom: _selected != null ? 12 : 7,
              onTap: (_, point) => _setControllersFromPoint(point),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'geodos.app',
                tileProvider: NetworkTileProvider(),
              ),
              if (markers.isNotEmpty) MarkerLayer(markers: markers),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _selected != null
                ? 'Lat: ${_selected!.latitude.toStringAsFixed(6)} · Lon: ${_selected!.longitude.toStringAsFixed(6)}'
                : 'Toca el mapa para seleccionar la ubicación',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
