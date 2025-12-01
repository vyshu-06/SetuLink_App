import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Localization Tests', () {
    late Map<String, dynamic> enData;
    late Map<String, dynamic> teData;
    // late Map<String, dynamic> hiData; // If hi.json exists and we want to test it

    setUpAll(() async {
      // Load JSON files directly
      final enFile = File('assets/translations/en.json');
      final teFile = File('assets/translations/te.json');
      
      enData = json.decode(await enFile.readAsString());
      teData = json.decode(await teFile.readAsString());
    });

    test('English translation keys should exist', () {
      expect(enData['welcome_slogan'], isNotNull);
      expect(enData['login'], equals('Login'));
    });

    test('Telugu translation keys should exist and match English keys structure', () {
      // Verify all keys in EN exist in TE
      for (var key in enData.keys) {
        expect(teData.containsKey(key), isTrue, reason: 'Missing key in te.json: $key');
      }
    });

    test('Check specific Telugu translations', () {
      expect(teData['welcome_slogan'], isNotEmpty);
      // Example check based on provided te.json content
      // expect(teData['login'], equals('లాగిన్')); 
    });
  });
}
