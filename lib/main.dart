import 'package:flutter/material.dart';

import 'src/ocr_mlkit.dart';
import 'src/scan_pipeline.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'ui/splash_screen.dart';

void main() {
  final state = AppState(ScanPipeline(MlKitOcrService()));
  runApp(AppScope(state: state, child: const PicSearchApp()));
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
