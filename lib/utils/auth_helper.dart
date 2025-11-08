import './security.dart';

class AuthHelper {
  // Example of using the Security class for hashing passwords.
  static String createHashedPassword(String password) {
    final salt = Security.generateSalt();
    // CORRECT: Call the existing hashPassword method
    return Security.hashPassword(password, salt);
  }

  // Example of verifying a password.
  static bool checkPassword(String password, String salt, String hashedPassword) {
    // CORRECT: Call the existing verifyPassword method
    return Security.verifyPassword(password, salt, hashedPassword);
  }

  // Example of creating a signature for data verification.
  static String createDataSignature(String data, String secret) {
    // CORRECT: Call the existing encryptData method (which is actually an HMAC)
    return Security.encryptData(data, secret);
  }
}
