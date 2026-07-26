import 'package:flutter_test/flutter_test.dart';
import 'package:snapvault/src/models.dart';
import 'package:snapvault/src/ocr_service.dart';
import 'package:snapvault/src/scan_pipeline.dart';

/// Fake OCR: returns canned text per path, so the pipeline is testable with no
/// device, camera, or ML Kit.
class FakeOcrService implements OcrService {
  final Map<String, String> _texts;
  FakeOcrService(this._texts);
  @override
  Future<String> recognize(String path) async => _texts[path] ?? '';
}

void main() {
  test('scans images into structured, categorized records', () async {
    final ocr = FakeOcrService({
      'a.png': 'HDFC Bank card 4111 1111 1111 1111',
      'b.png': 'WiFi password: hunter2',
    });

    final records = await ScanPipeline(ocr).scanAll(['a.png', 'b.png']);

    expect(records, hasLength(2));
    expect(records[0].category, Category.card);
    expect(records[0].fields.first.masked, '••••••••••••1111');
    expect(records[0].fields.first.value, '4111111111111111'); // full value kept on-device
    expect(records[1].category, Category.credential);
  });

  test('empty OCR text yields an "other" record, not a crash', () async {
    final records = await ScanPipeline(FakeOcrService({})).scanAll(['x.png']);
    expect(records.single.category, Category.other);
    expect(records.single.fields, isEmpty);
  });
}
