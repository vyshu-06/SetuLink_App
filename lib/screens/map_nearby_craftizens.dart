import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';

class MapNearbyCraftizens extends StatefulWidget {
  final String skillCategory;
  const MapNearbyCraftizens({required this.skillCategory, Key? key}) : super(key: key);

  @override
  State<MapNearbyCraftizens> createState() => _MapNearbyCraftizensState();
}

class _MapNearbyCraftizensState extends State<MapNearbyCraftizens> {
  LatLng? _currentPosition;
  final Location _location = Location();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Set<Marker> _craftizenMarkers = {};
  final double _radiusInKm = 10.0; //  Only show within 10 km radius

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      final locData = await _location.getLocation();
      setState(() {
        _currentPosition = LatLng(locData.latitude!, locData.longitude!);
      });

      await _loadNearbyCraftizens();
    } catch (e) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching location: $e')),
        );
      }
    }
  }

  Future<void> _loadNearbyCraftizens() async {
    if (_currentPosition == null) return;

    final snapshot = await _db
        .collection('users')
        .where('role', isEqualTo: 'craftizen')
        .where('skills', arrayContains: widget.skillCategory)
        .get();

    Set<Marker> markers = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final GeoPoint? geoPoint = data['location'];
      if (geoPoint == null) continue;

      final distance = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        geoPoint.latitude,
        geoPoint.longitude,
      );

      if (distance <= _radiusInKm) {
        markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(geoPoint.latitude, geoPoint.longitude),
            infoWindow: InfoWindow(
              title: data['name'] ?? 'Unknown',
              snippet: '${data['skills'].join(', ')} • ${distance.toStringAsFixed(1)} ${context.tr('km_away')}',
            ),
          ),
        );
      }
    }

    if(mounted){
      setState(() {
        _craftizenMarkers = markers;
      });
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const BilingualText(textKey: 'nearby_craftizens_title')),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition!,
          zoom: 13.5,
        ),
        markers: _craftizenMarkers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
