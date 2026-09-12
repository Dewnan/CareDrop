import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/geoapify_service.dart';
import '../../theme/app_theme.dart';

/// Renders a live map screen for patients to view real-time helper position and route to destination.
class PatientLiveHelperMapScreen extends StatefulWidget {
  final String taskId;

  const PatientLiveHelperMapScreen({
    super.key,
    required this.taskId,
  });

  @override
  State<PatientLiveHelperMapScreen> createState() => _PatientLiveHelperMapScreenState();
}

class _PatientLiveHelperMapScreenState extends State<PatientLiveHelperMapScreen> {
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;

  LatLng? _pickupPos;
  LatLng? _dropoffPos;
  LatLng? _helperPos;

  /// Loads route polyline connecting current helper location to destination.
  Future<void> _loadRoute(LatLng origin, LatLng destination) async {
    if (_isLoadingRoute) return;
    setState(() {
      _isLoadingRoute = true;
    });

    final points = await GeoapifyService.fetchRoutePoints(origin, destination);
    if (mounted) {
      setState(() {
        _routePoints = points;
        _isLoadingRoute = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareDropTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: CareDropTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Live Helper Map',
          style: TextStyle(
            color: CareDropTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _helperPos == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data();
          final title = data?['title'] as String? ?? 'Care Task';
          final progressStep = data?['progressStep'] as String? ?? 'taskAccepted';
          final category = data?['category'] as String? ?? 'all';

          final double? pLat = (data?['pickupLat'] ?? data?['latitude'])?.toDouble();
          final double? pLng = (data?['pickupLng'] ?? data?['longitude'])?.toDouble();
          final double? dLat = data?['dropoffLat']?.toDouble();
          final double? dLng = data?['dropoffLng']?.toDouble();

          final double defaultLat = pLat ?? 3.1390;
          final double defaultLng = pLng ?? 101.6869;

          _pickupPos = LatLng(defaultLat, defaultLng);
          _dropoffPos = dLat != null && dLng != null ? LatLng(dLat, dLng) : null;
          // Helper offset or reported live location
          final double? hLat = data?['helperLat']?.toDouble();
          final double? hLng = data?['helperLng']?.toDouble();
          _helperPos = LatLng(hLat ?? (defaultLat - 0.004), hLng ?? (defaultLng - 0.003));

          if (_routePoints.isEmpty && !_isLoadingRoute) {
            final dest = (progressStep == 'inProgress' && _dropoffPos != null) ? _dropoffPos! : _pickupPos!;
            _loadRoute(_helperPos!, dest);
          }

          final markers = <Marker>[
            // Helper Marker
            Marker(
              point: _helperPos!,
              width: 50,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  color: CareDropTheme.royalBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 28),
              ),
            ),
            // Destination Marker
            Marker(
              point: _pickupPos!,
              width: 44,
              height: 44,
              child: Container(
                decoration: BoxDecoration(
                  color: CareDropTheme.tealPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.location_on, color: Colors.white, size: 24),
              ),
            ),
          ];

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _helperPos!,
                  initialZoom: 14.5,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.caredrop.app',
                  ),
                  if (_routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          color: CareDropTheme.royalBlue,
                          strokeWidth: 4.5,
                        ),
                      ],
                    ),
                  MarkerLayer(markers: markers),
                ],
              ),

              // Bottom Info Card Overlay
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.near_me_rounded, color: CareDropTheme.royalBlue, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              category == 'queue' ? 'Helper is en route to patient' : 'Helper is moving towards location',
                              style: const TextStyle(color: CareDropTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
