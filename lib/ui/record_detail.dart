import 'package:flutter/material.dart';

import '../src/models.dart';
import '../theme.dart';
import 'ui_helpers.dart';

/// One screenshot's structured detail: masked fields with reveal + copy, the
/// verified-on-device trust line, and the move-to-vault action.
class RecordDetail extends StatelessWidget {
  const RecordDetail({super.key, required this.record});
  final ScreenshotRecord record;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categoryLabel(record.category)), backgroundColor: AppColors.ground),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Preview(),
          if (record.fields.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No structured fields — this one is filed by its text.',
                  style: TextStyle(color: AppColors.inkDim)),
            )
          else
            ...record.fields.map((f) => Column(
                  children: [
                    MaskedField(field: f),
                    const Divider(height: 1, color: AppColors.line),
                  ],
                )),
          if (record.fields.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.line),
              ),
              child: const Row(children: [
                Icon(Icons.verified_outlined, size: 16, color: AppColors.accent),
                SizedBox(width: 8),
                Expanded(child: Text('Verified & read on-device', style: TextStyle(color: AppColors.inkDim, fontSize: 12.5))),
              ]),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.delete_outline),
            label: const Text('Move to Vault & delete original'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.line),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 8),
          const Text('The original screenshot stays in your gallery until you delete it.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: AppColors.inkFaint)),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 148,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, color: AppColors.inkDim, size: 20),
              SizedBox(height: 7),
              Text('Original hidden', style: TextStyle(color: AppColors.inkDim, fontSize: 12)),
            ],
          ),
        ),
      );
}
