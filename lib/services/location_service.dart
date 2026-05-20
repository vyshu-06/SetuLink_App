import 'package:flutter/foundation.dart';
import 'package:location/location.dart' as loc;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:setulink_app/firebase_options.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class LocationService {
  final loc.Location _location = loc.Location();
  final _geo = GeoFlutterFire();
  final _db = FirebaseFirestore.instance;
  StreamSubscription? _globalGpsSubscription;

  Future<loc.LocationData?> getCurrentLocation() async {
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return null;
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return null;
    }

    return await _location.getLocation();
  }

  /// Starts a continuous location tracking for Craftizens.
  /// Updates Firestore for discovery and RTDB for active jobs.
  void startGlobalTracking(String userId) async {
    stopGlobalTracking(); // Clean up existing if any

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      _globalGpsSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen((Position position) {
        _handleGpsUpdate(userId, position);
      }, onError: (e) => debugPrint('Global GPS Error: $e'));
    }
  }

  void stopGlobalTracking() {
    _globalGpsSubscription?.cancel();
    _globalGpsSubscription = null;
  }

  void _handleGpsUpdate(String userId, Position pos) async {
    // 1. Update Firestore for nearby search
    GeoFirePoint myLocation = _geo.point(latitude: pos.latitude, longitude: pos.longitude);
    
    String? cityName;
    if (!kIsWeb) {
      try {
        List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) cityName = placemarks.first.locality;
      } catch (_) {}
    }

    _db.collection('users').doc(userId).update({
      'position': myLocation.data,
      if (cityName != null) 'city': cityName,
      'lastActive': FieldValue.serverTimestamp(),
    });

    // 2. Sync with any ACTIVE jobs in Realtime Database
    try {
      final activeJobs = await _db.collection('jobs')
          .where('assignedTo', isEqualTo: userId)
          .where('jobStatus', whereIn: ['confirmed', 'on_the_way', 'arrived', 'in_progress'])
          .get();

      for (var job in activeJobs.docs) {
        final tripId = job.id.replaceAll(RegExp(r'[.#$\[\]]'), '_');
        String? dbUrl = DefaultFirebaseOptions.currentPlatform.databaseURL;
        if (dbUrl == null || dbUrl.isEmpty) {
          dbUrl = 'https://setulink-app-fb-default-rtdb.asia-southeast1.firebasedatabase.app';
        }
        
        FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: dbUrl,
        ).ref("active_trips/$tripId/driver_location")
        .set({
          "latitude": pos.latitude,
          "longitude": pos.longitude,
          "heading": pos.heading,
          "timestamp": ServerValue.timestamp,
        });
      }
    } catch (e) {
      debugPrint('Background RTDB sync error: $e');
    }
  }

  Future<void> updateUserLocation(String userId) async {
    final pos = await getCurrentLocation();
    if (pos == null) return;
    _handleGpsUpdate(userId, Position(
      latitude: pos.latitude!,
      longitude: pos.longitude!,
      timestamp: DateTime.now(),
      accuracy: pos.accuracy ?? 0,
      altitude: pos.altitude ?? 0,
      heading: pos.heading ?? 0,
      speed: pos.speed ?? 0,
      speedAccuracy: pos.speedAccuracy ?? 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    ));
  }

  Stream<DocumentSnapshot> getUserLocationStream(String userId) {
    return _db.collection('users').doc(userId).snapshots();
  }

  Stream<List<DocumentSnapshot>> getNearbyCraftizens(double lat, double lng, {double radius = 10, String? skill}) {
    GeoFirePoint center = _geo.point(latitude: lat, longitude: lng);
    var collectionReference = _db.collection('users').where('role', isEqualTo: 'craftizen');
    
    return _geo.collection(collectionRef: collectionReference)
        .within(center: center, radius: radius, field: 'position');
  }
}
