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

  // UPI payee name — from the QR's pn= param if present, else a name line sitting
  // right next to the VPA in the OCR text.
  if (detections.any((d) => d.type == DocType.upiQr)) {
    final name = upiPayeeName(ocrText);
    if (name != null) {
      fields.add(ExtractedField(
        type: DocType.unknown,
        label: 'Payee name',
        value: name,
        masked: name,
        sensitive: false,
      ));
    }
  }

  final tags = <String>{};
  if (category == Category.otp) tags.add('deletable:otp');

  return AnalysisResult(category: category, fields: fields, tags: tags);
}

/// The UPI payee's name. First choice: the `pn=` param of a `upi://…` link
/// (URL-decoded) — deterministic. Fallback: a Title-Case name line immediately
/// above/below a VPA in the OCR text — a heuristic for screenshots that print
/// only the handle. Returns null when neither is confident.
String? upiPayeeName(String text) {
  // 1) explicit pn= in a upi:// link
  final pn = RegExp(r'[?&]pn=([^&\s]+)', caseSensitive: false).firstMatch(text);
  if (pn != null) {
    final v = Uri.decodeComponent(pn.group(1)!.replaceAll('+', ' ')).trim();
    if (v.isNotEmpty) return v;
  }
  // 2) a name line next to a VPA
  final lines = text.split(RegExp(r'[\r\n]+')).map((l) => l.trim()).toList();
  final vpa = RegExp(r'[\w.-]{2,}@[a-z]', caseSensitive: false);
  final nameLine = RegExp(r'^[A-Z][a-zA-Z]+(?: [A-Z][a-zA-Z.]+){0,3}$');
  const stop = {
    'scan', 'pay', 'upi', 'gpay', 'paytm', 'phonepe', 'bhim', 'google pay',
    'phone pe', 'amount', 'total', 'paying', 'pay to'
  };
  bool looksLikeName(String l) =>
      l.length <= 40 && nameLine.hasMatch(l) && !stop.contains(l.toLowerCase());
  for (var i = 0; i < lines.length; i++) {
    if (!vpa.hasMatch(lines[i])) continue;
    for (final j in [i - 1, i + 1, i - 2]) {
      if (j >= 0 && j < lines.length && looksLikeName(lines[j])) return lines[j];
    }
  }
  return null;
}
