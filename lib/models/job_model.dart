import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id;
  final String title;
  final GeoPoint location;
  final List<String> requiredSkills;
  final Map<String, dynamic> preferences; // e.g., {'preferredRating': 4.0}

  JobModel({
    required this.id,
    required this.title,
    required this.location,
    required this.requiredSkills,
    this.preferences = const {},
  });

  factory JobModel.fromMap(Map<String, dynamic> data, String id) {
    return JobModel(
      id: id,
      title: data['title'] ?? 'Untitled Job',
      location: data['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      requiredSkills: List<String>.from(data['requiredSkills'] ?? []),
      preferences: data['preferences'] ?? {},
    );
  }
}
