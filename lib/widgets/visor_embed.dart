import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geodos/services/project_service.dart';
import 'package:geodos/theme/brand.dart';
import 'package:geodos/theme/base_map_style.dart';

/// Visor principal de proyectos GEODOS.
/// Muestra el mapa, los marcadores y los controles flotantes (leyenda, zoom, base map, etc.)
class VisorEmbed extends StatefulWidget {
  final MapController mapCtrl;
  final BaseMapStyle baseMapStyle;

  /// Compatibilidad temporal con versiones previas (no afecta la lógica actual)
  final bool startExpanded;

  const VisorEmbed({
    super.key,
    required this.mapCtrl,
    required this.baseMapStyle,
    this.startExpanded = false,
  });

  @override
  State<VisorEmbed> createState() => _VisorEmbedState();
}

class _VisorEmbedState extends State<VisorEmbed> {
  double _zoom = 7;
  bool _mapReady = false;
  VoidCallback? _pendingCameraAction;

  @override
  Widget build(BuildContext context) {
    final center = const LatLng(28.3, -16.5); // Centro Canarias aproximado

    return Stack(
      children: [
        /// 🗺️ Mapa base principal
        FlutterMap(
          mapController: widget.mapCtrl,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 7,
            minZoom: 4,
            maxZoom: 18,
            onMapReady: () {
              if (!mounted) return;
              _mapReady = true;
              final pending = _pendingCameraAction;
              _pendingCameraAction = null;
              pending?.call();
            },
            onMapEvent: (event) {
              if (!mounted) return;
              if (_zoom != event.camera.zoom) {
                setState(() => _zoom = event.camera.zoom);
              }
            },
            interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
          ),
          children: [
            TileLayer(
              urlTemplate: widget.baseMapStyle.urlTemplate,
              userAgentPackageName: 'geodos.app',
              tileProvider: NetworkTileProvider(),
            ),
            MarkerLayer(markers: []), // 🔹 Aquí se renderizan los proyectos
          ],
        ),

        /// 🧭 Controles flotantes (zoom, capas, etc.)
        Positioned(
          top: 12,
          right: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ZoomControl(
                zoom: _zoom,
                onZoomIn: () {
                  final center = widget.mapCtrl.camera.center;
                  widget.mapCtrl.move(center, _zoom + 1);
                },
                onZoomOut: () {
                  final center = widget.mapCtrl.camera.center;
                  widget.mapCtrl.move(center, _zoom - 1);
                },
              ),
              const SizedBox(height: 8),
              _BaseMapControl(
                value: widget.baseMapStyle,
                onChanged: (newStyle) {
                  setState(() {
                    // Aquí podrías actualizar el estilo base del mapa
                  });
                },
              ),
            ],
          ),
        ),

        /// 🧩 Panel Flotante de Filtros
        const Positioned(
          top: 12,
          left: 12,
          child: FloatingFilterPanel(),
        ),

        /// 📊 Leyenda de categorías (opcional)
        Positioned(
          bottom: 12,
          right: 12,
          child: _Legend(
            categories: const ['Medioambiente', 'Patrimonio', 'Desarrollo'],
            total: ProjectService.lastRemoteCount,
            colorForCategory: (c) => c == 'Medioambiente'
                ? Colors.green
                : c == 'Patrimonio'
                ? Colors.brown
                : Colors.blue,
          ),
        ),
      ],
    );
  }
}

/// 🧭 Control de Zoom
class _ZoomControl extends StatelessWidget {
  final double zoom;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const _ZoomControl({
    required this.zoom,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      child: Column(
        children: [
          IconButton(
            onPressed: onZoomIn,
            icon: const Icon(Icons.add, size: 20),
          ),
          Text(zoom.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
          IconButton(
            onPressed: onZoomOut,
            icon: const Icon(Icons.remove, size: 20),
          ),
        ],
      ),
    );
  }
}

/// 🗺️ Selector de mapa base (satélite, relieve, etc.)
class _BaseMapControl extends StatelessWidget {
  final BaseMapStyle value;
  final ValueChanged<BaseMapStyle> onChanged;

  const _BaseMapControl({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: BaseMapStyle.values
              .map(
                (style) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Tooltip(
                message: style.label,
                child: InkResponse(
                  radius: 20,
                  onTap: () => onChanged(style),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: value == style
                          ? Brand.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: value == style
                            ? Brand.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Icon(
                      style.icon,
                      size: 18,
                      color: value == style
                          ? Brand.primary
                          : Colors.grey.shade800,
                    ),
                  ),
                ),
              ),
            ),
          )
              .toList(),
        ),
      ),
    );
  }
}

/// 🧩 Panel Flotante de Filtros (visual)
class FloatingFilterPanel extends StatelessWidget {
  const FloatingFilterPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      color: Colors.white.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros activos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.category_outlined, size: 16, color: Colors.blueGrey),
                SizedBox(width: 6),
                Text('Categoría: Todas'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.public_outlined, size: 16, color: Colors.blueGrey),
                SizedBox(width: 6),
                Text('Isla: Todas'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 🗂️ Leyenda de Categorías
class _Legend extends StatelessWidget {
  final List<String> categories;
  final int total;
  final Color Function(String) colorForCategory;

  const _Legend({
    required this.categories,
    required this.total,
    required this.colorForCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      color: Colors.white.withValues(alpha: 0.9),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Leyenda ($total proyectos)',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            for (final c in categories)
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: colorForCategory(c),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(c, style: const TextStyle(fontSize: 12)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
