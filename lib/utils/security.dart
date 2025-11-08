import 'dart:convert';
import 'package:crypto/crypto.dart';

class Security {
  // Hashing a password with a salt
  static String hashPassword(String password, String salt) {
    final saltedPassword = utf8.encode(password + salt);
    final digest = sha256.convert(saltedPassword);
    return digest.toString();
  }

  // Verifying a password against a hash
  static bool verifyPassword(String password, String salt, String hashedPassword) {
    final hashToVerify = hashPassword(password, salt);
    return hashToVerify == hashedPassword;
  }

  // Generating a random salt
  static String generateSalt() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return base64Url.encode(utf8.encode(random));
  }

  // Encrypting data (example with HMAC)
  static String encryptData(String data, String secretKey) {
    final key = utf8.encode(secretKey);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  // Decrypting data is not possible with HMAC, it's for verification.
  // This function would be for HMAC verification.
  static bool verifyHmac(String data, String secretKey, String hmacToVerify) {
    final expectedHmac = encryptData(data, secretKey);
    return expectedHmac == hmacToVerify;
  }
}
