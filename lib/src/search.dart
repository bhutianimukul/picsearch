import 'models.dart';

/// On-device search over analysed screenshots. A record matches when *every*
/// query token appears in its searchable blob (category + field labels/values +
/// OCR text). Records whose structured fields match rank above those matching
/// only loose OCR text — a verified card beats an incidental mention.
List<ScreenshotRecord> searchRecords(
    List<ScreenshotRecord> records, String query) {
  final tokens = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return const [];

  final matched = <(ScreenshotRecord, int)>[];
  for (final r in records) {
    final blob = _blob(r);
    if (!tokens.every(blob.contains)) continue;

    var score = 0;
    for (final f in r.analysis.fields) {
      final fieldBlob = '${f.label} ${f.value}'.toLowerCase();
      for (final t in tokens) {
        if (fieldBlob.contains(t)) score++;
      }
    }
    matched.add((r, score));
  }

  matched.sort((a, b) => b.$2.compareTo(a.$2));
  return matched.map((m) => m.$1).toList();
}

String _blob(ScreenshotRecord r) {
  final sb = StringBuffer()
    ..write(r.category.name)
    ..write(' ');
  for (final f in r.analysis.fields) {
    sb
      ..write(f.label)
      ..write(' ')
      ..write(f.value)
      ..write(' ');
  }
  sb.write(r.ocrText);
  return sb.toString().toLowerCase();
}
