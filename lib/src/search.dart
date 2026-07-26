import 'models.dart';

// Filler words dropped from queries so natural phrasing works
// ("give me my hdfc card" → [hdfc, card]). Meaningful terms like card/wifi/pan
// are intentionally NOT here.
const _stopWords = <String>{
  'a', 'an', 'the', 'my', 'me', 'i', 'give', 'show', 'find', 'get', 'is', 'of',
  'for', 'to', 'in', 'on', 'please', 'want', 'need', 'whats', 'what', 'where',
  'wheres', 'that', 'this', 'can', 'you', 'and', 'with',
};

/// On-device search. Drops filler words, then ranks records by how many query
/// terms they contain — matches in *structured fields* score higher than loose
/// OCR text. OR-with-ranking (not strict AND) so partial / natural queries work.
List<ScreenshotRecord> searchRecords(
    List<ScreenshotRecord> records, String query) {
  final tokens = query
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9@]+'))
      .where((t) => t.length > 1 && !_stopWords.contains(t))
      .toList();
  if (tokens.isEmpty) return const [];

  final scored = <(ScreenshotRecord, int)>[];
  for (final r in records) {
    final blob = _blob(r);
    final fieldBlob =
        r.fields.map((f) => '${f.label} ${f.value}').join(' ').toLowerCase();
    var score = 0;
    for (final t in tokens) {
      if (blob.contains(t)) score += 1;
      if (fieldBlob.contains(t)) score += 2;
    }
    if (score > 0) scored.add((r, score));
  }
  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return scored.map((e) => e.$1).toList();
}

String _blob(ScreenshotRecord r) {
  final sb = StringBuffer()
    ..write(r.category.name)
    ..write(' ');
  for (final f in r.fields) {
    sb
      ..write(f.label)
      ..write(' ')
      ..write(f.value)
      ..write(' ');
  }
  sb.write(r.ocrText);
  return sb.toString().toLowerCase();
}
