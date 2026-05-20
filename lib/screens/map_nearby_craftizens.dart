import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  List<Marker> _craftizenMarkers = [];
  final double _radiusInKm = 10.0; 

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    final locationData = await _locationService.getCurrentLocation();
    if (locationData != null && mounted) {
      setState(() {
        _currentPosition = LatLng(locationData.latitude!, locationData.longitude!);
      });
      _locationService
          .getNearbyCraftizens(
        locationData.latitude!,
        locationData.longitude!,
        radius: _radiusInKm,
      )
          .listen((craftizens) {
        _updateMarkers(craftizens);
      });
    }
  }

  void _updateMarkers(List<DocumentSnapshot> craftizenDocs) {
    List<Marker> markers = [];
    for (var doc in craftizenDocs) {
      final data = doc.data() as Map<String, dynamic>; 
      final Map<String, dynamic>? positionData = data['position'];
      if (positionData == null) continue;
      
      final GeoPoint? geoPoint = positionData['geopoint'];
      if (geoPoint == null) continue;

      final List<dynamic>? skills = data['skills'];
      if (skills != null && skills.contains(widget.skillCategory)) {
          markers.add(
            Marker(
              point: LatLng(geoPoint.latitude, geoPoint.longitude),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['name'] ?? 'Unknown', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text((data['skills'] as List<dynamic>?)?.join(', ') ?? ''),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
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
      appBar: AppBar(title: const BilingualText(textKey: 'Nearby Craftizens')),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: _currentPosition!,
                initialZoom: 13.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.setulink_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location, color: Colors.red, size: 30),
                    ),
                    ..._craftizenMarkers,
                  ],
                ),
              ],
            ),
    );
  }
}
