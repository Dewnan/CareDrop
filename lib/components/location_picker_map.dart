import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:caredrop/services/geoapify_service.dart';
import 'package:caredrop/theme/app_theme.dart';
import 'feedback_banner.dart';
import 'loading_indicator.dart';

/// Modal bottom sheet or screen for selecting a location on a map or searching via address autocomplete.
class LocationPickerMap extends StatefulWidget {
  final String title;
  final LatLng? initialLocation;

  const LocationPickerMap({
    super.key,
    required this.title,
    this.initialLocation,
  });

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  late LatLng _selectedLocation;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  List<GeoapifySearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingAddress = false;
  bool _isLocating = false;
  String? _resolvedAddress;
  Timer? _debounceTimer;

  // Default to Colombo center if no location provided
  static const LatLng _defaultColombo = LatLng(6.9271, 79.8612);

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? _defaultColombo;
    _fetchAddressForLocation(_selectedLocation);

    if (widget.initialLocation == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _moveToCurrentLocation();
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Fetches human-readable address for the target coordinates.
  Future<void> _fetchAddressForLocation(LatLng location) async {
    setState(() => _isLoadingAddress = true);
    final address = await GeoapifyService.reverseGeocode(
      location.latitude,
      location.longitude,
    );
    if (mounted) {
      setState(() {
        _resolvedAddress = address ?? '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
        _isLoadingAddress = false;
      });
    }
  }

  /// Handles search query changes with debounce.
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().length < 3) {
      setState(() => _searchResults = []);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isSearching = true);
      final results = await GeoapifyService.searchAddress(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  /// Selects a search result from the autocomplete dropdown list.
  void _selectSearchResult(GeoapifySearchResult result) {
    final location = LatLng(result.latitude, result.longitude);
    setState(() {
      _selectedLocation = location;
      _resolvedAddress = result.formattedAddress;
      _searchResults = [];
      _searchController.text = result.title;
    });
    _mapController.move(location, 16.0);
  }

  /// Moves map viewport to user's current GPS location and updates resolved address.
  Future<void> _moveToCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          FeedbackBanner.show(
            context,
            message: 'Location services are disabled.',
            type: FeedbackType.warning,
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            FeedbackBanner.show(
              context,
              message: 'Location permissions are denied.',
              type: FeedbackType.warning,
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          FeedbackBanner.show(
            context,
            message: 'Location permissions are permanently denied.',
            type: FeedbackType.warning,
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final userLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = userLocation;
      });
      _mapController.move(userLocation, 16.0);
      _fetchAddressForLocation(userLocation);
    } catch (e) {
      if (mounted) {
        FeedbackBanner.show(
          context,
          message: 'Failed to fetch current location: $e',
          type: FeedbackType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareDropTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: CareDropTheme.textPrimary,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'location': _selectedLocation,
                'address': _resolvedAddress ?? '',
              });
            },
            child: const Text(
              'Done',
              style: TextStyle(
                color: CareDropTheme.royalBlue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // Map View Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 15.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: (_, point) {
                setState(() {
                  _selectedLocation = point;
                });
                _fetchAddressForLocation(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'me.dewnan.caredrop',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.redAccent,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Search Bar & Autocomplete List
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search address or location...',
                      prefixIcon: const Icon(Icons.search, color: CareDropTheme.textSecondary),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchResults = []);
                                  },
                                )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                // Search Results Dropdown List
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final res = _searchResults[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.location_on_outlined,
                            color: CareDropTheme.royalBlue,
                          ),
                          title: Text(
                            res.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            res.formattedAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () => _selectSearchResult(res),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // My Location Floating Button
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton.small(
              heroTag: 'my_location_btn',
              onPressed: _isLocating ? null : _moveToCurrentLocation,
              backgroundColor: Colors.white,
              foregroundColor: CareDropTheme.royalBlue,
              elevation: 4,
              child: _isLocating
                  ? const AppLoadingIndicator(size: 18, color: CareDropTheme.royalBlue)
                  : const Icon(Icons.my_location),
            ),
          ),

          // Bottom Address Bar & Confirm Button
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Location',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: CareDropTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _isLoadingAddress
                      ? const Row(
                          children: [
                            AppLoadingIndicator(size: 14, strokeWidth: 2, color: CareDropTheme.royalBlue),
                            SizedBox(width: 8),
                            Text('Resolving address...'),
                          ],
                        )
                      : Text(
                          _resolvedAddress ?? 'Tap on map to select position',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CareDropTheme.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'location': _selectedLocation,
                          'address': _resolvedAddress ?? '',
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CareDropTheme.royalBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

