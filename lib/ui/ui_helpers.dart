import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../src/biometric.dart';
import '../src/models.dart';
import '../theme.dart';

String categoryLabel(Category c) {
  switch (c) {
    case Category.aadhaar:
      return 'Aadhaar';
    case Category.pan:
      return 'PAN';
    case Category.card:
      return 'Cards';
    case Category.bank:
      return 'Bank';
    case Category.upiQr:
      return 'UPI QRs';
    case Category.credential:
      return 'Wifi & codes';
    case Category.recipe:
      return 'Recipes';
    case Category.ticket:
      return 'Tickets';
    case Category.receipt:
      return 'Receipts';
    case Category.otp:
      return 'OTPs';
    case Category.social:
      return 'Social';
    case Category.other:
      return 'Other';
  }
}

/// A human title for a record row: the field label if we extracted one, else a
/// short lead from the OCR text (so a receipt shows "CAFE COFFEE DAY…", not the
/// redundant category name).
String recordTitle(ScreenshotRecord r) {
  if (r.fields.isNotEmpty) return r.fields.first.label;
  final t = r.ocrText.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t.isEmpty) return categoryLabel(r.category);
  return t.length <= 30 ? t : '${t.substring(0, 30)}…';
}

/// A distinct, muted hue per category — used to tint the type icons so the
/// Vault/search read lively at a glance, while cards/surfaces stay monochrome.
Color categoryColor(Category c) {
  switch (c) {
    case Category.card:
      return const Color(0xFF5B9BD5); // blue
    case Category.aadhaar:
      return const Color(0xFFE0A15E); // amber
    case Category.pan:
      return const Color(0xFFC98BE0); // violet
    case Category.bank:
      return const Color(0xFF5FB0A0); // teal
    case Category.upiQr:
      return const Color(0xFF7FBF6A); // green
    case Category.credential:
      return const Color(0xFFE08A8A); // coral
    case Category.recipe:
      return const Color(0xFF8FB96A); // olive
    case Category.ticket:
      return const Color(0xFFE08FB8); // pink
    case Category.receipt:
      return const Color(0xFFE0B85E); // gold
    case Category.otp:
      return const Color(0xFFE07A6A); // red
    case Category.social:
      return const Color(0xFF6AB0D0); // cyan
    case Category.other:
      return const Color(0xFF9AA3B8); // grey
  }
}

IconData categoryIcon(Category c) {
  switch (c) {
    case Category.aadhaar:
    case Category.pan:
      return Icons.badge_outlined;
    case Category.card:
      return Icons.credit_card;
    case Category.bank:
      return Icons.account_balance_outlined;
    case Category.upiQr:
      return Icons.qr_code_2;
    case Category.credential:
      return Icons.wifi;
    case Category.recipe:
      return Icons.restaurant;
    case Category.ticket:
      return Icons.confirmation_number_outlined;
    case Category.receipt:
      return Icons.receipt_long;
    case Category.otp:
      return Icons.pin_outlined;
    case Category.social:
      return Icons.tag;
    case Category.other:
      return Icons.folder_outlined;
  }
}

/// The tinted rounded-square icon chip for a category. Shared by every list row
/// (Vault, search results, cleanup) so the three read as one visual language.
Widget categoryChip(Category c, {double size = 34}) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: categoryColor(c).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(categoryIcon(c), size: size * 0.53, color: categoryColor(c)),
    );

/// A single extracted field: label, value (masked until revealed for sensitive
/// ones), a biometric-style reveal toggle, and tap-to-copy.
class MaskedField extends StatefulWidget {
  const MaskedField({super.key, required this.field, this.confirmReveal});
  final ExtractedField field;

  /// Gate applied before revealing a sensitive value (defaults to device
  /// biometrics). Injectable so widget tests can bypass the platform channel.
  final Future<bool> Function(String reason)? confirmReveal;

  @override
  State<MaskedField> createState() => _MaskedFieldState();
}

class _MaskedFieldState extends State<MaskedField> {
  bool _revealed = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.field.value));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Copied ${widget.field.label}'),
        duration: const Duration(milliseconds: 1400),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    final f = widget.field;
    final showFull = _revealed || !f.sensitive;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.label.toUpperCase(), style: labelStyle.copyWith(color: c.inkFaint)),
                const SizedBox(height: 5),
                Text(
                  showFull ? f.value : f.masked,
                  style: dataStyle.copyWith(
                    fontSize: 16,
                    color: (showFull && f.sensitive) ? c.accent : c.ink,
                  ),
                ),
              ],
            ),
          ),
          if (f.sensitive)
            IconButton(
              icon: Icon(_revealed ? Icons.lock_open : Icons.lock_outline),
              color: _revealed ? c.accent : c.inkDim,
              tooltip: _revealed ? 'Hide' : 'Reveal',
              onPressed: () async {
                if (_revealed) {
                  setState(() => _revealed = false);
                  return;
                }
                final gate = widget.confirmReveal ?? (r) => Biometric().confirm(r);
                final ok = await gate('Reveal ${widget.field.label}');
                if (ok && mounted) setState(() => _revealed = true);
              },
            ),
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            color: c.inkDim,
            tooltip: 'Copy',
            onPressed: _copy,
          ),
        ],
      ),
    );
  }
}

/// Soft ambient glow behind the home content (the calm "aurora").
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    return IgnorePointer(
      child: Stack(children: [
        _blob(const Alignment(-1.1, -0.7), c.glow),
        _blob(const Alignment(1.2, 0.9), c.accent),
      ]),
    );
  }

  Widget _blob(Alignment a, Color color) => Align(
        alignment: a,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withValues(alpha: 0.26), Colors.transparent],
            ),
          ),
        ),
      );
}
