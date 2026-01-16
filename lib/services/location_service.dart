import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';

class LocationService {
  final Location _location = Location();
  final _geo = GeoFlutterFire();
  final _db = FirebaseFirestore.instance;

  Future<LocationData?> getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return null;
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return null;
    }

    return await _location.getLocation();
  }

  Future<void> updateUserLocation(String userId) async {
    final pos = await getCurrentLocation();
    if (pos == null) return;

    GeoFirePoint myLocation = _geo.point(latitude: pos.latitude!, longitude: pos.longitude!);
    await _db.collection('users').doc(userId).update({
      'position': myLocation.data,
    });
  }

  Stream<List<DocumentSnapshot>> getNearbyCraftizens(double lat, double lng, {double radius = 10, String? skill}) {
    GeoFirePoint center = _geo.point(latitude: lat, longitude: lng);
    var collectionReference = _db.collection('users').where('role', isEqualTo: 'craftizen');
    
    // Skill filtering would usually be done on the client side after the geo-query
    // because Firestore doesn't support multiple inequality filters easily with geo-queries.
    return _geo.collection(collectionRef: collectionReference)
        .within(center: center, radius: radius, field: 'position');
  }
}
