import 'validators.dart';
import 'models.dart';
import 'masking.dart';
import 'classifier.dart';

/// The on-device structuring pipeline: OCR text in → structured [AnalysisResult]
/// out. Pure and synchronous, so the whole "messy → structured" transform is
/// unit-testable without OCR, UI, or a network.
///
///   pixels ──(OCR, elsewhere)──▶ text ──[analyzeText]──▶ {category, fields, tags}
AnalysisResult analyzeText(String ocrText) {
  final detections = detectFromText(ocrText);
  final category = classify(ocrText, detections);
  final fields = detections.map(toField).toList();

  // Card sub-field we can read from the surrounding text: expiry (MM/YY).
  if (detections.any((d) => d.type == DocType.card)) {
    final exp = RegExp(r'\b(0[1-9]|1[0-2])\s*/\s*(\d{2})\b').firstMatch(ocrText);
    if (exp != null) {
      final v = '${exp.group(1)}/${exp.group(2)}';
      fields.add(ExtractedField(
        type: DocType.unknown,
        label: 'Expiry',
        value: v,
        masked: v,
        sensitive: false,
      ));
    }
  }

  final tags = <String>{};
  if (category == Category.otp) tags.add('deletable:otp');

  return AnalysisResult(category: category, fields: fields, tags: tags);
}
