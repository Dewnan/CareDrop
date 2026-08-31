import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:caredrop/services/geoapify_service.dart';
import 'package:caredrop/theme/app_theme.dart';

/// Renders a map preview displaying pickup and dropoff markers along with the driving route polyline.
class RoutePreviewMap extends StatefulWidget {
  final LatLng pickupLocation;
  final LatLng dropoffLocation;
  final String? pickupAddress;
  final String? dropoffAddress;

  const RoutePreviewMap({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.pickupAddress,
    this.dropoffAddress,
  });

  @override
  State<RoutePreviewMap> createState() => _RoutePreviewMapState();
}

class _RoutePreviewMapState extends State<RoutePreviewMap> {
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  /// Fetches the route points connecting pickup and dropoff locations.
  Future<void> _loadRoute() async {
    final points = await GeoapifyService.fetchRoutePoints(
      widget.pickupLocation,
      widget.dropoffLocation,
    );
    if (mounted) {
      setState(() {
        _routePoints = points;
        _isLoadingRoute = false;
      });
    }
  }

  /// Opens native external map apps for turn-by-turn navigation via map_launcher.
  Future<void> _openExternalNavigation(LocationCoords destinationCoords, String title) async {
    try {
      await MapLauncher.directions(destinationCoords).show();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bounds = LatLngBounds.fromPoints([
      widget.pickupLocation,
      widget.dropoffLocation,
    ]);

    return Column(
      children: [
        Container(
          height: 220,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(40),
                  ),
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'me.dewnan.caredrop',
                  ),
                  if (_routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 4.0,
                          color: CareDropTheme.royalBlue,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      // Pickup Marker
                      Marker(
                        point: widget.pickupLocation,
                        width: 36,
                        height: 36,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.green,
                          size: 36,
                        ),
                      ),
                      // Dropoff Marker
                      Marker(
                        point: widget.dropoffLocation,
                        width: 36,
                        height: 36,
                        child: const Icon(
                          Icons.flag,
                          color: Colors.redAccent,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_isLoadingRoute)
                const Positioned(
                  top: 12,
                  right: 12,
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 6),
                          Text('Routing...', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openExternalNavigation(
                  LocationCoords(
                    widget.pickupLocation.latitude,
                    widget.pickupLocation.longitude,
                    title: 'Pickup Location',
                  ),
                  'Pickup Location',
                ),
                icon: const Icon(Icons.navigation, size: 16, color: Colors.green),
                label: const Text(
                  'Navigate to Pickup',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openExternalNavigation(
                  LocationCoords(
                    widget.dropoffLocation.latitude,
                    widget.dropoffLocation.longitude,
                    title: 'Dropoff Location',
                  ),
                  'Dropoff Location',
                ),
                icon: const Icon(Icons.navigation, size: 16, color: Colors.redAccent),
                label: const Text(
                  'Navigate to Dropoff',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
