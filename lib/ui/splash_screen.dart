import 'package:flutter/material.dart';

import '../theme.dart';
import 'root_shell.dart';

/// Animated splash that pitches the app: scattered screenshots converge into a
/// stack and a lock seals them (decisions §11). Navigates to the shell on done.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();

  static const _scatter = [
    Offset(-0.55, -0.55),
    Offset(0.52, -0.42),
    Offset(-0.6, 0.18),
    Offset(0.58, 0.30),
    Offset(-0.05, 0.62),
  ];
  static const _tags = ['CARD', 'AADHAAR', 'WIFI', 'UPI', 'RECEIPT'];

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RootShell()),
        );
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final conv = Curves.easeInOut.transform(((t - 0.30) / 0.35).clamp(0.0, 1.0));
            final fadeIn = (t * 3.5).clamp(0.0, 1.0);
            final sealT = Curves.easeOut.transform(((t - 0.60) / 0.22).clamp(0.0, 1.0));
            final wordT = ((t - 0.70) / 0.3).clamp(0.0, 1.0);
            return SizedBox(
              width: 280,
              height: 440,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (var i = 0; i < _scatter.length; i++)
                    Transform.translate(
                      offset: Offset.lerp(
                          _scatter[i] * 118, const Offset(0, -34), conv)!,
                      child: Opacity(
                        opacity: fadeIn * (1 - sealT * 0.85),
                        child: _card(_tags[i], conv),
                      ),
                    ),
                  Opacity(
                    opacity: sealT,
                    child: Transform.scale(
                      scale: 0.6 + 0.4 * sealT,
                      child: _seal(),
                    ),
                  ),
                  Positioned(
                    bottom: 74,
                    child: Opacity(
                      opacity: wordT,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - wordT)),
                        child: _word(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _card(String tag, double conv) => Container(
        width: 96,
        height: 66,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.line),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 44, height: 6, color: AppColors.ink.withValues(alpha: 0.16)),
            const SizedBox(height: 6),
            Container(width: 68, height: 12, color: AppColors.ink.withValues(alpha: 0.16)),
            const Spacer(),
            Opacity(
              opacity: (conv * 1.4).clamp(0.0, 1.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tag,
                    style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentInk)),
              ),
            ),
          ],
        ),
      );

  Widget _seal() => Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
          boxShadow: [BoxShadow(color: AppColors.glow.withValues(alpha: 0.45), blurRadius: 34)],
        ),
        child: const Icon(Icons.lock_outline, color: AppColors.accent, size: 27),
      );

  Widget _word() => const Column(
        children: [
          Text('PicSearch',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink)),
          SizedBox(height: 6),
          Text('800 screenshots. Zero chaos.',
              style: TextStyle(fontSize: 12, color: AppColors.inkDim)),
        ],
      );
}
