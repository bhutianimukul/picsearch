import 'models.dart';

/// A stable key for near-duplicate detection: two screenshots collapse to the
/// same key if they extracted the same primary value, or (lacking fields) have
/// the same normalized OCR text.
String dedupKey(ScreenshotRecord r) {
  if (r.fields.isNotEmpty) {
    final f = r.fields.first;
    return '${f.type.name}:${f.value}';
  }
  return 'text:${r.ocrText.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ')}';
}

/// Groups of records that are duplicates of each other (size > 1).
List<List<ScreenshotRecord>> duplicateGroups(List<ScreenshotRecord> records) {
  final byKey = <String, List<ScreenshotRecord>>{};
  for (final r in records) {
    byKey.putIfAbsent(dedupKey(r), () => []).add(r);
  }
  return byKey.values.where((g) => g.length > 1).toList();
}

/// Records safe to suggest clearing:
/// - **OTP** screenshots (single-use codes you no longer need), and
/// - the **redundant copies** in each duplicate group (keep the first).
List<ScreenshotRecord> deletableCandidates(List<ScreenshotRecord> records) {
  final out = <ScreenshotRecord>[];
  for (final r in records) {
    if (r.analysis.tags.contains('deletable:otp')) out.add(r);
  }
  for (final group in duplicateGroups(records)) {
    out.addAll(group.skip(1)); // keep the first copy, offer the rest
  }
  final seen = <ScreenshotRecord>{}; // identity-dedupe the candidate list
  return out.where(seen.add).toList();
}

/// Why a record was flagged — shown in the cleanup list.
String deletableReason(ScreenshotRecord r, List<ScreenshotRecord> all) {
  if (r.analysis.tags.contains('deletable:otp')) return 'One-time code';
  return 'Duplicate';
}
