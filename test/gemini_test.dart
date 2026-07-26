import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

  test('verifyKey returns null when the key works (200)', () async {
    final client = MockClient((_) async => http.Response('{"candidates":[]}', 200));
    expect(await GeminiClient('k', client: client).verifyKey(), isNull);
  });

  test('verifyKey reports a rejected key (400/401/403)', () async {
    final client = MockClient((_) async => http.Response('{}', 403));
    final err = await GeminiClient('k', client: client).verifyKey();
    expect(err, isNotNull);
    expect(err!.toLowerCase(), contains('rejected'));
  });

  test('verifyKey treats 429 (rate-limited) as a valid key', () async {
    final client = MockClient((_) async => http.Response('{}', 429));
    expect(await GeminiClient('k', client: client).verifyKey(), isNull);
  });

  test('groupRecords maps JSON labels onto records, gaps become Misc', () async {
    final body = jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': '{"1":"Payments","2":"Identity"}'}
            ]
          }
        }
      ]
    });
    final client = MockClient((_) async => http.Response(body, 200));
    final recs = [
      _rec('a.png', 'upi rahul@okhdfc'),
      _rec('b.png', 'PAN ABCDE1234F'),
      _rec('c.png', 'blurry meme'),
    ];
    final groups = await GeminiClient('k', client: client).groupRecords(recs);
    expect(groups, ['Payments', 'Identity', 'Misc']);
  });
}
