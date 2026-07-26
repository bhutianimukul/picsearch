import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/ocr_mlkit.dart';
import 'src/scan_pipeline.dart';
import 'src/vault_store.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'ui/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState(ScanPipeline(MlKitOcrService()), VaultStore());
  state.init(); // async load of saved records
  _wireShareInbox(state);
  runApp(AppScope(state: state, child: const PicSearchApp()));
}

/// Images shared into PicSearch (from any app's share sheet) arrive on the
/// native "picsearch/share" channel as file paths — ingest them into the vault.
void _wireShareInbox(AppState state) {
  const channel = MethodChannel('picsearch/share');
  Future<void> ingest(Object? args) async {
    final paths = (args as List?)?.cast<String>() ?? const <String>[];
    if (paths.isNotEmpty) await state.addSharedImages(paths);
  }

  channel.setMethodCallHandler((call) async {
    if (call.method == 'shared') await ingest(call.arguments);
  });
  // Anything the app was cold-started with.
  channel.invokeMethod<List<Object?>>('getInitialShared').then(ingest);
}

class PicSearchApp extends StatelessWidget {
  const PicSearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (context, mode, _) => MaterialApp(
        title: 'PicSearch',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: mode,
        home: const SplashScreen(),
      ),
    );
  }
}
