import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (!_isInitialized) {
      bool available = await _speech.initialize(
        onStatus: (status) => print('Speech Status: $status'),
        onError: (errorNotification) => print('Speech Error: $errorNotification'),
      );
      _isInitialized = available;
      return available;
    }
    return true;
  }

  Future<void> startListening({required Function(String) onResult}) async {
    if (!_isInitialized) {
      bool available = await initialize();
      if (!available) return;
    }

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          processVoiceCommand(result.recognizedWords);
        }
      },
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  // Cloud NLP Integration Stub
  // Connect this to Dialogflow or Google Cloud Speech-to-Text
  Future<void> processVoiceCommand(String command) async {
    print("Processing command via Cloud NLP: $command");
    // Example:
    // final response = await cloudNlpService.detectIntent(command);
    // executeAction(response.action);
    
    // Simple local intent matching for demo
    if (command.toLowerCase().contains('book')) {
      print("Intent detected: BOOK_SERVICE");
    } else if (command.toLowerCase().contains('status')) {
      print("Intent detected: CHECK_STATUS");
    }
  }
}
