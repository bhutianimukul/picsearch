import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

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

  final List<ScreenshotRecord> records = <ScreenshotRecord>[];
  bool scanning = false;

  /// Load previously saved (encrypted) records on startup.
  Future<void> init() async {
    final saved = await _store.load();
    records
      ..clear()
      ..addAll(saved);
    notifyListeners();
  }

  /// Pick screenshots from the gallery, run the pipeline, persist.
  Future<int> scanFromGallery() async {
    if (scanning) return 0;
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) return 0;

    scanning = true;
    notifyListeners();
    try {
      final recs = await _pipeline.scanAll(files.map((f) => f.path));
      records.insertAll(0, recs);
      await _store.save(records);
      return recs.length;
    } finally {
      scanning = false;
      notifyListeners();
    }
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
