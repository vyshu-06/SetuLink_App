import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:setulink_app/models/job_model.dart';

class JobService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collection = 'jobs';

  String generateJobId(String userId, String craftizenId, String service) {
    final input = '$userId-$craftizenId-$service-${DateTime.now().millisecondsSinceEpoch}';
    return sha256.convert(utf8.encode(input)).toString();
  }

  Future<void> createJob(JobModel job) async {
    // Conflict Resolution: Use set with merge option if updating, or add new.
    // Using set here to specify ID if needed, or let Firestore auto-generate if ID is null.
    // Since JobModel has an ID, we use set.
    await _db.collection(collection).doc(job.id).set({
      'title': job.title,
      'location': job.location,
      'requiredSkills': job.requiredSkills,
      'preferences': job.preferences,
      'createdAt': FieldValue.serverTimestamp(),
      'jobStatus': 'open',
    }, SetOptions(merge: true));
  }

  // Stream jobs with offline metadata support
  Stream<List<JobModel>> getJobsStream(String userId, {bool isCraftizen = false}) {
    Query query = _db.collection(collection);
    if (isCraftizen) {
      query = query.where('assignedTo', isEqualTo: userId);
    } else {
      query = query.where('userId', isEqualTo: userId);
    }

    // includeMetadataChanges: true allows us to receive events even for local cache updates
    // and inspect snapshot.metadata.isFromCache
    return query
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          // You can inspect snapshot.metadata.isFromCache here if needed for logging
          return snapshot.docs.map((doc) => JobModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
        });
  }
  
  // Method to get raw snapshot to check metadata in UI if needed
  Stream<QuerySnapshot> getRawJobsSnapshot(String userId) {
    return _db.collection(collection)
        .where('userId', isEqualTo: userId)
        .snapshots(includeMetadataChanges: true);
  }
}
