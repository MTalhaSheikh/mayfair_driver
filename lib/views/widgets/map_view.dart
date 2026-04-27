import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapView extends StatefulWidget {
  final LatLng pickupLocation;
  final LatLng dropOffLocation;

  const MapView({
    super.key,
    required this.pickupLocation,
    required this.dropOffLocation,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final Completer<GoogleMapController> _controllerCompleter = Completer();
  final Set<Marker> _markers = {};
  bool _hasLocationPermission = false;

  LatLng get _midpoint => LatLng(
        (widget.pickupLocation.latitude + widget.dropOffLocation.latitude) / 2,
        (widget.pickupLocation.longitude + widget.dropOffLocation.longitude) /
            2,
      );

  LatLngBounds get _tripBounds {
    final lats = [
      widget.pickupLocation.latitude,
      widget.dropOffLocation.latitude,
    ];
    final lngs = [
      widget.pickupLocation.longitude,
      widget.dropOffLocation.longitude,
    ];
    return LatLngBounds(
      southwest: LatLng(lats.reduce((a, b) => a < b ? a : b),
          lngs.reduce((a, b) => a < b ? a : b)),
      northeast: LatLng(lats.reduce((a, b) => a > b ? a : b),
          lngs.reduce((a, b) => a > b ? a : b)),
    );
  }

  @override
  void initState() {
    super.initState();
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
    _resolveLocationPermission();
  }

  Future<void> _resolveLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (!mounted) return;
    setState(() {
      _hasLocationPermission =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_controllerCompleter.isCompleted) {
      _controllerCompleter.complete(controller);
    }

    // Post-frame delay is required on iOS: the Metal renderer needs one
    // layout pass after onMapCreated before it accepts camera commands.
    // Without this the map renders grey/blank on iOS.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 150));
      try {
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(_tripBounds, 60.0),
        );
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _controllerCompleter.future
        .then((c) => c.dispose())
        .catchError((_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _midpoint,
          zoom: 12.0,
        ),
        markers: _markers,
        myLocationEnabled: _hasLocationPermission,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
        mapToolbarEnabled: true,
        onMapCreated: _onMapCreated,
      ),
    );
  }
}
