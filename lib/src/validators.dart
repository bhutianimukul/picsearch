/// Pure, dependency-free validation + extraction for the Indian ID / financial
/// artifacts PicSearch finds in screenshots.
///
/// The design bet (see decisions.md §5): don't *guess* a document's type from
/// "does this text look like an Aadhaar" — *verify* it with the real checksum.
/// That kills false positives on messy OCR output and is trivially unit-testable
/// with known valid/invalid values.
///
/// No Flutter, no I/O — runs under `dart test` in milliseconds.
library;

// ---------------------------------------------------------------------------
// Luhn (ISO/IEC 7812) — debit/credit card numbers.
// ---------------------------------------------------------------------------

/// Returns true if [digits] (13–19 digits, no separators) passes the Luhn
/// checksum used by payment cards.
bool isValidLuhn(String digits) {
  if (!RegExp(r'^\d{13,19}$').hasMatch(digits)) return false;
  var sum = 0;
  var alternate = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var n = digits.codeUnitAt(i) - 0x30; // '0'
    if (alternate) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alternate = !alternate;
  }
  return sum % 10 == 0;
}

// ---------------------------------------------------------------------------
// Verhoeff — the actual algorithm behind Aadhaar's 12th (check) digit.
// ---------------------------------------------------------------------------

// Dihedral group D5 multiplication table.
const _d = <List<int>>[
  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
  [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
  [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
  [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
  [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
  [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
  [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
  [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
  [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
  [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
];

// Permutation table (period 8).
const _p = <List<int>>[
  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
  [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
  [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
  [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
  [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
  [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
  [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
  [7, 0, 4, 6, 9, 1, 3, 2, 5, 8],
];

// Multiplicative inverse table.
const _inv = <int>[0, 4, 3, 2, 1, 5, 6, 7, 8, 9];

/// Returns true if [digits] (including its trailing check digit) is a valid
/// Verhoeff number.
bool isValidVerhoeff(String digits) {
  if (!RegExp(r'^\d+$').hasMatch(digits)) return false;
  var c = 0;
  final reversed = digits.split('').reversed.toList();
  for (var i = 0; i < reversed.length; i++) {
    final digit = reversed[i].codeUnitAt(0) - 0x30;
    c = _d[c][_p[i % 8][digit]];
  }
  return c == 0;
}

/// Computes the Verhoeff check digit for a [payload] that does NOT yet include
/// one. Used to generate valid test vectors and to validate our own logic.
int verhoeffCheckDigit(String payload) {
  var c = 0;
  final reversed = payload.split('').reversed.toList();
  for (var i = 0; i < reversed.length; i++) {
    final digit = reversed[i].codeUnitAt(0) - 0x30;
    c = _d[c][_p[(i + 1) % 8][digit]];
  }
  return _inv[c];
}

// ---------------------------------------------------------------------------
// Document-specific validators.
// ---------------------------------------------------------------------------

/// Aadhaar: 12 digits, first digit 2–9 (0/1 are reserved), Verhoeff-valid.
bool isValidAadhaar(String s) {
  final d = s.replaceAll(RegExp(r'[\s-]'), '');
  if (!RegExp(r'^[2-9]\d{11}$').hasMatch(d)) return false;
  return isValidVerhoeff(d);
}

final _panRegExp = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');

/// PAN: 5 letters, 4 digits, 1 letter (e.g. ABCDE1234F).
bool isValidPan(String s) => _panRegExp.hasMatch(s.toUpperCase());

final _ifscRegExp = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');

/// IFSC: 4-letter bank code, a mandatory '0', then 6 alphanumerics.
bool isValidIfsc(String s) => _ifscRegExp.hasMatch(s.toUpperCase());

/// Parses a `upi://pay?...` deep link (the payload inside a UPI QR) into its
/// query parameters. Returns null if it isn't a UPI URI.
///
/// Common keys: `pa` (payee VPA), `pn` (payee name), `am` (amount), `cu`.
Map<String, String>? parseUpiUri(String s) {
  final trimmed = s.trim();
  if (!trimmed.toLowerCase().startsWith('upi://')) return null;
  final q = trimmed.indexOf('?');
  if (q < 0) return <String, String>{};
  final out = <String, String>{};
  for (final pair in trimmed.substring(q + 1).split('&')) {
    if (pair.isEmpty) continue;
    final eq = pair.indexOf('=');
    if (eq < 0) {
      out[Uri.decodeComponent(pair)] = '';
    } else {
      out[Uri.decodeComponent(pair.substring(0, eq))] =
          Uri.decodeComponent(pair.substring(eq + 1));
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Detection over messy OCR text.
// ---------------------------------------------------------------------------

enum DocType { aadhaar, pan, card, ifsc, upiQr, unknown }

/// A single validated thing found inside a screenshot's OCR text.
class Detection {
  final DocType type;

  /// Normalized value (digits stripped of separators, codes upper-cased).
  final String value;

  /// The substring as it appeared in the source text.
  final String raw;

  const Detection(this.type, this.value, this.raw);

  @override
  bool operator ==(Object other) =>
      other is Detection &&
      other.type == type &&
      other.value == value &&
      other.raw == raw;

  @override
  int get hashCode => Object.hash(type, value, raw);

  @override
  String toString() => 'Detection($type, $value)';
}

/// Scans free-form OCR [text] and returns only detections that pass their
/// real validation. This is the "verify, don't guess" core the UI sits on.
///
/// Order matters: PAN/IFSC are matched on alphanumeric tokens; Aadhaar and
/// card numbers are matched on digit runs (allowing spaces/hyphens between
/// groups, which is how OCR usually reads them) and then checksum-validated.
List<Detection> detectFromText(String text) {
  final results = <Detection>[];
  final seen = <String>{}; // dedupe on "type:value"

  void add(DocType type, String value, String raw) {
    if (seen.add('$type:$value')) {
      results.add(Detection(type, value, raw));
    }
  }

  // PAN
  for (final m in RegExp(r'\b[A-Z]{5}[0-9]{4}[A-Z]\b').allMatches(text.toUpperCase())) {
    add(DocType.pan, m.group(0)!, m.group(0)!);
  }

  // IFSC
  for (final m in RegExp(r'\b[A-Z]{4}0[A-Z0-9]{6}\b').allMatches(text.toUpperCase())) {
    add(DocType.ifsc, m.group(0)!, m.group(0)!);
  }

  // UPI QR payload
  for (final m in RegExp(r'upi://[^\s]+', caseSensitive: false).allMatches(text)) {
    final raw = m.group(0)!;
    final parsed = parseUpiUri(raw);
    if (parsed != null) {
      add(DocType.upiQr, parsed['pa'] ?? raw, raw);
    }
  }

  // Digit runs (with internal spaces/hyphens) → Aadhaar or card.
  for (final m in RegExp(r'\b\d[\d\s-]{10,21}\d\b').allMatches(text)) {
    final raw = m.group(0)!;
    final digits = raw.replaceAll(RegExp(r'[\s-]'), '');
    if (digits.length == 12 && isValidAadhaar(digits)) {
      add(DocType.aadhaar, digits, raw);
    } else if (isValidLuhn(digits)) {
      add(DocType.card, digits, raw);
    }
  }

  return results;
}
