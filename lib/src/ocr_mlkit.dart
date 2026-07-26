import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'ocr_service.dart';

/// On-device OCR via Google ML Kit — nothing leaves the phone. Isolated in its
/// own file so nothing but the app entrypoint depends on the plugin (keeps the
/// pipeline and its tests plugin-free).
class MlKitOcrService implements OcrService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<String> recognize(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer.processImage(input);
    return recognized.text;
  }

  /// Release native resources when the service is no longer needed.
  Future<void> dispose() => _recognizer.close();
}
