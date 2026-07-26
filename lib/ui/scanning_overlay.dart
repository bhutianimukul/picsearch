import 'package:flutter/material.dart';

import '../theme.dart';

/// Full-screen overlay shown while screenshots are being read: a card being
/// swept by a scan line, plus "reading X of N" progress. Turns the OCR wait
/// into a moment instead of a freeze.
class ScanningOverlay extends StatefulWidget {
  const ScanningOverlay({super.key, required this.done, required this.total});
  final int done;
  final int total;

  @override
  State<ScanningOverlay> createState() => _ScanningOverlayState();
}

class _ScanningOverlayState extends State<ScanningOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    final progress = widget.total == 0 ? null : widget.done / widget.total;
    return Positioned.fill(
      // Material (not a bare Container) so the Text has a Material ancestor —
      // otherwise Flutter paints the yellow debug underline under it.
      child: Material(
        color: c.ground.withValues(alpha: 0.94),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (_, _) => CustomPaint(
                    painter: _ScanPainter(_c.value, c.accent, c.glow, c.line),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text('Reading your screenshots',
                  style: TextStyle(color: c.ink, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('${widget.done} of ${widget.total}',
                  style: dataStyle.copyWith(color: c.accent, fontSize: 15)),
              const SizedBox(height: 22),
              SizedBox(
                width: 190,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: c.surface2,
                    valueColor: AlwaysStoppedAnimation(c.accent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanPainter extends CustomPainter {
  _ScanPainter(this.t, this.accent, this.glow, this.line);
  final double t;
  final Color accent, glow, line;

  @override
  void paint(Canvas canvas, Size size) {
    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.14, size.height * 0.12, size.width * 0.72, size.height * 0.76),
      const Radius.circular(16),
    );
    canvas.drawRRect(card, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = line);

    // faux text lines
    final bar = Paint()..color = line;
    for (var i = 0; i < 3; i++) {
      final y = size.height * 0.3 + i * size.height * 0.16;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.24, y, size.width * (0.52 - i * 0.1), 7),
          const Radius.circular(4),
        ),
        bar,
      );
    }

    // sweeping scan line + glow, clipped to the card
    canvas.save();
    canvas.clipRRect(card);
    final y = size.height * 0.12 + t * size.height * 0.76;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.14, y - 16, size.width * 0.72, 32),
      Paint()..color = glow.withValues(alpha: 0.28),
    );
    canvas.drawLine(
      Offset(size.width * 0.14, y),
      Offset(size.width * 0.86, y),
      Paint()..color = accent..strokeWidth = 3,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScanPainter old) => old.t != t;
}
