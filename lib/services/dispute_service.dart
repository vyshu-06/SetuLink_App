import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:setulink_app/models/dispute_model.dart';

class DisputeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collection = 'disputes';

  Future<void> createDispute({
    required String jobId,
    required String raisedBy,
    required String craftizenId,
    required String type,
    required String description,
  }) async {
    await _db.collection(collection).add({
      'jobId': jobId,
      'raisedBy': raisedBy,
      'craftizenId': craftizenId,
      'type': type,
      'description': description,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'messages': [],
      'escalationRequested': false,
    });
  }

  Stream<List<DisputeModel>> getUserDisputes(String userId) {
    return _db
        .collection(collection)
        .where('raisedBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
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
}
