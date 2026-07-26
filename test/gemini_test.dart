import 'package:flutter_test/flutter_test.dart';
import 'package:picsearch/src/analyzer.dart';
import 'package:picsearch/src/gemini.dart';
import 'package:picsearch/src/models.dart';

ScreenshotRecord _rec(String p, String t) =>
    ScreenshotRecord(imagePath: p, ocrText: t, analysis: analyzeText(t));

void main() {
  test('redactForLlm hides a full card number, keeps the last 4', () {
    final out = redactForLlm('card 4539 1488 0343 6467 here');
    expect(out.contains('4539148803436467'), isFalse);
    expect(out.contains('4539 1488 0343 6467'), isFalse);
    expect(out.contains('6467'), isTrue);
  });

  test('buildContext never leaks the full card number to the LLM', () {
    final ctx = buildContext([_rec('a.png', 'HDFC card 4539 1488 0343 6467')]);
    expect(ctx.contains('4539148803436467'), isFalse);
    expect(ctx.contains('6467'), isTrue); // last-4 survives
    expect(ctx.toLowerCase().contains('card'), isTrue);
  });

  test('buildPrompt carries the question + answer-only-from-context rule', () {
    final p = buildPrompt('my hdfc card', 'CONTEXT LINE');
    expect(p.contains('my hdfc card'), isTrue);
    expect(p.toLowerCase().contains('only from the context'), isTrue);
    expect(p.contains('CONTEXT LINE'), isTrue);
  });
}
