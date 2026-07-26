import 'package:flutter/material.dart';

import '../theme.dart';

/// Settings — privacy statement + a BYOK Gemini key field (wiring comes with the
/// Gemini task). Placeholder for now so the shell is complete.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), backgroundColor: AppColors.ground),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: AppColors.accent, size: 24),
                SizedBox(height: 11),
                Text('Your images never leave your phone.',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('Screenshots are read on-device with ML Kit. Only you ever see them.',
                    style: TextStyle(color: AppColors.inkDim, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('GEMINI · OPTIONAL', style: labelStyle),
          const SizedBox(height: 10),
          TextField(
            obscureText: true,
            style: dataStyle.copyWith(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Paste your Gemini API key',
              hintStyle: const TextStyle(color: AppColors.inkFaint, fontFamily: 'monospace'),
              prefixIcon: const Icon(Icons.key_outlined, color: AppColors.inkFaint, size: 18),
              filled: true,
              fillColor: AppColors.surface2,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Used only for natural-language questions. We send masked text — never your images, never full card or Aadhaar numbers.',
            style: TextStyle(fontSize: 11.5, color: AppColors.inkFaint),
          ),
        ],
      ),
    );
  }
}
