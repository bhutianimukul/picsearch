import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// A single extracted field: label, value (masked until revealed for sensitive
/// ones), a biometric-style reveal toggle, and tap-to-copy.
class MaskedField extends StatefulWidget {
  const MaskedField({super.key, required this.field});
  final ExtractedField field;

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
              onPressed: () => setState(() => _revealed = !_revealed),
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
