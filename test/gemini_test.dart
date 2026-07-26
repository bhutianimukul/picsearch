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

  test('analyzeRecords parses group + clear flags, gaps become Misc', () async {
    final inner = jsonEncode({
      '1': {'group': 'Payments', 'clear': false},
      '2': {'group': 'Codes', 'clear': true, 'reason': 'one-time OTP'},
    });
    final body = jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': inner}
            ]
          }
        }
      ]
    });
    final client = MockClient((_) async => http.Response(body, 200));
    final recs = [
      _rec('a.png', 'upi rahul@okhdfc'),
      _rec('b.png', '123456 is your OTP'),
      _rec('c.png', 'blurry meme'), // no entry -> gap
    ];
    final out = await GeminiClient('k', client: client).analyzeRecords(recs);
    expect(out[0].group, 'Payments');
    expect(out[0].clear, isFalse);
    expect(out[1].group, 'Codes');
    expect(out[1].clear, isTrue);
    expect(out[1].reason, 'one-time OTP');
    expect(out[2].group, 'Misc'); // gap filled
    expect(out[2].clear, isFalse);
  });

  // Local (on-device) models rarely return clean JSON — they wrap it in prose or
  // ```json fences. The shared parser must dig it out; this is the riskiest bit
  // of the local engine and IS unit-testable without a device.
  test('firstJsonObject digs JSON out of a fenced, prose-wrapped reply', () {
    const reply =
        'Sure! Here are the folders:\n```json\n{"1":{"group":"Payments"}}\n```\nHope that helps!';
    final m = firstJsonObject(reply);
    expect(m['1'], isA<Map>());
    expect((m['1'] as Map)['group'], 'Payments');
  });

  test('parseAnalyze survives a messy local-model reply', () {
    const reply =
        'Okay:\n```\n{"1":{"group":"Identity","clear":false},'
        '"2":{"group":"Codes","clear":true,"reason":"one-time OTP"}}\n```';
    final out = parseAnalyze(reply, 2);
    expect(out[0].group, 'Identity');
    expect(out[1].clear, isTrue);
    expect(out[1].reason, 'one-time OTP');
  });

  test('parseAnalyze falls back to safe defaults on total garbage', () {
    final out = parseAnalyze('I could not do that.', 2);
    expect(out.every((e) => e.group == 'Misc' && !e.clear), isTrue);
  });
}
