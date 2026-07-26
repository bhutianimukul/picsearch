import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import '../src/ai_engine.dart';
import '../src/cleanup.dart';
import '../src/gallery_scanner.dart';
import '../src/gemini.dart';
import '../src/image_vault.dart';
import '../src/models.dart';
import '../src/scan_pipeline.dart';
import '../src/vault_store.dart';

/// Holds the analysed screenshot records, drives the gallery scan, and persists
/// results (encrypted) between launches.
class AppState extends ChangeNotifier {
  AppState(this._pipeline, this._store);

  final ScanPipeline _pipeline;
  final VaultStore _store;
  final ImagePicker _picker = ImagePicker();
  final GalleryScanner _gallery = GalleryScanner();
  final ImageVault _images = ImageVault();

  final List<ScreenshotRecord> records = <ScreenshotRecord>[];
  bool scanning = false;
  int scanTotal = 0;
  int scanDone = 0;
  String? geminiKey;
  final Set<String> processedIds = <String>{};
  int newCount = 0;
  bool grouping = false; // an AI regroup is in flight

  // --- AI engine (cloud Gemini ↔ on-device Gemma) ---
  AiMode aiMode = AiMode.cloud;
  bool downloadingModel = false;
  int modelPercent = 0;
  String? modelError;

  /// Load previously saved (encrypted) records on startup.
  Future<void> init() async {
    final saved = await _store.load();
    records
      ..clear()
      ..addAll(_dedupe(saved));
    geminiKey = await _store.geminiKey();
    processedIds
      ..clear()
      ..addAll(await _store.loadProcessedIds());
    // Prefer the on-device model if one is already downloaded and there's no key.
    if (LocalGemma.isReady && !hasGemini) aiMode = AiMode.local;
    notifyListeners();
    refreshNewCount(); // best-effort; may prompt for gallery access
  }

  /// Count gallery screenshots not yet read into the vault.
  Future<void> refreshNewCount() async {
    try {
      if (!await _gallery.ensurePermission()) return;
      final assets = await _gallery.screenshots();
      newCount = assets.where((a) => !processedIds.contains(a.id)).length;
      notifyListeners();
    } catch (_) {
      /* gallery access unavailable — leave newCount as-is */
    }
  }

  /// Scan only the screenshots we haven't processed yet.
  Future<int> scanNewScreenshots() async {
    if (scanning) return 0;
    if (!await _gallery.ensurePermission()) return 0;
    final assets = (await _gallery.screenshots())
        .where((a) => !processedIds.contains(a.id))
        .toList();
    if (assets.isEmpty) {
      newCount = 0;
      notifyListeners();
      return 0;
    }
    scanning = true;
    scanTotal = assets.length;
    scanDone = 0;
    notifyListeners();
    try {
      final recs = <ScreenshotRecord>[];
      for (final a in assets) {
        final file = await a.file;
        if (file != null) {
          var rec = await _pipeline.scanOne(file.path);
          try {
            rec = rec.copyWith(imagePath: await _images.store(file.path));
          } catch (_) {/* keep original path if the copy fails */}
          recs.add(rec);
        }
        processedIds.add(a.id);
        scanDone++;
        notifyListeners();
      }
      _addRecords(recs);
      await _store.save(records);
      await _store.saveProcessedIds(processedIds);
      newCount = 0;
      return recs.length;
    } finally {
      scanning = false;
      notifyListeners();
      if (aiReady) unawaited(regroupWithAi());
    }
  }

  /// Pick screenshots from the gallery, run the pipeline, persist.
  Future<int> scanFromGallery() async {
    if (scanning) return 0;
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) return 0;

    scanning = true;
    scanTotal = files.length;
    scanDone = 0;
    notifyListeners();
    try {
      final recs = <ScreenshotRecord>[];
      for (final f in files) {
        var rec = await _pipeline.scanOne(f.path);
        try {
          rec = rec.copyWith(imagePath: await _images.store(f.path));
        } catch (_) {/* keep original path if the copy fails */}
        recs.add(rec);
        scanDone++;
        notifyListeners(); // drive the progress overlay
      }
      _addRecords(recs);
      await _store.save(records);
      return recs.length;
    } finally {
      scanning = false;
      notifyListeners();
      if (aiReady) unawaited(regroupWithAi());
    }
  }

  /// Remove records from the vault and persist. (Clears from PicSearch's vault,
  /// not from the phone's gallery — deleting the original photo is a separate,
  /// permission-gated OS action, deliberately out of scope for now.)
  Future<void> removeRecords(Iterable<ScreenshotRecord> toRemove) async {
    final set = toRemove.toSet();
    records.removeWhere(set.contains);
    await _store.save(records);
    notifyListeners();
  }

  // --- AI engine: cloud (Gemini BYOK) ↔ on-device (Gemma via MediaPipe) ---
  bool get hasGemini => (geminiKey ?? '').trim().isNotEmpty;

  /// The active engine, or null if nothing is ready (no key / no local model).
  AiEngine? get engine {
    if (aiMode == AiMode.local) {
      return LocalGemma.isReady ? const LocalGemmaEngine() : null;
    }
    return hasGemini ? GeminiEngine(geminiKey!) : null;
  }

  bool get aiReady => engine != null;
  bool get localModelReady => LocalGemma.isReady;

  Future<void> setGeminiKey(String? key) async {
    await _store.setGeminiKey(key);
    geminiKey = (key ?? '').trim().isEmpty ? null : key!.trim();
    if (hasGemini) aiMode = AiMode.cloud;
    notifyListeners();
    // Turning AI on regroups the existing vault into smart folders.
    if (aiReady && records.isNotEmpty) unawaited(regroupWithAi());
  }

  /// Returns null if [key] is a working Gemini key, else a short error message.
  Future<String?> verifyGeminiKey(String key) =>
      GeminiClient(key.trim()).verifyKey();

  /// Switch between the cloud and on-device engines.
  void setAiMode(AiMode mode) {
    aiMode = mode;
    notifyListeners();
    if (aiReady && records.isNotEmpty) unawaited(regroupWithAi());
  }

  /// Download the on-device Gemma model (progress via [modelPercent]) and switch
  /// to it. Inference needs a real device — MediaPipe LLM won't run on an emulator.
  Future<void> downloadLocalModel({String? hfToken}) async {
    if (downloadingModel) return;
    downloadingModel = true;
    modelError = null;
    modelPercent = 0;
    notifyListeners();
    try {
      await LocalGemma.download((p) {
        modelPercent = p;
        notifyListeners();
      }, hfToken: hfToken);
      aiMode = AiMode.local;
      modelPercent = 100;
      notifyListeners();
      if (records.isNotEmpty) unawaited(regroupWithAi());
    } catch (e) {
      modelError = 'Couldn’t load the model: $e';
    } finally {
      downloadingModel = false;
      notifyListeners();
    }
  }

  /// Activate a Gemma `.task`/`.bin` the user downloaded themselves (via the
  /// browser) — sidesteps in-app auth for gated models.
  Future<void> loadLocalModelFile(String path) async {
    if (downloadingModel) return;
    downloadingModel = true;
    modelError = null;
    notifyListeners();
    try {
      await LocalGemma.loadFile(path);
      aiMode = AiMode.local;
      notifyListeners();
      if (records.isNotEmpty) unawaited(regroupWithAi());
    } catch (e) {
      modelError = 'Couldn’t load that file — is it a MediaPipe Gemma .task? ($e)';
    } finally {
      downloadingModel = false;
      notifyListeners();
    }
  }

  Future<String> askAi(String query) {
    final e = engine;
    if (e == null) throw StateError('No AI engine ready');
    return e.ask(query, records);
  }

  /// Re-analyses the vault from redacted text only: an AI folder name per record
  /// plus a clearable-junk flag. Runs after a scan and when the engine changes;
  /// leaves existing results untouched on failure.
  Future<void> regroupWithAi() async {
    final e = engine;
    if (e == null || records.isEmpty || grouping) return;
    grouping = true;
    notifyListeners();
    try {
      final insights = await e.analyzeRecords(records);
      for (var i = 0; i < records.length && i < insights.length; i++) {
        records[i] = records[i].copyWith(
          aiGroup: insights[i].group,
          aiClearable: insights[i].clear,
          aiClearReason: insights[i].reason,
        );
      }
      await _store.save(records);
    } catch (_) {
      // keep whatever we already have; Vault falls back where results are null
    } finally {
      grouping = false;
      notifyListeners();
    }
  }

  /// Screenshots suggested for clearing — AI-flagged when an engine is active,
  /// else the on-device heuristics (one-time codes + duplicates).
  List<ScreenshotRecord> get cleanupCandidates => aiReady
      ? records.where((r) => r.aiClearable).toList()
      : deletableCandidates(records);

  /// Why a candidate is clearable, shown in the cleanup list.
  String cleanupReason(ScreenshotRecord r) => aiReady
      ? ((r.aiClearReason?.isNotEmpty ?? false) ? r.aiClearReason! : 'Suggested by AI')
      : deletableReason(r, records);

  /// Insert new records at the front, then drop any duplicates (keeps newest).
  void _addRecords(List<ScreenshotRecord> recs) {
    records.insertAll(0, recs);
    final deduped = _dedupe(records);
    records
      ..clear()
      ..addAll(deduped);
  }

  List<ScreenshotRecord> _dedupe(List<ScreenshotRecord> list) {
    final seen = <String>{};
    final out = <ScreenshotRecord>[];
    for (final r in list) {
      if (seen.add(dedupKey(r))) out.add(r);
    }
    return out;
  }

  Map<Category, int> get categoryCounts {
    final m = <Category, int>{};
    for (final r in records) {
      m[r.category] = (m[r.category] ?? 0) + 1;
    }
    return m;
  }

  List<ScreenshotRecord> byCategory(Category c) =>
      records.where((r) => r.category == c).toList();

  ScreenshotRecord? recordByPath(String path) {
    for (final r in records) {
      if (r.imagePath == path) return r;
    }
    return null;
  }

  Future<void> addFieldToRecord(String imagePath, ExtractedField field) async {
    final i = records.indexWhere((r) => r.imagePath == imagePath);
    if (i < 0) return;
    records[i] = records[i].copyWith(extra: [...records[i].extra, field]);
    await _store.save(records);
    notifyListeners();
  }

  Future<void> removeField(String imagePath, ExtractedField field) async {
    final i = records.indexWhere((r) => r.imagePath == imagePath);
    if (i < 0) return;
    records[i] =
        records[i].copyWith(extra: [...records[i].extra]..remove(field));
    await _store.save(records);
    notifyListeners();
  }
}

/// Makes [AppState] available down the tree and rebuilds dependents on change.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
