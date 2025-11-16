import 'dart:convert';
import 'package:crypto/crypto.dart';

class JobService {

  String generateJobId(String userId, String craftizenId, String service) {
    final input = '$userId-$craftizenId-$service-${DateTime.now().millisecondsSinceEpoch}';
    return sha256.convert(utf8.encode(input)).toString();
  }
}
