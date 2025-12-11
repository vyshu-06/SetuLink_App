import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:setulink_app/models/dispute_model.dart';

class DisputeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collection = 'disputes';

  Future<void> raiseDispute({
    required String jobId,
    required String raiserId,
    required String respondentId,
    required String reason,
    required String description,
  }) async {
    await _db.collection(collection).add({
      'jobId': jobId,
      'raiserId': raiserId,
      'respondentId': respondentId,
      'reason': reason,
      'description': description,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'messages': [],
      'escalationRequested': false,
    });
  }

  Future<void> createDispute({
    required String jobId,
    required String raisedBy,
    required String craftizenId,
    required String type,
    required String description,
  }) async {
    // Legacy support or alias for raiseDispute if needed, 
    // but updating to match raiseDispute signature would be cleaner if refactoring.
    // For now, mapping arguments to match the structure.
    await raiseDispute(
      jobId: jobId,
      raiserId: raisedBy,
      respondentId: craftizenId,
      reason: type,
      description: description,
    );
  }

  Stream<List<DisputeModel>> getUserDisputes(String userId) {
    return _db
        .collection(collection)
        .where('raiserId', isEqualTo: userId) // Updated to match new schema
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => DisputeModel.fromSnapshot(doc)).toList());
  }

  // Admin: Get all disputes, optionally filtered by status
  Stream<List<DisputeModel>> getAllDisputes({String? status}) {
    Query query = _db.collection(collection).orderBy('createdAt', descending: true);
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => DisputeModel.fromSnapshot(doc)).toList());
  }

  Stream<DisputeModel> getDispute(String disputeId) {
    return _db
        .collection(collection)
        .doc(disputeId)
        .snapshots()
        .map((doc) => DisputeModel.fromSnapshot(doc));
  }

  Future<void> sendMessage(String disputeId, String senderId, String message) async {
    final msgData = {
      'senderId': senderId,
      'message': message,
      'timestamp': Timestamp.now(),
    };

    await _db.collection(collection).doc(disputeId).update({
      'messages': FieldValue.arrayUnion([msgData]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> requestEscalation(String disputeId) async {
    await _db.collection(collection).doc(disputeId).update({
      'escalationRequested': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> resolveDispute(String disputeId, String outcome, String resolutionNote) async {
    await _db.collection(collection).doc(disputeId).update({
      'status': 'resolved',
      'outcome': outcome, // e.g., 'refund_issued', 'claim_rejected'
      'resolutionNote': resolutionNote,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }
}
