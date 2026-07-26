import 'package:flutter_gemma/flutter_gemma.dart';

import 'gemini.dart';
import 'models.dart';

/// Which AI backend answers questions / groups the vault.
enum AiMode { cloud, local }

/// A pluggable AI backend. Both engines only ever see **redacted text** — never
/// images, never full card/Aadhaar numbers. `cloud` = Google Gemini (BYOK);
/// `local` = a Gemma model run on-device via MediaPipe (no key, no network).
abstract class AiEngine {
  bool get ready;
  Future<String> ask(String query, List<ScreenshotRecord> records);
  Future<List<RecordInsight>> analyzeRecords(List<ScreenshotRecord> records);
}

/// Cloud engine — Google Gemini via a bring-your-own key.
class GeminiEngine implements AiEngine {
  GeminiEngine(this.apiKey);
  final String apiKey;

  @override
  bool get ready => apiKey.trim().isNotEmpty;

  @override
  Future<String> ask(String query, List<ScreenshotRecord> records) =>
      GeminiClient(apiKey.trim()).ask(query, records);

  @override
  Future<List<RecordInsight>> analyzeRecords(List<ScreenshotRecord> records) =>
      GeminiClient(apiKey.trim()).analyzeRecords(records);
}

/// On-device engine — a local Gemma model via MediaPipe (`flutter_gemma`). No
/// key and no network at inference time: the whole prompt runs on the phone.
/// A model must be downloaded/loaded first (see [LocalGemma]).
class LocalGemmaEngine implements AiEngine {
  const LocalGemmaEngine();

  @override
  bool get ready => FlutterGemma.hasActiveModel();

  Future<String> _run(String prompt) async {
    final model = await FlutterGemma.getActiveModel(maxTokens: 2048);
    final session = await model.createSession();
    try {
      await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      return (await session.getResponse()).trim();
    } finally {
      await session.close(); // free the KV cache between calls
    }
  }

  @override
  Future<String> ask(String query, List<ScreenshotRecord> records) async {
    final out = await _run(buildPrompt(query, buildContext(records)));
    return out.isEmpty ? 'No answer found.' : out;
  }

  @override
  Future<List<RecordInsight>> analyzeRecords(
      List<ScreenshotRecord> records) async {
    if (records.isEmpty) return const [];
    return parseAnalyze(await _run(buildAnalyzePrompt(records)), records.length);
  }
}

/// Downloads / tracks the on-device Gemma model file.
class LocalGemma {
  /// Default: Gemma 3 1B instruction-tuned, int4 `.task` for MediaPipe (~550 MB)
  /// — small enough to run + answer on a phone. Many Hugging Face model files
  /// are gated, so pass an HF read token if the download 401/403s.
  static const defaultUrl =
      'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task';

  static bool get isReady => FlutterGemma.hasActiveModel();

  /// Download + activate the model, reporting 0–100% progress.
  static Future<void> download(
    void Function(int percent) onProgress, {
    String url = defaultUrl,
    String? hfToken,
  }) async {
    await FlutterGemma
        .installModel(modelType: ModelType.gemmaIt)
        .fromNetwork(url, token: hfToken)
        .withProgress(onProgress)
        .install();
  }

  /// Activate an already-downloaded `.task` / `.bin` file from disk.
  static Future<void> loadFile(String path) async {
    await FlutterGemma
        .installModel(modelType: ModelType.gemmaIt)
        .fromFile(path)
        .install();
  }

  static Future<void> remove() async {
    for (final id in await FlutterGemma.listInstalledModels()) {
      await FlutterGemma.uninstallModel(id);
    }
  }
}
