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
    await _db.collection(collection).doc(job.id).set(job.toMap(), SetOptions(merge: true));
  }

  Stream<List<JobModel>> getJobsStream(String userId, {bool isCraftizen = false}) {
    Query query = _db.collection(collection);
    if (isCraftizen) {
      query = query.where('assignedTo', isEqualTo: userId);
    } else {
      query = query.where('userId', isEqualTo: userId);
    }
    return query
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs.map((doc) => JobModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<JobModel>> getOpenJobsForCraftizen(List<String> skills) {
    if (skills.isEmpty) return Stream.value([]); // Return empty if craftizen has no skills

    return _db
        .collection(collection)
        .where('jobStatus', isEqualTo: 'open')
        .where('requiredSkills', arrayContainsAny: skills)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => JobModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<QuerySnapshot> getRawJobsSnapshot(String userId) {
    return _db.collection(collection)
        .where('userId', isEqualTo: userId)
        .snapshots(includeMetadataChanges: true);
  }
}
