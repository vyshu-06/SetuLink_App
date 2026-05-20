import 'package:cloud_firestore/cloud_firestore.dart';

class CraftizenModel {
  final String uid;
  final String name;
  final GeoPoint location;
  final List<String> skills;
  final double rating;
  final int ratingCount;
  final bool isAvailable;
  final String? bio;
  final String? experienceLevel;
  final String? travelRadius;
  final bool isCertified;
  final double minCharge;
  final String? city;
  final DateTime? createdAt;
  final Map<String, dynamic> commonAnswers;
  final Map<String, dynamic> videoUrls;
  final bool isKycVerified;
  final String email;
  final Map<String, dynamic> preferences;

  CraftizenModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.location,
    required this.skills,
    required this.rating,
    this.ratingCount = 0,
    required this.isAvailable,
    this.bio,
    this.experienceLevel,
    this.travelRadius,
    this.isCertified = false,
    this.isKycVerified = false,
    this.minCharge = 0.0,
    this.city,
    this.createdAt,
    this.commonAnswers = const {},
    this.videoUrls = const {},
    this.preferences = const {},
  });

  factory CraftizenModel.fromMap(Map<String, dynamic> data, String uid) {
    return CraftizenModel(
      uid: uid,
      name: data['name'] ?? 'Unknown',
      email: data['email'] ?? 'N/A',
      location: data['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      skills: List<String>.from(data['skills'] ?? []),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: data['ratingCount'] ?? 0,
      isAvailable: data['isAvailable'] ?? false,
      bio: data['bio'],
      experienceLevel: data['experienceLevel'] ?? data['experienceYears']?.toString(),
      travelRadius: data['travelRadius'] ?? data['serviceRadiusKm']?.toString(),
      isCertified: data['isCertified'] ?? false,
      isKycVerified: data['kyc']?['verified'] ?? false,
      minCharge: (data['minCharge'] as num?)?.toDouble() ?? 0.0,
      city: data['city'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      commonAnswers: Map<String, dynamic>.from(data['kyc']?['commonAnswers'] ?? {}),
      videoUrls: Map<String, dynamic>.from(data['kyc']?['videoUrls'] ?? {}),
      preferences: data['preferences'] ?? {},
    );
  }
}
