import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Note: The geo-querying functionality has been temporarily removed
  // because the geoflutterfire_plus package was causing a dependency conflict.
  // This service can be updated with a new geo-query package in the future.

  Stream<List<DocumentSnapshot>> getNearbyCraftizens(double lat, double lng, double radius) {
    // Placeholder implementation - does not perform a geo-query.
    // This will need to be replaced with a proper geo-query implementation.
    return _db
        .collection('users')
        .where('role', isEqualTo: 'craftizen')
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }
}
