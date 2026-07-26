import 'validators.dart';
import 'models.dart';

/// Keyword heuristics for screenshots that carry no validated ID — the "fuzzy"
/// types. Order matters: earlier checks win. (This is the on-device baseline;
/// the BYOK LLM can later refine "other" and ambiguous cases.)
Category classifyByKeywords(String text) {
  final t = text.toLowerCase();
  bool has(List<String> ks) => ks.any((k) => t.contains(k));

  if (has(['one-time password', 'otp', 'do not share', 'verification code'])) {
    return Category.otp;
  }
  if (has(['wifi', 'wi-fi', 'ssid', 'passphrase', 'password'])) {
    return Category.credential;
  }
  if (has(['ingredients', 'recipe', 'preheat', 'tbsp', 'tsp'])) {
    return Category.recipe;
  }
  if (has(['pnr', 'boarding', 'gate ', 'seat ', 'departure', 'e-ticket'])) {
    return Category.ticket;
  }
  if (has(['invoice', 'receipt', 'subtotal', 'gst', 'amount paid', 'grand total'])) {
    return Category.receipt;
  }
  return Category.other;
}

// When several IDs appear in one screenshot, the most sensitive wins the
// category. (A card photo that also shows an IFSC files as "card".)
const _priority = <DocType>[
  DocType.aadhaar,
  DocType.card,
  DocType.pan,
  DocType.upiQr,
  DocType.ifsc,
];

/// Primary category for a screenshot. A validated ID always beats keywords —
/// verification is stronger signal than a fuzzy word match.
Category classify(String text, List<Detection> detections) {
  for (final type in _priority) {
    if (detections.any((d) => d.type == type)) {
      return categoryFromDocType(type);
    }
  }
  return classifyByKeywords(text);
}
