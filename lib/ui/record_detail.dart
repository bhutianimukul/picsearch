import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../src/biometric.dart';
import '../src/models.dart';
import '../src/validators.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'ui_helpers.dart';

/// One screenshot's structured detail: a real (blur-gated) image preview, its
/// masked fields with reveal + copy, user-added fields, and type actions.
class RecordDetail extends StatefulWidget {
  const RecordDetail({super.key, required this.record});
  final ScreenshotRecord record;

  @override
  State<RecordDetail> createState() => _RecordDetailState();
}

class _RecordDetailState extends State<RecordDetail> {
  bool _imageRevealed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    final state = AppScope.of(context);
    // Look up the live record so user-added fields appear immediately.
    final record = state.recordByPath(widget.record.imagePath) ?? widget.record;
    final upiField = record.fields.where((f) => f.type == DocType.upiQr);
    final upiVpa = upiField.isEmpty ? null : upiField.first.value;
    final sensitive = record.fields.any((f) => f.sensitive);

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryLabel(record.category)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add a detail',
            onPressed: () => _addDetail(context, state, record),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _preview(c, record, sensitive),
          const SizedBox(height: 6),
          if (record.fields.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Text('No fields yet — tap + to add one.',
                  style: TextStyle(color: c.inkDim)),
            )
          else
            for (final f in record.fields) ...[
              MaskedField(field: f),
              Divider(height: 1, color: c.line),
            ],
          if (record.fields.any((f) => f.sensitive))
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
                Expanded(
                    child: Text('Verified & read on-device',
                        style: TextStyle(color: c.inkDim, fontSize: 12.5))),
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
              minimumSize: const Size.fromHeight(48),
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

  Widget _preview(PicColors c, ScreenshotRecord record, bool sensitive) {
    final file = File(record.imagePath);
    if (!file.existsSync()) return _placeholder(c);

    final image = Image.file(file,
        height: 190,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(c));

    if (!sensitive || _imageRevealed) {
      return ClipRRect(borderRadius: BorderRadius.circular(14), child: image);
    }

    return GestureDetector(
      onTap: () async {
        final ok = await Biometric().confirm('View this image');
        if (ok && mounted) setState(() => _imageRevealed = true);
      },
      child: Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: image,
          ),
        ),
        Positioned.fill(
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: c.ground.withValues(alpha: 0.25),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock_outline, color: c.ink, size: 22),
              const SizedBox(height: 6),
              Text('Tap to view', style: TextStyle(color: c.ink, fontSize: 12)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _placeholder(PicColors c) => Container(
        height: 148,
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.line),
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.image_outlined, color: c.inkDim, size: 22),
            const SizedBox(height: 6),
            Text('No preview', style: TextStyle(color: c.inkDim, fontSize: 12)),
          ]),
        ),
      );

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

  Future<void> _addDetail(
      BuildContext context, AppState state, ScreenshotRecord record) async {
    var label = 'Expiry';
    var sensitive = false;
    final valueCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final c = ctx.pic;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            backgroundColor: c.surface,
            title: const Text('Add a detail'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButton<String>(
                value: label,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Expiry', child: Text('Expiry')),
                  DropdownMenuItem(value: 'Cardholder name', child: Text('Cardholder name')),
                  DropdownMenuItem(value: 'CVV', child: Text('CVV')),
                  DropdownMenuItem(value: 'Note', child: Text('Note')),
                ],
                onChanged: (v) => setLocal(() {
                  label = v!;
                  sensitive = v == 'CVV';
                }),
              ),
              TextField(
                controller: valueCtrl,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Value'),
              ),
            ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: c.accent, foregroundColor: c.accentInk),
                onPressed: () {
                  final v = valueCtrl.text.trim();
                  if (v.isNotEmpty) {
                    state.addFieldToRecord(
                      record.imagePath,
                      ExtractedField(
                        type: DocType.unknown,
                        label: label,
                        value: v,
                        masked: sensitive ? ''.padRight(v.length, '•') : v,
                        sensitive: sensitive,
                      ),
                    );
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }
}
