import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class JobService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Basic Job CRUD
  Stream<QuerySnapshot> getJobs(String category) {
    return _db.collection('jobs').where('category', isEqualTo: category).snapshots();
  }

  Future<DocumentReference> addJob(Map<String, dynamic> jobData) {
    jobData['jobId'] = _generateJobId(jobData['title'], jobData['userId']);
    return _db.collection('jobs').add(jobData);
  }

  String _generateJobId(String title, String userId) {
    final uniqueString = "$title-$userId-${DateTime.now().millisecondsSinceEpoch}";
    return sha256.convert(utf8.encode(uniqueString)).toString();
  }

  Future<void> updateJob(String jobId, Map<String, dynamic> newData) {
    return _db.collection('jobs').doc(jobId).update(newData);
  }

  Future<void> deleteJob(String jobId) {
    return _db.collection('jobs').doc(jobId).delete();
  }

  // Job Lifecycle Management
  Future<void> postJob(Map<String, dynamic> jobData) {
    jobData['status'] = 'open';
    jobData['postedAt'] = FieldValue.serverTimestamp();
    return addJob(jobData);
  }

  Stream<QuerySnapshot> getOpenJobs() {
    return _db.collection('jobs').where('status', isEqualTo: 'open').snapshots();
  }

  Future<void> applyForJob(String jobId, String craftizenId, String craftizenName) async {
    final jobRef = _db.collection('jobs').doc(jobId);
    return jobRef.update({
      'applicants': FieldValue.arrayUnion([{
        'craftizenId': craftizenId,
        'craftizenName': craftizenName,
        'appliedAt': DateTime.now(),
      }])
    });
  }

  Future<void> acceptApplicant(String jobId, String craftizenId) {
    final jobRef = _db.collection('jobs').doc(jobId);
    return _db.runTransaction((transaction) async {
      final jobSnapshot = await transaction.get(jobRef);
      if (!jobSnapshot.exists) {
        throw Exception("Job does not exist!");
      }
      transaction.update(jobRef, {
        'status': 'assigned',
        'assignedCraftizenId': craftizenId,
        'assignedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> startJob(String jobId) {
    return updateJob(jobId, {
      'status': 'in_progress',
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeJob(String jobId) {
    return updateJob(jobId, {
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelJob(String jobId) {
    return updateJob(jobId, {'status': 'cancelled'});
  }

  // Reviews and Ratings
  Future<void> leaveReview({
    required String jobId,
    required String userId,
    required String craftizenId,
    required double rating,
    required String comment,
  }) {
    final reviewRef = _db.collection('reviews').doc();
    final craftizenRef = _db.collection('users').doc(craftizenId);

    return _db.runTransaction((transaction) async {
      transaction.set(reviewRef, {
        'jobId': jobId,
        'userId': userId,
        'craftizenId': craftizenId,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(craftizenRef, {
        'ratings': FieldValue.arrayUnion([rating]),
      });
    });
  }
}
