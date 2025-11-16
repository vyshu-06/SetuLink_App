import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class KYCService {
  final _textRecognizer = TextRecognizer();

  Future<String?> pickAndScanIDDocument() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return null;

    final inputImage = InputImage.fromFilePath(image.path);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    await _textRecognizer.close();

    // Extract relevant data from recognizedText.text e.g., name, ID number based on format
    return recognizedText.text; // You may parse further based on document type
  }
}
