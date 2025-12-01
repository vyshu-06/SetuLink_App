import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:setulink_app/models/craftizen_model.dart';
import 'package:setulink_app/models/job_model.dart';

class RecommendationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Weights for scoring
  static const double weightLocation = 0.3;
  static const double weightRating = 0.25;
  static const double weightSkill = 0.3;
  static const double weightAvailability = 0.1;
  static const double weightPreference = 0.05;

  Future<List<CraftizenModel>> getTopMatches(JobModel job, {int limit = 5}) async {
    // 1. Fetch all candidate Craftizens (In a real app, use GeoFlutterFire to filter by radius first)
    // For this implementation, we fetch all and filter in memory, or fetch strictly by active status.
    final querySnapshot = await _db.collection('users')
        .where('role', isEqualTo: 'craftizen')
        // .where('isAvailable', isEqualTo: true) // Optional: Filter basic availability at DB level
        .get();

    List<CraftizenModel> candidates = querySnapshot.docs
        .map((doc) => CraftizenModel.fromMap(doc.data(), doc.id))
        .toList();

    // 2. Score each candidate
    Map<String, double> scores = {};
    for (var craftizen in candidates) {
      scores[craftizen.uid] = computeMatchScore(craftizen, job);
    }

    // 3. Sort candidates by score descending
    candidates.sort((a, b) => (scores[b.uid] ?? 0).compareTo(scores[a.uid] ?? 0));

    // 4. Return top N
    return candidates.take(limit).toList();
  }

  // General recommendation for Home screen based on location
  Future<List<CraftizenModel>> getRecommendedCraftizens(GeoPoint userLocation, {int limit = 5}) async {
    final querySnapshot = await _db.collection('users')
        .where('role', isEqualTo: 'craftizen')
        .limit(50) // Fetch a pool to sort
        .get();

    List<CraftizenModel> candidates = querySnapshot.docs
        .map((doc) => CraftizenModel.fromMap(doc.data(), doc.id))
        .toList();

    // Simple sort by rating then distance
    candidates.sort((a, b) {
      int ratingComp = b.rating.compareTo(a.rating);
      if (ratingComp != 0) return ratingComp;
      
      double distA = _haversineDistance(userLocation.latitude, userLocation.longitude, a.location.latitude, a.location.longitude);
      double distB = _haversineDistance(userLocation.latitude, userLocation.longitude, b.location.latitude, b.location.longitude);
      return distA.compareTo(distB);
    });

    return candidates.take(limit).toList();
  }

  double computeMatchScore(CraftizenModel craftizen, JobModel job) {
    final double locationScore = _calculateLocationScore(
      job.location.latitude,
      job.location.longitude,
      craftizen.location.latitude,
      craftizen.location.longitude,
    );

    final double ratingScore = (craftizen.rating / 5.0).clamp(0.0, 1.0);

    final double skillMatchScore = _calculateSkillMatchScore(job.requiredSkills, craftizen.skills);

    final double availabilityScore = craftizen.isAvailable ? 1.0 : 0.0;

    final double preferenceMatchScore = _calculatePreferenceMatchScore(craftizen, job);

    return (weightLocation * locationScore) +
           (weightRating * ratingScore) +
           (weightSkill * skillMatchScore) +
           (weightAvailability * availabilityScore) +
           (weightPreference * preferenceMatchScore);
  }

  double _calculateLocationScore(double lat1, double lon1, double lat2, double lon2) {
    const double maxDistanceKm = 50.0; // Max distance to consider for scoring
    double distance = _haversineDistance(lat1, lon1, lat2, lon2);
    
    if (distance > maxDistanceKm) return 0.0;
    // Closer is better: 1.0 at 0km, 0.0 at maxDistanceKm
    return (1.0 - (distance / maxDistanceKm)).clamp(0.0, 1.0);
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
               cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
               sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  double _calculateSkillMatchScore(List<String> required, List<String> actual) {
    if (required.isEmpty) return 1.0; // No specific skills required
    if (actual.isEmpty) return 0.0;

    int matchCount = 0;
    for (var skill in required) {
      // Simple string match (case-insensitive)
      if (actual.any((s) => s.toLowerCase() == skill.toLowerCase())) {
        matchCount++;
      }
    }
    return (matchCount / required.length).clamp(0.0, 1.0);
  }

  double _calculatePreferenceMatchScore(CraftizenModel craftizen, JobModel job) {
    // Example preference matching logic
    double score = 0.0;
    int checks = 0;

    // Check 1: Preferred Rating
    if (job.preferences.containsKey('minRating')) {
      checks++;
      if (craftizen.rating >= (job.preferences['minRating'] as num).toDouble()) {
        score += 1.0;
      }
    }

    // Add other preference checks here...

    return checks > 0 ? (score / checks) : 0.5; // Default to 0.5 if no preferences
  }
}
