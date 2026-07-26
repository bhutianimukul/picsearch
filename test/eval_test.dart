import 'package:flutter_test/flutter_test.dart';

import '../eval/samples.dart';
import '../eval/scorer.dart';

void main() {
  test('pipeline meets accuracy targets on the labelled eval set', () {
    final report = runEval(evalSamples());
    // ignore: avoid_print
    print('\n${formatReport(report)}');

    expect(report.total, greaterThanOrEqualTo(15));
    expect(report.classificationAccuracy, greaterThanOrEqualTo(0.9),
        reason: report.misses.join('\n'));
    // The headline guarantee of "verify, don't guess": zero false positives.
    expect(report.precision, 1.0, reason: report.misses.join('\n'));
    expect(report.recall, greaterThanOrEqualTo(0.9), reason: report.misses.join('\n'));
  });

  test('every adversarial negative is rejected (no ID extracted)', () {
    final report = runEval(evalSamples());
    expect(report.falsePos, 0, reason: report.misses.join('\n'));
  });
}
