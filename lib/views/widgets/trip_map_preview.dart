import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/app_colors.dart';
import 'shimmer_loading.dart';
import 'map_view.dart';

class TripMapPreview extends StatefulWidget {
  /// Pickup coordinates from the trip (e.g. trip.pickupLat, trip.pickupLng).
  final LatLng pickupLocation;
  /// Drop-off coordinates from the trip (e.g. trip.dropoffLat, trip.dropoffLng).
  final LatLng dropOffLocation;
  final VoidCallback? onExpand;

  const TripMapPreview({
    super.key,
    required this.pickupLocation,
    required this.dropOffLocation,
    this.onExpand,
  });

  @override
  State<TripMapPreview> createState() => _TripMapPreviewState();
}

class _TripMapPreviewState extends State<TripMapPreview> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _hasLocationPermission = false;
  bool _isLoading = true;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Always show trip markers even if user denies location permission.
      _markers.addAll([
        Marker(
          markerId: const MarkerId('pickup_location'),
          position: widget.pickupLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Pickup Location'),
        ),
        Marker(
          markerId: const MarkerId('dropoff_location'),
          position: widget.dropOffLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Drop-off Location'),
        ),
      ]);

      // Request location permission
      final status = await Permission.location.request();
      if (!status.isGranted) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _hasLocationPermission = true;
        _currentPosition = position;
        _isLoading = false;

        // Add current location marker
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(position.latitude, position.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: const InfoWindow(title: 'Current Location'),
          ),
        );

      });

      // Move camera to show both pickup and drop-off locations
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              widget.pickupLocation.latitude < widget.dropOffLocation.latitude
                  ? widget.pickupLocation.latitude
                  : widget.dropOffLocation.latitude,
              widget.pickupLocation.longitude < widget.dropOffLocation.longitude
                  ? widget.pickupLocation.longitude
                  : widget.dropOffLocation.longitude,
            ),
            northeast: LatLng(
              widget.pickupLocation.latitude > widget.dropOffLocation.latitude
                  ? widget.pickupLocation.latitude
                  : widget.dropOffLocation.latitude,
              widget.pickupLocation.longitude > widget.dropOffLocation.longitude
                  ? widget.pickupLocation.longitude
                  : widget.dropOffLocation.longitude,
            ),
          ),
          50.0, // Padding around the bounds
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: AppColors.softCardShadow,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: _isLoading
                ? const ShimmerMapPreview()
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition != null
                          ? LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            )
                          : LatLng(
                              (widget.pickupLocation.latitude +
                                      widget.dropOffLocation.latitude) /
                                  2,
                              (widget.pickupLocation.longitude +
                                      widget.dropOffLocation.longitude) /
                                  2,
                            ),
                      zoom: 15.0,
                    ),
                    markers: _markers,
                    myLocationEnabled: _hasLocationPermission,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    zoomGesturesEnabled: false,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      if (_currentPosition != null) {
                        controller.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            15.0,
                          ),
                        );
                      }
                    },
                  ),
          ),
          Positioned(
            right: 14,
            bottom: 14,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                if (widget.onExpand != null) {
                  widget.onExpand!();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapView(
                        pickupLocation: widget.pickupLocation,
                        dropOffLocation: widget.dropOffLocation,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.softCardShadow,
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.open_in_full, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
