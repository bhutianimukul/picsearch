import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'ui_helpers.dart';

/// Home A — ask-first. Ambient aurora + screenshots orbiting a vault mark, with
/// the search + voice docked at the bottom (decisions §11).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final count = state.records.length;
    return Stack(
      children: [
        const AuroraBackground(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text('Good evening', style: TextStyle(color: AppColors.inkDim, fontSize: 13)),
                    const Spacer(),
                    const Icon(Icons.lock_outline, color: AppColors.inkDim, size: 20),
                  ],
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _OrbitMark(),
                      const SizedBox(height: 22),
                      const Text('What are you looking for?',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                        count == 0
                            ? 'Tap Scan to read your screenshots'
                            : '$count screenshot${count == 1 ? '' : 's'}, read & ready',
                        style: const TextStyle(color: AppColors.inkDim, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: const [
                    _Ghost('My HDFC card'),
                    _Ghost('Airbnb wifi'),
                  ],
                ),
                const SizedBox(height: 12),
                const _SearchDock(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Ghost extends StatelessWidget {
  const _Ghost(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.line),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.inkDim)),
      );
}

class _SearchDock extends StatelessWidget {
  const _SearchDock();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.inkFaint, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Ask, or hold to speak…',
                style: TextStyle(color: AppColors.inkFaint, fontSize: 15)),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.18),
              boxShadow: [BoxShadow(color: AppColors.glow.withValues(alpha: 0.45), blurRadius: 20)],
            ),
            child: const Icon(Icons.mic_none, color: AppColors.accent, size: 18),
          ),
        ],
      ),
    );
  }
}

/// A vault mark with mini-screenshots slowly orbiting it.
class _OrbitMark extends StatefulWidget {
  const _OrbitMark();
  @override
  State<_OrbitMark> createState() => _OrbitMarkState();
}

class _OrbitMarkState extends State<_OrbitMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final base = _c.value * 2 * math.pi;
          return Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Transform.translate(
                  offset: Offset(
                    math.cos(base + i * 2 * math.pi / 3) * 84,
                    math.sin(base + i * 2 * math.pi / 3) * 84,
                  ),
                  child: _orbitCard(),
                ),
              child!,
            ],
          );
        },
        child: Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.26)),
            boxShadow: [BoxShadow(color: AppColors.glow.withValues(alpha: 0.42), blurRadius: 46)],
          ),
          child: const Icon(Icons.lock_outline, color: AppColors.accent, size: 38),
        ),
      ),
    );
  }

  Widget _orbitCard() => Container(
        width: 38,
        height: 27,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.line),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 6))],
        ),
      );
}
