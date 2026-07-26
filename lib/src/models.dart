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

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'label': label,
        'value': value,
        'masked': masked,
        'sensitive': sensitive,
      };

  factory ExtractedField.fromJson(Map<String, dynamic> j) => ExtractedField(
        type: DocType.values.byName(j['type'] as String),
        label: j['label'] as String,
        value: j['value'] as String,
        masked: j['masked'] as String,
        sensitive: j['sensitive'] as bool,
      );
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

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'fields': fields.map((f) => f.toJson()).toList(),
        'tags': tags.toList(),
      };

  factory AnalysisResult.fromJson(Map<String, dynamic> j) => AnalysisResult(
        category: Category.values.byName(j['category'] as String),
        fields: (j['fields'] as List)
            .map((e) => ExtractedField.fromJson(e as Map<String, dynamic>))
            .toList(),
        tags: (j['tags'] as List).map((e) => e as String).toSet(),
      );
}

/// One analysed screenshot: where the image lives (on-device only), the OCR
/// text it yielded, and the structured [AnalysisResult] derived from it.
class ScreenshotRecord {
  final String imagePath;
  final String ocrText;
  final AnalysisResult analysis;

  /// Fields the user added by hand (e.g. CVV, cardholder name) — merged after
  /// the auto-extracted ones.
  final List<ExtractedField> extra;

  /// The AI-assigned group name, set when a Gemini key is active (see
  /// AppState.regroupWithAi). Null until grouped; the Vault falls back to the
  /// on-device [category] when this is absent.
  final String? aiGroup;

  /// Whether the AI flagged this as clearable junk (a one-time OTP, a duplicate,
  /// transient noise), with a short reason. Set in the same pass as [aiGroup].
  final bool aiClearable;
  final String? aiClearReason;

  /// The gallery (MediaStore) asset id this record came from, when scanned from
  /// the device gallery — lets us optionally delete the original. Null for
  /// picked/shared images (no gallery asset to delete).
  final String? assetId;

  const ScreenshotRecord({
    required this.imagePath,
    required this.ocrText,
    required this.analysis,
    this.extra = const [],
    this.aiGroup,
    this.aiClearable = false,
    this.aiClearReason,
    this.assetId,
  });

  Category get category => analysis.category;
  List<ExtractedField> get fields => [...analysis.fields, ...extra];

  ScreenshotRecord copyWith({
    String? imagePath,
    List<ExtractedField>? extra,
    String? aiGroup,
    bool? aiClearable,
    String? aiClearReason,
    String? assetId,
  }) =>
      ScreenshotRecord(
        imagePath: imagePath ?? this.imagePath,
        ocrText: ocrText,
        analysis: analysis,
        extra: extra ?? this.extra,
        aiGroup: aiGroup ?? this.aiGroup,
        aiClearable: aiClearable ?? this.aiClearable,
        aiClearReason: aiClearReason ?? this.aiClearReason,
        assetId: assetId ?? this.assetId,
      );

  Map<String, dynamic> toJson() => {
        'imagePath': imagePath,
        'ocrText': ocrText,
        'analysis': analysis.toJson(),
        'extra': extra.map((f) => f.toJson()).toList(),
        'aiGroup': aiGroup,
        'aiClearable': aiClearable,
        'aiClearReason': aiClearReason,
        'assetId': assetId,
      };

  factory ScreenshotRecord.fromJson(Map<String, dynamic> j) => ScreenshotRecord(
        imagePath: j['imagePath'] as String,
        ocrText: j['ocrText'] as String,
        analysis: AnalysisResult.fromJson(j['analysis'] as Map<String, dynamic>),
        extra: ((j['extra'] as List?) ?? const [])
            .map((e) => ExtractedField.fromJson(e as Map<String, dynamic>))
            .toList(),
        aiGroup: j['aiGroup'] as String?,
        aiClearable: (j['aiClearable'] as bool?) ?? false,
        aiClearReason: j['aiClearReason'] as String?,
        assetId: j['assetId'] as String?,
      );
}
