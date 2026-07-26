import 'package:picsearch/src/analyzer.dart';

import 'samples.dart';

/// Metrics from running the pipeline over the labelled set.
class EvalReport {
  final int total;
  final int categoryCorrect;
  final int truePos; // correct ID extractions
  final int falsePos; // things we extracted that we shouldn't have
  final int falseNeg; // things we should have extracted but missed
  final List<String> misses;

  const EvalReport({
    required this.total,
    required this.categoryCorrect,
    required this.truePos,
    required this.falsePos,
    required this.falseNeg,
    required this.misses,
  });

  double get classificationAccuracy => total == 0 ? 0 : categoryCorrect / total;
  double get precision =>
      (truePos + falsePos) == 0 ? 1 : truePos / (truePos + falsePos);
  double get recall =>
      (truePos + falseNeg) == 0 ? 1 : truePos / (truePos + falseNeg);
  double get f1 =>
      (precision + recall) == 0 ? 0 : 2 * precision * recall / (precision + recall);
}

/// Runs [analyzeText] over every sample and scores classification + extraction.
EvalReport runEval(List<EvalSample> samples) {
  var categoryCorrect = 0, tp = 0, fp = 0, fn = 0;
  final misses = <String>[];

  for (final s in samples) {
    final result = analyzeText(s.ocrText);

    if (result.category == s.expectedCategory) {
      categoryCorrect++;
    } else {
      misses.add(
          'CATEGORY  "${s.name}": expected ${s.expectedCategory.name}, got ${result.category.name}');
    }

    final predicted = result.fields.map((f) => f.type).toSet();
    for (final t in predicted) {
      if (s.expectedTypes.contains(t)) {
        tp++;
      } else {
        fp++;
        misses.add('FALSE-POS "${s.name}": extracted ${t.name} (a checksum leak!)');
      }
    }
    for (final t in s.expectedTypes) {
      if (!predicted.contains(t)) {
        fn++;
        misses.add('MISSED    "${s.name}": ${t.name}');
      }
    }
  }

  return EvalReport(
    total: samples.length,
    categoryCorrect: categoryCorrect,
    truePos: tp,
    falsePos: fp,
    falseNeg: fn,
    misses: misses,
  );
}

String formatReport(EvalReport r) {
  String pct(double v) => '${(v * 100).toStringAsFixed(1)}%';
  final b = StringBuffer()
    ..writeln('┌─ PicSearch · extraction & classification eval ───────────')
    ..writeln('│ Samples                 : ${r.total}')
    ..writeln('│ Classification accuracy : ${pct(r.classificationAccuracy)}  (${r.categoryCorrect}/${r.total})')
    ..writeln('│ Extraction precision    : ${pct(r.precision)}  (TP=${r.truePos}, FP=${r.falsePos})')
    ..writeln('│ Extraction recall       : ${pct(r.recall)}  (FN=${r.falseNeg})')
    ..writeln('│ Extraction F1           : ${pct(r.f1)}')
    ..writeln('└──────────────────────────────────────────────────────────');
  if (r.misses.isNotEmpty) {
    b.writeln('Misses:');
    for (final m in r.misses) {
      b.writeln('  - $m');
    }
  } else {
    b.writeln('No misses — every label matched, zero false positives.');
  }
  return b.toString();
}
