import 'analyzer.dart';
import 'models.dart';
import 'ocr_service.dart';

/// Ties OCR to the structuring pipeline: image path → OCR text →
/// [analyzeText] → a structured [ScreenshotRecord].
class ScanPipeline {
  final OcrService _ocr;
  const ScanPipeline(this._ocr);

  Future<ScreenshotRecord> scanOne(String imagePath) async {
    final text = await _ocr.recognize(imagePath);
    return ScreenshotRecord(
      imagePath: imagePath,
      ocrText: text,
      analysis: analyzeText(text),
    );
  }

  /// Scans images sequentially.
  // ponytail: sequential keeps ML Kit's native memory bounded on large batches;
  // parallelise only if scan throughput becomes a real complaint.
  Future<List<ScreenshotRecord>> scanAll(Iterable<String> paths) async {
    final records = <ScreenshotRecord>[];
    for (final path in paths) {
      records.add(await scanOne(path));
    }
    return records;
  }
}
