import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:caredrop/services/geoapify_service.dart';
import 'package:caredrop/theme/app_theme.dart';

/// Renders a map preview displaying pickup and dropoff markers along with the driving route polyline.
class RoutePreviewMap extends StatefulWidget {
  final LatLng pickupLocation;
  final LatLng dropoffLocation;
  final String? pickupAddress;
  final String? dropoffAddress;
  final bool isAccepted;

  const RoutePreviewMap({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.pickupAddress,
    this.dropoffAddress,
    this.isAccepted = false,
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

  /// Opens native external map apps for turn-by-turn navigation via url_launcher and map_launcher.
  Future<void> _openExternalNavigation(LatLng coords, String title) async {
    final lat = coords.latitude;
    final lng = coords.longitude;
    final googleUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    final appleUrl = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng');

    try {
      if (await canLaunchUrl(googleUrl)) {
        await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
        return;
      } else if (await canLaunchUrl(appleUrl)) {
        await launchUrl(appleUrl, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      await MapLauncher.directions(LocationCoords(lat, lng, title: title)).show();
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
        if (widget.isAccepted) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _openExternalNavigation(
                    widget.pickupLocation,
                    widget.pickupAddress ?? 'Pickup Location',
                  ),
                  icon: const Icon(Icons.navigation, size: 16, color: Colors.green),
                  label: const Text(
                    'Open Map (Pickup)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: CareDropTheme.royalBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _openExternalNavigation(
                    widget.dropoffLocation,
                    widget.dropoffAddress ?? 'Dropoff Location',
                  ),
                  icon: const Icon(Icons.navigation, size: 16, color: CareDropTheme.royalBlue),
                  label: const Text(
                    'Open Map (Dropoff)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: CareDropTheme.royalBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
