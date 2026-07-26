import 'package:picsearch/src/models.dart';
import 'package:picsearch/src/validators.dart';

/// One labelled example: the messy OCR text, the category it should file under,
/// and which validated ID types should be extracted from it.
class EvalSample {
  final String name;
  final String ocrText;
  final Category expectedCategory;
  final Set<DocType> expectedTypes;
  const EvalSample(
    this.name,
    this.ocrText,
    this.expectedCategory, [
    this.expectedTypes = const {},
  ]);
}

/// A hand-labelled set that deliberately includes adversarial negatives — a
/// tampered card, a bad-checksum Aadhaar, a malformed PAN, a phone number, and
/// a random 16-digit string — all of which MUST be rejected (no false positives).
List<EvalSample> evalSamples() {
  // Build a genuinely valid Aadhaar, and a copy with a broken check digit.
  final aadhaar = '23456789012${verhoeffCheckDigit('23456789012')}';
  final aadhaarSpaced =
      '${aadhaar.substring(0, 4)} ${aadhaar.substring(4, 8)} ${aadhaar.substring(8, 12)}';
  final badAadhaar =
      aadhaar.substring(0, 11) + ((int.parse(aadhaar[11]) + 1) % 10).toString();

  return [
    // --- positives ---
    EvalSample('clean card', 'HDFC Bank 4539 1488 0343 6467 valid thru 05/28',
        Category.card, {DocType.card}),
    EvalSample('card, tight text', 'Debit card 4539148803436467 CVV 123',
        Category.card, {DocType.card}),
    EvalSample('valid aadhaar (spaced)', 'Aadhaar $aadhaarSpaced', Category.aadhaar,
        {DocType.aadhaar}),
    EvalSample('valid PAN', 'Income Tax PAN ABCDE1234F', Category.pan, {DocType.pan}),
    EvalSample('IFSC + account', 'HDFC Bank  IFSC HDFC0001234  A/c 0012345',
        Category.bank, {DocType.ifsc}),
    EvalSample('UPI QR payload', 'Scan to pay  upi://pay?pa=shop@okaxis&pn=Store',
        Category.upiQr, {DocType.upiQr}),
    EvalSample('wifi note', 'WiFi network OceanView_5G  password sunset2024',
        Category.credential),
    EvalSample('recipe', 'Ingredients: 2 cups flour, 1 tsp salt. Preheat oven 180C',
        Category.recipe),
    EvalSample('receipt', 'CAFE COFFEE DAY  Invoice  Grand Total Rs 450  GST 18%',
        Category.receipt),
    EvalSample('otp', '995123 is your OTP. Do not share with anyone.', Category.otp),

    // --- mixed (priority + multi-extract) ---
    EvalSample('card + IFSC', 'Card 4539 1488 0343 6467  IFSC HDFC0001234',
        Category.card, {DocType.card, DocType.ifsc}),
    EvalSample('aadhaar + card', 'Aadhaar $aadhaarSpaced  Card 4539 1488 0343 6467',
        Category.aadhaar, {DocType.aadhaar, DocType.card}),

    // --- adversarial negatives (must be rejected → no detections) ---
    EvalSample('tampered card (bad Luhn)', 'Card 4539 1488 0343 6461', Category.other),
    EvalSample('bad-checksum aadhaar', 'Aadhaar $badAadhaar', Category.other),
    EvalSample('malformed PAN', 'PAN ABCD1234F', Category.other),
    EvalSample('phone number, not an ID', 'Call me at 9876543210 tomorrow', Category.other),
    EvalSample('random 16 digits (not Luhn)', 'ref 1111 1111 1111 1111 end', Category.other),
    EvalSample('plain noise', 'meeting notes: ship the thing', Category.other),
  ];
}
