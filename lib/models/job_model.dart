import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final double budget;
  final DateTime scheduledTime;
  final GeoPoint location;
  final List<String> requiredSkills;
  final List<String> images;
  final String? voiceUrl;
  final String jobStatus; // open, confirmed, in_progress, completed, disputed
  final String? assignedTo;
  final Map<String, dynamic> preferences; // e.g., {'preferredRating': 4.0}

  JobModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.budget,
    required this.scheduledTime,
    required this.location,
    required this.requiredSkills,
    required this.images,
    this.voiceUrl,
    this.jobStatus = 'open',
    this.assignedTo,
    this.preferences = const {},
  });

  factory JobModel.fromMap(Map<String, dynamic> data, String id) {
    return JobModel(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'Untitled Job',
      description: data['description'] ?? '',
      budget: (data['budget'] as num?)?.toDouble() ?? 0.0,
      scheduledTime: (data['scheduledTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      requiredSkills: List<String>.from(data['requiredSkills'] ?? []),
      images: List<String>.from(data['images'] ?? []),
      voiceUrl: data['voiceUrl'],
      jobStatus: data['jobStatus'] ?? 'open',
      assignedTo: data['assignedTo'],
      preferences: data['preferences'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'budget': budget,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'location': location,
      'requiredSkills': requiredSkills,
      'images': images,
      'voiceUrl': voiceUrl,
      'jobStatus': jobStatus,
      'assignedTo': assignedTo,
      'preferences': preferences,
    };
  }
}
