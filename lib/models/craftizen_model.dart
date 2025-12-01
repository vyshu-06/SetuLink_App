import 'package:cloud_firestore/cloud_firestore.dart';

class CraftizenModel {
  final String uid;
  final String name;
  final GeoPoint location;
  final List<String> skills;
  final double rating;
  final bool isAvailable;
  final Map<String, dynamic> preferences; // e.g., {'minPrice': 100}

  CraftizenModel({
    required this.uid,
    required this.name,
    required this.location,
    required this.skills,
    required this.rating,
    required this.isAvailable,
    this.preferences = const {},
  });

  factory CraftizenModel.fromMap(Map<String, dynamic> data, String uid) {
    return CraftizenModel(
      uid: uid,
      name: data['name'] ?? 'Unknown',
      location: data['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      skills: List<String>.from(data['skills'] ?? []),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      isAvailable: data['isAvailable'] ?? false,
      preferences: data['preferences'] ?? {},
    );
  }
}
