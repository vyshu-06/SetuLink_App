import 'dart:convert';
import 'package:crypto/crypto.dart';

class Security {
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  bool verifySignature(String payload, String signature, String secret) {
    final hmac = Hmac(sha256, utf8.encode(secret));
    final digest = hmac.convert(utf8.encode(payload));
    return signature == digest.toString();
  }
}
