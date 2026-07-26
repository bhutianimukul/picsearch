import 'validators.dart';

/// The category a screenshot is filed under. A superset of [DocType]: it adds
/// the keyword-classified, non-ID kinds (recipe, ticket, otp, …).
enum Category {
  aadhaar,
  pan,
  card,
  bank,
  upiQr,
  credential,
  recipe,
  ticket,
  receipt,
  otp,
  social,
  other,
}

/// Maps a validated [DocType] to its [Category].
Category categoryFromDocType(DocType t) {
  switch (t) {
    case DocType.aadhaar:
      return Category.aadhaar;
    case DocType.pan:
      return Category.pan;
    case DocType.card:
      return Category.card;
    case DocType.ifsc:
      return Category.bank;
    case DocType.upiQr:
      return Category.upiQr;
    case DocType.unknown:
      return Category.other;
  }
}

/// A single structured field pulled out of a screenshot, carrying both the full
/// [value] (kept on-device) and a display-safe [masked] form.
class ExtractedField {
  final DocType type;
  final String label; // human label, e.g. "Card number"
  final String value; // full, sensitive — never shown until revealed
  final String masked; // display-safe form
  final bool sensitive; // true → hidden by default, needs reveal

  const ExtractedField({
    required this.type,
    required this.label,
    required this.value,
    required this.masked,
    required this.sensitive,
  });
}

/// The structured result of analysing one screenshot's OCR text: what it is,
/// the fields we could verify, and any secondary tags (e.g. deletable:otp).
class AnalysisResult {
  final Category category;
  final List<ExtractedField> fields;
  final Set<String> tags;

  const AnalysisResult({
    required this.category,
    required this.fields,
    this.tags = const {},
  });
}

/// One analysed screenshot: where the image lives (on-device only), the OCR
/// text it yielded, and the structured [AnalysisResult] derived from it.
class ScreenshotRecord {
  final String imagePath;
  final String ocrText;
  final AnalysisResult analysis;

  const ScreenshotRecord({
    required this.imagePath,
    required this.ocrText,
    required this.analysis,
  });

  Category get category => analysis.category;
  List<ExtractedField> get fields => analysis.fields;
}
