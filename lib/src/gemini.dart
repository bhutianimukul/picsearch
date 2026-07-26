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

/// One record's AI analysis: which folder, and whether it's clearable junk (with
/// a reason). Shared by the cloud (Gemini) and on-device (Gemma) engines.
typedef RecordInsight = ({String group, bool clear, String reason});

/// The grouping + cleanup prompt — asks for a JSON object keyed by item number.
String buildAnalyzePrompt(List<ScreenshotRecord> records) {
  final b = StringBuffer();
  for (var i = 0; i < records.length; i++) {
    final r = records[i];
    final fields = r.fields.map((f) => '${f.label}: ${f.masked}').join(', ');
    var snip = redactForLlm(r.ocrText).trim().replaceAll(RegExp(r'\s+'), ' ');
    if (snip.length > 120) snip = '${snip.substring(0, 120)}…';
    final body = snip.isEmpty ? '(image, no readable text)' : snip;
    b.writeln('${i + 1}. ${fields.isEmpty ? '' : '$fields — '}$body');
  }
  return 'Organize these phone screenshots into folders and flag clearable junk. '
      'Each numbered line is one screenshot’s extracted text (sensitive numbers '
      'are masked). For every item return a JSON object with:\n'
      '- "group": a short Title Case folder name (1–2 words). Reuse the same '
      'name for similar items; aim for 3–8 folders. Good names: Payments, '
      'Identity, Banking, Travel, Shopping, Receipts, Passwords, Personal, Misc.\n'
      '- "clear": true ONLY for transient junk safe to delete — one-time OTP or '
      'verification codes, obvious duplicates, expired noise. NEVER true for '
      'IDs, cards, bank details, passwords/wifi, or receipts.\n'
      '- "reason": a few words on why it is clearable (empty when clear is false).\n'
      'Return ONLY a JSON object mapping each item number (as a string) to that '
      'object.\n\n$b';
}

/// Pulls the first `{…}` JSON object out of [text] — local models often wrap it
/// in prose or ```json fences, so we don't assume a clean body.
Map<String, dynamic> firstJsonObject(String text) {
  var t = text.trim();
  final start = t.indexOf('{');
  final end = t.lastIndexOf('}');
  if (start >= 0 && end > start) t = t.substring(start, end + 1);
  try {
    return jsonDecode(t) as Map<String, dynamic>;
  } catch (_) {
    return const {};
  }
}

/// Parses the analyze response into one [RecordInsight] per record; gaps and
/// malformed entries default to a safe (Misc, not-clearable).
List<RecordInsight> parseAnalyze(String jsonText, int n) {
  final map = firstJsonObject(jsonText);
  return List.generate(n, (i) {
    final v = map['${i + 1}'];
    if (v is Map) {
      final g = v['group'];
      final rs = v['reason'];
      return (
        group: (g is String && g.trim().isNotEmpty) ? g.trim() : 'Misc',
        clear: v['clear'] == true,
        reason: (rs is String) ? rs.trim() : '',
      );
    }
    return (
      group: (v is String && v.trim().isNotEmpty) ? v.trim() : 'Misc',
      clear: false,
      reason: '',
    );
  });
}

class GeminiException implements Exception {
  GeminiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Minimal Gemini client (bring-your-own-key). Sends only the redacted prompt.
class GeminiClient {
  // gemini-flash-latest is a rolling alias to the current stable flash model, so
  // this never deprecates out from under a user's key (as gemini-2.5-flash did).
  GeminiClient(this.apiKey,
      {this.model = 'gemini-flash-latest', http.Client? client})
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

  /// Lightweight validity check for a key: one tiny request. Returns null if the
  /// key works, else a short human-readable reason. Used to verify on Save so a
  /// bad key is caught immediately, not at the first question.
  Future<String?> verifyKey() async {
    try {
      final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');
      final resp = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'ping'}
              ]
            }
          ]
        }),
      );
      // 429 = valid key, just rate-limited — treat as OK.
      if (resp.statusCode == 200 || resp.statusCode == 429) return null;
      if (resp.statusCode == 400 || resp.statusCode == 401 || resp.statusCode == 403) {
        return 'That key was rejected — check you copied all of it.';
      }
      if (resp.statusCode == 404) {
        return 'This key can’t reach the model. Get a fresh one from aistudio.google.com.';
      }
      return 'Couldn’t verify the key (error ${resp.statusCode}).';
    } catch (_) {
      return 'Couldn’t reach Gemini — check your connection.';
    }
  }

  /// Analyzes [records] from their redacted text only (never images, never full
  /// numbers): a folder name per record, plus whether it's clearable junk and
  /// why. Returns one entry per record, aligned by index.
  Future<List<RecordInsight>> analyzeRecords(
      List<ScreenshotRecord> records) async {
    if (records.isEmpty) return const [];
    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': buildAnalyzePrompt(records)}
            ]
          }
        ],
        'generationConfig': {'responseMimeType': 'application/json'},
      }),
    );
    if (resp.statusCode != 200) {
      throw GeminiException('Analysis failed (${resp.statusCode}).');
    }
    return parseAnalyze(_extractText(jsonDecode(resp.body)) ?? '{}', records.length);
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
