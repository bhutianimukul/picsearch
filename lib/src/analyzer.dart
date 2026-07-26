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

  final tags = <String>{};
  if (category == Category.otp) tags.add('deletable:otp');

  return AnalysisResult(category: category, fields: fields, tags: tags);
}
