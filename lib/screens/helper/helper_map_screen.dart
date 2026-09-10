import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/feedback_banner.dart';
import '../../models/task_model.dart';
import '../../providers/app_state.dart';
import '../../services/geoapify_service.dart';
import '../../services/task_service.dart';
import '../../theme/app_theme.dart';
import 'upload_proof_screen.dart';

/// Renders 2-part interactive map navigation for task helpers routing to pickup and dropoff locations.
class HelperMapScreen extends StatefulWidget {
  final TaskModel? task;

  const HelperMapScreen({super.key, this.task});

  @override
  State<HelperMapScreen> createState() => _HelperMapScreenState();
}

class _HelperMapScreenState extends State<HelperMapScreen> {
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;
  bool _isUpdatingStatus = false;
  bool _hasLocationError = false;

  LatLng? _resolvedHelperPos;
  LatLng? _resolvedPickupPos;
  LatLng? _resolvedDropoffPos;

  @override
  void initState() {
    super.initState();
    _loadRouteForCurrentPhase();
  }

  /// Resolves exact LatLng coordinates dynamically via task model, Geoapify geocoding, or current GPS device location.
  Future<LatLng?> _resolveLocation({
    required double? lat,
    required double? lng,
    required String? addressQuery,
  }) async {
    // 1. Task Model explicit coordinates
    if (lat != null && lng != null) {
      return LatLng(lat, lng);
    }

    // 2. Geoapify address geocoding
    if (addressQuery != null && addressQuery.trim().isNotEmpty) {
      final cleanAddress = addressQuery.replaceAll('(select via map)', '').replaceAll(', ,', '').trim();
      if (cleanAddress.isNotEmpty) {
        final geocoded = await GeoapifyService.geocodeAddress(cleanAddress);
        if (geocoded != null) return geocoded;
      }
    }

    // 3. Option A: Device Current GPS location
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (isEnabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(timeLimit: Duration(seconds: 4)),
          );
          return LatLng(pos.latitude, pos.longitude);
        }
      }
    } catch (_) {}

    // 4. Option B: Return null on complete failure
    return null;
  }

  /// Queries the helper's current device GPS position or provides an offset fallback near pickup point.
  Future<LatLng> _getHelperCurrentPosition(LatLng pickupPos) async {
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (isEnabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(timeLimit: Duration(seconds: 4)),
          );
          return LatLng(pos.latitude, pos.longitude);
        }
      }
    } catch (_) {}
    return LatLng(pickupPos.latitude - 0.005, pickupPos.longitude - 0.005);
  }

  TaskModel? _overrideTask;

  /// Calculates coordinates and loads polyline route points based on current navigation phase.
  Future<void> _loadRouteForCurrentPhase() async {
    final appState = context.read<CareDropAppState>();
    final task = _overrideTask ?? appState.activeTask ?? widget.task;

    if (task == null) {
      if (mounted) setState(() => _isLoadingRoute = false);
      return;
    }

    final isDropoffPhase = task.progressStep == TaskProgressStep.inProgress ||
        task.progressStep == TaskProgressStep.uploadProof;

    final pickupPos = await _resolveLocation(
      lat: task.pickupLat,
      lng: task.pickupLng,
      addressQuery: (task.pickupAddress != null && task.pickupAddress!.isNotEmpty)
          ? task.pickupAddress
          : task.hospital,
    );

    final dropoffPos = await _resolveLocation(
      lat: task.dropoffLat ?? task.latitude,
      lng: task.dropoffLng ?? task.longitude,
      addressQuery: (task.dropoffAddress != null && task.dropoffAddress!.isNotEmpty)
          ? task.dropoffAddress
          : task.locationDetail,
    );

    if (pickupPos == null && dropoffPos == null) {
      if (mounted) {
        setState(() {
          _hasLocationError = true;
          _isLoadingRoute = false;
        });
        FeedbackBanner.show(
          context,
          message: 'Unable to resolve task location. Please enable location services or check address.',
          type: FeedbackType.error,
        );
      }
      return;
    }

    final validPickup = pickupPos ?? dropoffPos!;
    final validDropoff = dropoffPos ?? pickupPos!;
    final helperPos = await _getHelperCurrentPosition(validPickup);

    if (mounted) {
      setState(() {
        _resolvedHelperPos = helperPos;
        _resolvedPickupPos = validPickup;
        _resolvedDropoffPos = validDropoff;
        _hasLocationError = false;
      });
    }

    final LatLng startPos = isDropoffPhase ? validPickup : helperPos;
    final LatLng endPos = isDropoffPhase ? validDropoff : validPickup;

    if (mounted) setState(() => _isLoadingRoute = true);

    final points = await GeoapifyService.fetchRoutePoints(startPos, endPos);

    if (mounted) {
      setState(() {
        _routePoints = points.isNotEmpty ? points : [startPos, endPos];
        _isLoadingRoute = false;
      });
    }
  }

  /// Opens native external navigation app like Google Maps or Apple Maps.
  Future<void> _launchExternalMap(LatLng coords, String title) async {
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
    } catch (_) {
      if (!mounted) return;
      FeedbackBanner.show(
        context,
        message: 'Could not launch external map application.',
        type: FeedbackType.error,
      );
    }
  }

  /// Advances task state from pickup confirmation to dropoff phase.
  Future<void> _handleConfirmPickup(TaskModel task) async {
    setState(() => _isUpdatingStatus = true);
    final appState = context.read<CareDropAppState>();

    try {
      await TaskService.updateTaskProgress(
        taskId: task.id,
        step: TaskProgressStep.inProgress,
        helperName: appState.currentUserModel?.fullName ?? appState.helperUser.fullName,
      );
      appState.updateTaskProgressStep(TaskProgressStep.inProgress);

      final updatedTask = task.copyWith(progressStep: TaskProgressStep.inProgress);

      if (mounted) {
        setState(() {
          _overrideTask = updatedTask;
        });
      }

      if (!mounted) return;
      FeedbackBanner.show(
        context,
        message: 'Pickup confirmed! Routing to dropoff destination.',
        type: FeedbackType.success,
      );

      await _loadRouteForCurrentPhase();
    } catch (e) {
      if (!mounted) return;
      FeedbackBanner.show(
        context,
        message: 'Failed to update pickup status.',
        type: FeedbackType.error,
      );
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<CareDropAppState>();
    final task = _overrideTask ?? appState.activeTask ?? widget.task;

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Navigation Map')),
        body: const Center(
          child: Text('No active task to navigate.'),
        ),
      );
    }

    if (_resolvedPickupPos == null || _resolvedDropoffPos == null) {
      if (_hasLocationError) {
        return Scaffold(
          appBar: AppBar(title: const Text('Navigation Map')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off_rounded, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to Resolve Location',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Could not determine GPS coordinates for this task. Please enable device location services or verify address.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: CareDropTheme.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CareDropTheme.royalBlue,
                    ),
                    onPressed: _isLoadingRoute ? null : () => _loadRouteForCurrentPhase(),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('Retry Location Search', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Skeleton / Loading UI view while coordinates resolve
      return Scaffold(
        backgroundColor: CareDropTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Loading Map Route...'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  color: CareDropTheme.royalBlue,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Resolving Route & Navigation...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: CareDropTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Fetching pickup coordinates and live GPS...',
                style: TextStyle(
                  fontSize: 13,
                  color: CareDropTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isDropoffPhase = task.progressStep == TaskProgressStep.inProgress ||
        task.progressStep == TaskProgressStep.uploadProof;

    final LatLng pickupPos = _resolvedPickupPos!;
    final LatLng dropoffPos = _resolvedDropoffPos!;

    final LatLng startPos = isDropoffPhase
        ? pickupPos
        : (_resolvedHelperPos ?? LatLng(pickupPos.latitude - 0.005, pickupPos.longitude - 0.005));

    final LatLng targetPos = isDropoffPhase ? dropoffPos : pickupPos;

    final displayTitle = isDropoffPhase ? 'Dropoff Location' : 'Pickup Location';
    final displayAddress = isDropoffPhase
        ? (task.dropoffAddress ?? task.locationDetail.replaceAll('(select via map)', '').trim())
        : (task.pickupAddress ?? task.hospital);

    final bounds = LatLngBounds.fromPoints([startPos, targetPos]);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Interactive Map Canvas
            FlutterMap(
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(50),
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
                        strokeWidth: 5.0,
                        color: CareDropTheme.royalBlue,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (!isDropoffPhase)
                      Marker(
                        point: startPos,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: CareDropTheme.royalBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.navigation, color: Colors.white, size: 22),
                        ),
                      ),
                    Marker(
                      point: targetPos,
                      width: 44,
                      height: 44,
                      child: Icon(
                        isDropoffPhase ? Icons.flag_rounded : Icons.location_on_rounded,
                        color: isDropoffPhase ? Colors.redAccent : Colors.green,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Routing indicator overlay
            if (_isLoadingRoute)
              Positioned(
                top: 80,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Calculating route...', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),

            // Top Status Bar Banner Overlay
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDropoffPhase
                            ? Colors.redAccent.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDropoffPhase ? Icons.flag : Icons.my_location,
                        color: isDropoffPhase ? Colors.redAccent : Colors.green,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDropoffPhase ? 'PHASE 2: TO DROPOFF' : 'PHASE 1: TO PICKUP',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: CareDropTheme.royalBlue,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            displayAddress.isNotEmpty ? displayAddress : displayTitle,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: CareDropTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Actions Overlay
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: CareDropTheme.cardBorderColor),
                              foregroundColor: CareDropTheme.textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text(
                              'Close',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: CareDropTheme.royalBlue),
                              foregroundColor: CareDropTheme.royalBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _launchExternalMap(targetPos, displayTitle),
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: const Text(
                              'Open in Maps',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDropoffPhase
                            ? CareDropTheme.royalBlue
                            : Colors.green.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isUpdatingStatus
                          ? null
                          : () {
                              if (!isDropoffPhase) {
                                _handleConfirmPickup(task);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const UploadProofScreen(),
                                  ),
                                );
                              }
                            },
                      child: _isUpdatingStatus
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isDropoffPhase
                                  ? 'Arrived at Destination & Complete Trip'
                                  : 'Confirm Pickup & Route to Dropoff',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

