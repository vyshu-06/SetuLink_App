import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:setulink_app/services/voice_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceService Integration Tests', () {
    late VoiceService voiceService;
    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      voiceService = VoiceService();
      // Mock platform channel for speech_to_text
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugin.csdcorp.com/speech_to_text'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          if (methodCall.method == 'initialize') {
            return true;
          } else if (methodCall.method == 'listen') {
             return true;
          } else if (methodCall.method == 'stop') {
            return true;
          }
          return null;
        }
      );
      
      // Mock flutter_tts
       TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          return 1;
        }
      );
    });

    tearDown(() {
      log.clear();
      // Reset handlers
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugin.csdcorp.com/speech_to_text'), 
        null
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter_tts'), 
        null
      );
    });

    test('Initialize Voice Service', () async {
      bool result = await voiceService.initialize();
      expect(result, isTrue);
    });

    test('Speak text using TTS', () async {
      await voiceService.speak("Hello");
    });

    test('Process Voice Command Stub', () async {
      await voiceService.processVoiceCommand("I want to book a plumber");
    });
  });
}
