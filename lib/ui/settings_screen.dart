import 'package:flutter/material.dart';

import '../theme.dart';

/// Settings — appearance toggle, privacy statement, and a BYOK Gemini key field
/// (key wiring comes with the Gemini task).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    final isDark = themeMode.value == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance
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
              secondary: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, color: c.accent),
              onChanged: (v) => themeMode.value = v ? ThemeMode.dark : ThemeMode.light,
            ),
          ),
          const SizedBox(height: 18),
          // Privacy
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
          const SizedBox(height: 10),
          TextField(
            obscureText: true,
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
          const SizedBox(height: 10),
          Text(
            'Used only for natural-language questions. We send masked text — never your images, never full card or Aadhaar numbers.',
            style: TextStyle(fontSize: 11.5, color: c.inkFaint),
          ),
        ],
      ),
    );
  }
}
