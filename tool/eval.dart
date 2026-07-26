// Run with: dart run tool/eval.dart
// Prints the accuracy report for the README.
// ignore_for_file: avoid_print

import '../eval/samples.dart';
import '../eval/scorer.dart';

void main() {
  print(formatReport(runEval(evalSamples())));
}
