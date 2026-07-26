import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'ocr_service.dart';

/// On-device OCR **and** QR/barcode decoding via Google ML Kit — nothing leaves
/// the phone. Any decoded barcode payload (e.g. a UPI QR's
/// `upi://pay?pa=…&pn=…&am=…`) is appended to the recognized text, so the pure
/// [analyzeText] pipeline extracts it without knowing barcodes exist. Isolated
/// here so only the app entrypoint depends on the plugins (the pipeline and its
/// tests stay plugin-free).
class MlKitOcrService implements OcrService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  final BarcodeScanner _barcode = BarcodeScanner();

  @override
  Future<String> recognize(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer.processImage(input);
    final parts = <String>[recognized.text];
    try {
      for (final b in await _barcode.processImage(input)) {
        final v = b.rawValue;
        if (v != null && v.trim().isNotEmpty) parts.add(v.trim());
      }
    } catch (_) {
      // Barcode decoding is best-effort; the OCR text is still returned.
    }
    return parts.join('\n');
  }

  /// Release native resources when the service is no longer needed.
  Future<void> dispose() async {
    await _recognizer.close();
    await _barcode.close();
  }
}
