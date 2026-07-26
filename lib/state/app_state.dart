import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import '../src/gallery_scanner.dart';
import '../src/gemini.dart';
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

  final List<ScreenshotRecord> records = <ScreenshotRecord>[];
  bool scanning = false;
  int scanTotal = 0;
  int scanDone = 0;
  String? geminiKey;
  final Set<String> processedIds = <String>{};
  int newCount = 0;

  /// Load previously saved (encrypted) records on startup.
  Future<void> init() async {
    final saved = await _store.load();
    records
      ..clear()
      ..addAll(saved);
    geminiKey = await _store.geminiKey();
    processedIds
      ..clear()
      ..addAll(await _store.loadProcessedIds());
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
        if (file != null) recs.add(await _pipeline.scanOne(file.path));
        processedIds.add(a.id);
        scanDone++;
        notifyListeners();
      }
      records.insertAll(0, recs);
      await _store.save(records);
      await _store.saveProcessedIds(processedIds);
      newCount = 0;
      return recs.length;
    } finally {
      scanning = false;
      notifyListeners();
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
        recs.add(await _pipeline.scanOne(f.path));
        scanDone++;
        notifyListeners(); // drive the progress overlay
      }
      records.insertAll(0, recs);
      await _store.save(records);
      return recs.length;
    } finally {
      scanning = false;
      notifyListeners();
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

  // --- BYOK Gemini ---
  bool get hasGemini => (geminiKey ?? '').trim().isNotEmpty;

  Future<void> setGeminiKey(String? key) async {
    await _store.setGeminiKey(key);
    geminiKey = (key ?? '').trim().isEmpty ? null : key!.trim();
    notifyListeners();
  }

  Future<String> askGemini(String query) {
    final k = geminiKey;
    if (k == null || k.trim().isEmpty) {
      throw StateError('No Gemini key set');
    }
    return GeminiClient(k.trim()).ask(query, records);
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
}

/// Makes [AppState] available down the tree and rebuilds dependents on change.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
