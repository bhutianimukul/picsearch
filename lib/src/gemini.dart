import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

/// Redacts long digit runs (card / Aadhaar / account numbers) to the last 4, so
/// the LLM never receives a full sensitive number — even from raw OCR text.
String redactForLlm(String text) {
  return text.replaceAllMapped(RegExp(r'\d[\d\s-]{5,}\d'), (m) {
    final digits = m[0]!.replaceAll(RegExp(r'[\s-]'), '');
    if (digits.length < 6) return m[0]!;
    return '••••${digits.substring(digits.length - 4)}';
  });
}

/// A compact, redacted context from the vault — masked field values plus a
/// redacted OCR snippet per record. This is all the LLM ever sees.
String buildContext(List<ScreenshotRecord> records, {int max = 50}) {
  final b = StringBuffer();
  final n = records.length < max ? records.length : max;
  for (var i = 0; i < n; i++) {
    final r = records[i];
    final fields = r.fields.map((f) => '${f.label}: ${f.masked}').join(', ');
    var snip = redactForLlm(r.ocrText).trim().replaceAll(RegExp(r'\s+'), ' ');
    if (snip.length > 120) snip = '${snip.substring(0, 120)}…';
    b.writeln('${i + 1}. [${r.category.name}] ${fields.isEmpty ? '' : '$fields — '}$snip');
  }
  return b.toString();
}

const _system =
    'You are PicSearch, a private on-device screenshot assistant. Answer the '
    'user ONLY from the context below (a list of their screenshots). If the '
    'answer is not in the context, say you could not find it. Be concise and '
    'point to the item. Numbers are intentionally masked — never guess or '
    'invent full card, Aadhaar, or PAN numbers.';

String buildPrompt(String query, String context) =>
    '$_system\n\nCONTEXT:\n$context\nQUESTION: $query\nANSWER:';

class GeminiException implements Exception {
  GeminiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Minimal Gemini client (bring-your-own-key). Sends only the redacted prompt.
class GeminiClient {
  GeminiClient(this.apiKey,
      {this.model = 'gemini-2.5-flash', http.Client? client})
      : _client = client ?? http.Client();

  final String apiKey;
  final String model;
  final http.Client _client;

  Future<String> ask(String query, List<ScreenshotRecord> records) async {
    final prompt = buildPrompt(query, buildContext(records));
    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      }),
    );
    if (resp.statusCode != 200) {
      throw GeminiException('Gemini request failed (${resp.statusCode}).');
    }
    final text = _extractText(jsonDecode(resp.body));
    return (text == null || text.trim().isEmpty) ? 'No answer found.' : text.trim();
  }

  String? _extractText(dynamic data) {
    try {
      final candidates = data['candidates'] as List;
      final content = (candidates.first as Map)['content'] as Map;
      final parts = content['parts'] as List;
      return (parts.first as Map)['text'] as String?;
    } catch (_) {
      return null;
    }
  }
}
