import 'validators.dart';
import 'models.dart';

/// Masks all but the last [revealLast] alphanumerics with a bullet. Separators
/// are ignored when counting. Values at/under [revealLast] are returned as-is
/// (nothing meaningful to hide).
String mask(String value, {int revealLast = 4}) {
  final visible = value.replaceAll(RegExp(r'[\s-]'), '');
  if (visible.length <= revealLast) return value;
  final keep = visible.substring(visible.length - revealLast);
  return '${'•' * (visible.length - revealLast)}$keep';
}

/// Turns a validated [Detection] into a display-ready [ExtractedField], deciding
/// per type what is sensitive (mask by default) vs public (show in full).
///
/// Sensitive: card / Aadhaar / PAN — masked, revealed only behind biometric.
/// Public: IFSC (a bank branch code) / UPI VPA — shown in full, safe to copy.
ExtractedField toField(Detection d) {
  switch (d.type) {
    case DocType.aadhaar:
      return ExtractedField(
        type: d.type,
        label: 'Aadhaar number',
        value: d.value,
        masked: mask(d.value),
        sensitive: true,
      );
    case DocType.card:
      return ExtractedField(
        type: d.type,
        label: 'Card number',
        value: d.value,
        masked: mask(d.value),
        sensitive: true,
      );
    case DocType.pan:
      return ExtractedField(
        type: d.type,
        label: 'PAN',
        value: d.value,
        masked: mask(d.value),
        sensitive: true,
      );
    case DocType.ifsc:
      return ExtractedField(
        type: d.type,
        label: 'IFSC',
        value: d.value,
        masked: d.value,
        sensitive: false,
      );
    case DocType.upiQr:
      return ExtractedField(
        type: d.type,
        label: 'UPI ID',
        value: d.value,
        masked: d.value,
        sensitive: false,
      );
    case DocType.unknown:
      return ExtractedField(
        type: d.type,
        label: 'Value',
        value: d.value,
        masked: d.value,
        sensitive: false,
      );
  }
}
