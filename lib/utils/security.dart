import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

class Security {
  /// Hash a string using SHA-256
  static String hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate a random salt for passwords
  static String generateSalt([int length = 16]) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  /// Hash password with salt (for signup)
  static String hashPasswordWithSalt(String password, String salt) {
    final combined = '$salt$password';
    final hashed = hashString(combined);
    return '$salt:$hashed'; // store salt:hash format
  }

  /// Verify password (for login)
  static bool verifyPassword(String password, String storedHash) {
    final parts = storedHash.split(':');
    if (parts.length != 2) return false;
    final salt = parts[0];
    final hash = hashString('$salt$password');
    return hash == parts[1];
  }

  /// Optional HMAC generator (for tokens)
  static String hmacSha256(String data, String secretKey) {
    final key = utf8.encode(secretKey);
    final bytes = utf8.encode(data);
    final hmacSha = Hmac(sha256, key);
    final digest = hmacSha.convert(bytes);
    return digest.toString();
  }
}
