import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../src/ai_engine.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Settings — appearance toggle, privacy statement, and the BYOK Gemini key.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _keyCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _openKeyPage() async {
    final uri = Uri.parse('https://aistudio.google.com/apikey');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn’t open the browser')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    final state = AppScope.of(context);
    final isDark = themeMode.value == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.line),
            ),
            child: SwitchListTile(
              value: isDark,
              activeThumbColor: c.accent,
              title: const Text('Dark theme'),
              subtitle: Text(isDark ? 'Vault (dark)' : 'Daylight (light)',
                  style: TextStyle(color: c.inkDim, fontSize: 12.5)),
              secondary: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  color: c.accent),
              onChanged: (v) =>
                  setState(() => themeMode.value = v ? ThemeMode.dark : ThemeMode.light),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: c.accent, size: 24),
                const SizedBox(height: 11),
                const Text('Your images never leave your phone.',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Screenshots are read on-device with ML Kit. Only you ever see them.',
                    style: TextStyle(color: c.inkDim, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('GEMINI · OPTIONAL', style: labelStyle.copyWith(color: c.inkFaint)),
          const SizedBox(height: 6),
          Text(
            'A free Google Gemini key (runs on gemini-flash-latest) unlocks AI '
            'search, smart folders and cleanup. Paste it below.',
            style: TextStyle(fontSize: 12, color: c.inkDim, height: 1.4),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _openKeyPage,
              icon: const Icon(Icons.open_in_new, size: 15),
              label: const Text('Get a free key at aistudio.google.com'),
              style: TextButton.styleFrom(
                foregroundColor: c.accent,
                padding: const EdgeInsets.symmetric(vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (state.hasGemini) _savedRow(c, state) else _entryRow(c, state),
          const SizedBox(height: 10),
          Text(
            'Used only for natural-language questions. We send masked text — never '
            'your images, never full card or Aadhaar numbers.',
            style: TextStyle(fontSize: 11.5, color: c.inkFaint),
          ),
          const SizedBox(height: 24),
          Text('ON-DEVICE MODEL · NO KEY',
              style: labelStyle.copyWith(color: c.inkFaint)),
          const SizedBox(height: 6),
          Text(
            'Run AI entirely on your phone with a local Gemma model (MediaPipe) — '
            'no key, no network, nothing leaves the device. Best on a real phone '
            'with a few GB of RAM.',
            style: TextStyle(fontSize: 12, color: c.inkDim, height: 1.4),
          ),
          const SizedBox(height: 12),
          _localModelCard(c, state),
        ],
      ),
    );
  }

  Widget _localModelCard(PicColors c, AppState state) {
    final box = BoxDecoration(
      color: c.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: c.line),
    );
    if (state.downloadingModel) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: box,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Downloading Gemma… ${state.modelPercent}%',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: state.modelPercent <= 0 ? null : state.modelPercent / 100,
              minHeight: 6,
              backgroundColor: c.surface2,
              valueColor: AlwaysStoppedAnimation(c.accent),
            ),
          ),
        ]),
      );
    }
    if (state.localModelReady) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: box.copyWith(
            border: Border.all(color: c.accent.withValues(alpha: 0.4))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.check_circle_outline, color: c.accent, size: 18),
            const SizedBox(width: 10),
            const Expanded(
                child: Text('On-device model ready',
                    style: TextStyle(fontWeight: FontWeight.w600))),
          ]),
          if (state.hasGemini) ...[
            const SizedBox(height: 14),
            Text('ANSWER WITH', style: labelStyle.copyWith(color: c.inkFaint)),
            const SizedBox(height: 8),
            Row(children: [
              _engineChip(c, state, 'On-device', AiMode.local),
              const SizedBox(width: 8),
              _engineChip(c, state, 'Cloud (Gemini)', AiMode.cloud),
            ]),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('AI runs entirely on your phone — no key, no network.',
                  style: TextStyle(color: c.inkDim, fontSize: 12)),
            ),
        ]),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => state.downloadLocalModel(),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Download Gemma 3 1B  (~550 MB)'),
          style: FilledButton.styleFrom(
            backgroundColor: c.accent,
            foregroundColor: c.accentInk,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ),
      if (state.modelError != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(state.modelError!,
              style: TextStyle(color: c.inkDim, fontSize: 12)),
        ),
    ]);
  }

  Widget _engineChip(PicColors c, AppState state, String label, AiMode mode) {
    final selected = state.aiMode == mode;
    return GestureDetector(
      onTap: () => state.setAiMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? c.accent.withValues(alpha: 0.18) : c.surface2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? c.accent : c.line),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? c.accent : c.inkDim,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13)),
      ),
    );
  }

  Widget _savedRow(PicColors c, AppState state) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: c.accent, size: 18),
            const SizedBox(width: 10),
            const Expanded(child: Text('Gemini key saved', style: TextStyle(fontWeight: FontWeight.w600))),
            TextButton(
              onPressed: () => state.setGeminiKey(null),
              child: Text('Remove', style: TextStyle(color: c.inkDim)),
            ),
          ],
        ),
      );

  Widget _entryRow(PicColors c, AppState state) => Row(
        children: [
          Expanded(
            child: TextField(
              controller: _keyCtrl,
              obscureText: true,
              enabled: !_saving,
              onSubmitted: (_) => _save(state),
              style: dataStyle.copyWith(fontSize: 13, color: c.ink),
              decoration: InputDecoration(
                hintText: 'Paste your Gemini API key',
                hintStyle: TextStyle(color: c.inkFaint, fontFamily: 'monospace'),
                prefixIcon: Icon(Icons.key_outlined, color: c.inkFaint, size: 18),
                filled: true,
                fillColor: c.surface2,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.accent),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _saving ? null : () => _save(state),
            style: FilledButton.styleFrom(
                backgroundColor: c.accent, foregroundColor: c.accentInk),
            child: _saving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: c.accentInk))
                : const Text('Save'),
          ),
        ],
      );

  /// Verifies the pasted key with a tiny live request before storing it, so a
  /// bad key is caught here rather than at the first question.
  Future<void> _save(AppState state) async {
    final v = _keyCtrl.text.trim();
    if (v.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final err = await state.verifyGeminiKey(v);
    if (!mounted) return;
    setState(() => _saving = false);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (err != null) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    await state.setGeminiKey(v);
    _keyCtrl.clear();
    messenger.showSnackBar(
        const SnackBar(content: Text('Gemini key verified & saved ✓')));
  }
}
