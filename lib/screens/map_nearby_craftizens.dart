import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:setulink_app/services/location_service.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';

class MapNearbyCraftizens extends StatefulWidget {
  final String skillCategory;
  const MapNearbyCraftizens({required this.skillCategory, Key? key}) : super(key: key);

  @override
  State<MapNearbyCraftizens> createState() => _MapNearbyCraftizensState();
}

class _MapNearbyCraftizensState extends State<MapNearbyCraftizens> {
  final LocationService _locationService = LocationService();
  LatLng? _currentPosition;
  Set<Marker> _craftizenMarkers = {};
  final double _radiusInKm = 10.0; 

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    // Note: Temporary fixed location since getCurrentGeoPoint was removed.
    // In a real implementation, you would use a location package to get the current location.
    final userLocation = const GeoPoint(20.5937, 78.9629); // Example center of India
    if (mounted) {
      setState(() {
        _currentPosition = LatLng(userLocation.latitude, userLocation.longitude);
      });
      _locationService
          .getNearbyCraftizens(
        userLocation.latitude,
        userLocation.longitude,
        _radiusInKm,
      )
          .listen((craftizens) {
        _updateMarkers(craftizens);
      });
    }
  }

  void _updateMarkers(List<DocumentSnapshot> craftizenDocs) {
    Set<Marker> markers = {};
    for (var doc in craftizenDocs) {
      final data = doc.data() as Map<String, dynamic>; // Explicitly cast to Map
      final GeoPoint? geoPoint = data['location'];
      if (geoPoint == null) continue;

      // Filter by skill category locally since the service is simplified
      final List<dynamic>? skills = data['skills'];
      if (skills != null && skills.contains(widget.skillCategory)) {
          markers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(geoPoint.latitude, geoPoint.longitude),
              infoWindow: InfoWindow(
                title: data['name'] ?? 'Unknown',
                snippet: (data['skills'] as List<dynamic>?)?.join(', '), // Safe navigation and join
              ),
            ),
          );
      }
    }

    if (mounted) {
      setState(() {
        _craftizenMarkers = markers;
      });
    }
  }

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
