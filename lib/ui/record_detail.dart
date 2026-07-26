import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../src/models.dart';
import '../src/validators.dart';
import '../theme.dart';
import 'ui_helpers.dart';

/// One screenshot's structured detail: masked fields with reveal + copy, the
/// verified-on-device trust line, and the move-to-vault action.
class RecordDetail extends StatelessWidget {
  const RecordDetail({super.key, required this.record});
  final ScreenshotRecord record;

  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    final upiField = record.fields.where((f) => f.type == DocType.upiQr);
    final upiVpa = upiField.isEmpty ? null : upiField.first.value;
    return Scaffold(
      appBar: AppBar(title: Text(categoryLabel(record.category))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Preview(),
          if (record.fields.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('No structured fields — this one is filed by its text.',
                  style: TextStyle(color: c.inkDim)),
            )
          else
            ...record.fields.map((f) => Column(
                  children: [
                    MaskedField(field: f),
                    Divider(height: 1, color: c.line),
                  ],
                )),
          if (record.fields.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: c.line),
              ),
              child: Row(children: [
                Icon(Icons.verified_outlined, size: 16, color: c.accent),
                const SizedBox(width: 8),
                Expanded(child: Text('Verified & read on-device', style: TextStyle(color: c.inkDim, fontSize: 12.5))),
              ]),
            ),
          const SizedBox(height: 16),
          if (upiVpa != null) ...[
            FilledButton.icon(
              onPressed: () => _payUpi(context, upiVpa),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Pay via UPI'),
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.accentInk,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 9),
          ],
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.delete_outline),
            label: const Text('Move to Vault & delete original'),
            style: OutlinedButton.styleFrom(
              foregroundColor: c.ink,
              side: BorderSide(color: c.line),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 8),
          Text('The original screenshot stays in your gallery until you delete it.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: c.inkFaint)),
        ],
      ),
    );
  }

  Future<void> _payUpi(BuildContext context, String vpa) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await launchUrl(Uri.parse('upi://pay?pa=$vpa&cu=INR'),
          mode: LaunchMode.externalApplication);
      if (!ok) {
        messenger.showSnackBar(const SnackBar(content: Text('No UPI app found')));
      }
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('No UPI app found')));
    }
  }
}

class _Preview extends StatelessWidget {
  const _Preview();
  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    return Container(
      height: 148,
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, color: c.inkDim, size: 20),
            const SizedBox(height: 7),
            Text('Original hidden', style: TextStyle(color: c.inkDim, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
