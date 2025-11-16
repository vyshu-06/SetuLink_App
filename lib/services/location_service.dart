import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:geoflutterfire2/geoflutterfire2.dart'; 
import 'package:location/location.dart'; 
 
class LocationService { 
  final geo = GeoFlutterFire(); 
  final FirebaseFirestore _db = FirebaseFirestore.instance; 
  final Location _location = Location(); 
 
  // Get current device location with permission checks 
  Future<GeoPoint?> getCurrentGeoPoint() async { 
    bool serviceEnabled = await _location.serviceEnabled(); 
    if (!serviceEnabled) { 
      serviceEnabled = await _location.requestService(); 
      if (!serviceEnabled) return null; 
    } 
 
    PermissionStatus permissionGranted = await _location.hasPermission(); 
    if (permissionGranted == PermissionStatus.denied) { 
      permissionGranted = await _location.requestPermission(); 
      if (permissionGranted != PermissionStatus.granted) return null; 
    } 
 
    final locData = await _location.getLocation(); 
    return GeoPoint(locData.latitude!, locData.longitude!); 
  } 
 
  // Query craftizens within radius (in kilometers) of current location, filtered by skill 
  Stream<List<DocumentSnapshot>> getNearbyCraftizens({ 
    required GeoPoint center, 
    required double radiusInKm, 
    required String skillCategory, 
  }) { 
    final centerGeo = geo.point(latitude: center.latitude, longitude: center.longitude); 
    final collectionRef = _db.collection('users').where('role', isEqualTo: 'craftizen').where('skillCategory', isEqualTo: skillCategory); 
 
    return geo.collection(collectionRef: collectionRef).within( 
          center: centerGeo, 
          radius: radiusInKm, 
          field: 'location', 
          strictMode: true, 
        ); 
  } 
} 