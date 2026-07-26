/// Extracts text from an image file. The real implementation
/// ([MlKitOcrService]) runs entirely on-device; tests use a fake so the scan
/// pipeline is verifiable without a device, camera, or network.
abstract class OcrService {
  Future<String> recognize(String imagePath);
}
