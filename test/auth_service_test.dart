import 'package:flutter_test/flutter_test.dart';
import 'package:setulink_app/services/auth_service.dart';

void main() {
  final authService = AuthService();

  test('Password hashing should return consistent string', () {
    final hash1 = authService.hashPassword('password123');
    final hash2 = authService.hashPassword('password123');
    expect(hash1, equals(hash2));
  });

  // Add more tests for signInWithEmail, registerWithEmail with mock/fake Firebase if possible
}
