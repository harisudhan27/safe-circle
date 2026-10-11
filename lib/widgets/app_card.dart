import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final BorderRadius borderRadius;
  final double elevation;

  const AppCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.borderColor = AppColors.border,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveShadowColor = borderColor.withValues(alpha: 0.18);

    return Padding(
      padding: margin,
      child: Material(
        color: color,
        elevation: elevation,
        shadowColor: effectiveShadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          splashColor: color.withValues(alpha: 0.12),
          highlightColor: color.withValues(alpha: 0.08),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// SafeCircle logo. Uses assets/images/logo.png and falls back to an
/// icon version if the image file is missing.
class SafeLogo extends StatelessWidget {
  final double size;
  const SafeLogo({super.key, this.size = 90});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size * 2.2,
      height: size * 2.2,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) => _fallback(),
    );
  }

  Widget _fallback() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.shield_outlined, size: size, color: AppColors.green),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: size * 0.36,
              fontWeight: FontWeight.w800,
            ),
            children: const [
              TextSpan(
                text: 'Safe',
                style: TextStyle(color: AppColors.darkGreen),
              ),
              TextSpan(
                text: 'Circle',
                style: TextStyle(color: AppColors.green),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Real OpenStreetMap (no API key). Same name/API as the old placeholder,
/// so every screen keeps working. Centres on the phone's real GPS position.
class MapPlaceholder extends StatefulWidget {
  final double height;
  final String? caption;
  final bool locateCurrent;
  final LatLng? position;
  final double? circleRadiusMeters;
  final List<MapPin> pins;
  final bool includePositionInFit;
  const MapPlaceholder({
    super.key,
    this.height = 200,
    this.caption,
    this.locateCurrent = true,
    this.position,
    this.circleRadiusMeters,
    this.pins = const [],
    this.includePositionInFit = false,
  });

  @override
  State<MapPlaceholder> createState() => _MapPlaceholderState();
}

class _MapPlaceholderState extends State<MapPlaceholder> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(0, 0);
  bool _hasGps = false;
  bool _mapReady = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    if (widget.position != null) {
      _center = widget.position!;
      _hasGps = true;
    } else if (widget.locateCurrent) {
      _load();
    } else {
      _locationError = 'No shared location data available.';
    }
  }

  @override
  void didUpdateWidget(covariant MapPlaceholder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pins.isNotEmpty) {
      if (widget.includePositionInFit && widget.position != null) {
        _center = widget.position!;
        _hasGps = true;
        _locationError = null;
      } else if (!_hasGps) {
        _center = widget.position ?? widget.pins.first.position;
        _hasGps = true;
        _locationError = null;
      }
      if ((widget.includePositionInFit &&
              (widget.position != oldWidget.position ||
                  widget.circleRadiusMeters != oldWidget.circleRadiusMeters)) ||
          widget.pins.length != oldWidget.pins.length ||
          (widget.includePositionInFit &&
              widget.pins.asMap().entries.any((entry) {
                final index = entry.key;
                if (index >= oldWidget.pins.length) return true;
                final oldPosition = oldWidget.pins[index].position;
                return entry.value.position.latitude != oldPosition.latitude ||
                    entry.value.position.longitude != oldPosition.longitude;
              }))) {
        _fitPins();
      }
    } else if (widget.position != oldWidget.position &&
        widget.position != null) {
      _center = widget.position!;
      _hasGps = true;
      if (_mapReady) {
        _mapController.move(widget.position!, _mapController.camera.zoom);
      }
      _locationError = null;
    } else if (widget.position == null &&
        oldWidget.position != null &&
        !widget.locateCurrent) {
      _hasGps = false;
      _mapReady = false;
      _locationError = 'No shared location data available.';
    }
  }

  void _onMapReady() {
    _mapReady = true;
    _fitPins();
  }

  void _fitPins() {
    if (!_mapReady) return;
    final points = widget.pins.map((pin) => pin.position).toList();
    if (widget.includePositionInFit && widget.position != null) {
      points.add(widget.position!);
      final radius = widget.circleRadiusMeters;
      if (radius != null && radius > 0) {
        final latitudeOffset = radius / 111320;
        final longitudeOffset =
            radius /
            (111320 * math.cos(widget.position!.latitude * math.pi / 180))
                .abs()
                .clamp(1, double.infinity);
        points.addAll([
          LatLng(
            widget.position!.latitude + latitudeOffset,
            widget.position!.longitude,
          ),
          LatLng(
            widget.position!.latitude - latitudeOffset,
            widget.position!.longitude,
          ),
          LatLng(
            widget.position!.latitude,
            widget.position!.longitude + longitudeOffset,
          ),
          LatLng(
            widget.position!.latitude,
            widget.position!.longitude - longitudeOffset,
          ),
        ]);
      }
    }
    if (points.length < 2) return;
    final first = points.first;
    if (!points
        .skip(1)
        .any(
          (point) =>
              point.latitude != first.latitude ||
              point.longitude != first.longitude,
        )) {
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
    );
  }

  Future<void> _load() async {
    final result = await LocationService.getCurrent();
    final pos = result.position;
    if (!mounted) return;
    if (pos == null) {
      setState(() => _locationError = result.error);
      return;
    }
    setState(() {
      _center = LatLng(pos.latitude, pos.longitude);
      _hasGps = true;
      _locationError = null;
    });
  }

  void _zoom(double change) {
    if (!_mapReady) return;
    final camera = _mapController.camera;
    final zoom = (camera.zoom + change).clamp(2.0, 19.0).toDouble();
    _mapController.move(camera.center, zoom);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (_hasGps)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 16,
                minZoom: 2,
                maxZoom: 19,
                onMapReady: _onMapReady,
                interactionOptions: const InteractionOptions(
                  flags:
                      InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.safecircle',
                ),
                if (widget.circleRadiusMeters != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _center,
                        radius: widget.circleRadiusMeters!,
                        useRadiusInMeter: true,
                        color: AppColors.green.withValues(alpha: 0.16),
                        borderColor: AppColors.green,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (widget.includePositionInFit && widget.position != null)
                      Marker(
                        point: widget.position!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.home,
                          color: AppColors.darkGreen,
                          size: 32,
                        ),
                      )
                    else if (widget.pins.isEmpty)
                      Marker(
                        point: _center,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.red,
                          size: 36,
                        ),
                      ),
                    ...widget.pins.map(
                      (pin) => Marker(
                        point: pin.position,
                        width: 76,
                        height: 58,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              constraints: const BoxConstraints(maxWidth: 76),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                pin.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(Icons.location_on, color: pin.color, size: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Container(
              color: AppColors.grey,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_off_outlined,
                    color: AppColors.muted,
                    size: 34,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _locationError ?? 'Getting GPS location...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          if (_hasGps)
            Positioned(
              top: 8,
              right: 8,
              child: Column(
                children: [
                  _mapZoomButton(
                    tooltip: 'Zoom in',
                    icon: Icons.add,
                    onPressed: () => _zoom(1),
                  ),
                  const SizedBox(height: 6),
                  _mapZoomButton(
                    tooltip: 'Zoom out',
                    icon: Icons.remove,
                    onPressed: () => _zoom(-1),
                  ),
                ],
              ),
            ),
          if (widget.caption != null)
            Positioned(
              bottom: 22,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.caption!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          const Positioned(
            bottom: 2,
            right: 6,
            child: Text(
              '© OpenStreetMap contributors',
              style: TextStyle(fontSize: 9, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapZoomButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class MapPin {
  final LatLng position;
  final String label;
  final Color color;

  const MapPin({
    required this.position,
    required this.label,
    this.color = AppColors.red,
  });
}
