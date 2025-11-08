abstract class ProfileRepository {
  Future<Map<String, dynamic>> getUserProfile(String userId);
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data);
}
