import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import '../src/models.dart';
import '../src/scan_pipeline.dart';

/// Holds the analysed screenshot records and drives the gallery scan.
/// In-memory for now; encrypted persistence is a later task (decisions §5/todo).
class AppState extends ChangeNotifier {
  AppState(this._pipeline);

  final ScanPipeline _pipeline;
  final ImagePicker _picker = ImagePicker();

  final List<ScreenshotRecord> records = <ScreenshotRecord>[];
  bool scanning = false;

  /// Pick screenshots from the gallery and run them through the pipeline.
  Future<int> scanFromGallery() async {
    if (scanning) return 0;
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) return 0;

    scanning = true;
    notifyListeners();
    try {
      final recs = await _pipeline.scanAll(files.map((f) => f.path));
      records.insertAll(0, recs);
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

/// Makes [AppState] available down the widget tree and rebuilds dependents
/// when it changes — no external state-management package needed.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
