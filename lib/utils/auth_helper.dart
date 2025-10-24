import 'security.dart';

class AuthHelper {
  /// Hash password and generate salt for signup
  static String hashPasswordForSignup(String password) {
    final salt = Security.generateSalt();
    return Security.hashPasswordWithSalt(password, salt);
  }

  /// Verify password for login
  static bool verifyPassword(String password, String storedHash) {
    return Security.verifyPassword(password, storedHash);
  }

  /// Generate secure HMAC token (optional use)
  static String generateHmac(String data, String secretKey) {
    return Security.hmacSha256(data, secretKey);
  }
}
