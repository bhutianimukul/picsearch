import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'search_screen.dart';
import 'ui_helpers.dart';

/// Home A — ask-first. Ambient aurora + screenshots orbiting a vault mark, with
/// the search + voice docked at the bottom (decisions §11).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.pic;
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
                    Text('Good evening', style: TextStyle(color: c.inkDim, fontSize: 13)),
                    const Spacer(),
                    Icon(Icons.lock_outline, color: c.inkDim, size: 20),
                  ],
                ),
                if (state.newCount > 0) _NewBanner(count: state.newCount),
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
                        style: TextStyle(color: c.inkDim, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: const [_Ghost('My HDFC card'), _Ghost('Airbnb wifi')],
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

void _openSearch(BuildContext context, [String query = '']) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => SearchScreen(initialQuery: query)),
  );
}

class _NewBanner extends StatelessWidget {
  const _NewBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Material(
        color: Color.alphaBlend(c.accent.withValues(alpha: 0.10), c.surface),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => AppScope.of(context).scanNewScreenshots(),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.accent.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_motion, color: c.accent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$count new screenshot${count == 1 ? '' : 's'}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('Tap to read & sort',
                          style: TextStyle(color: c.inkDim, fontSize: 12)),
                    ],
                  ),
                ),
                Text('Sort', style: TextStyle(color: c.accent, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Ghost extends StatelessWidget {
  const _Ghost(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    return GestureDetector(
      onTap: () => _openSearch(context, text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.line),
        ),
        child: Text(text, style: TextStyle(fontSize: 12, color: c.inkDim)),
      ),
    );
  }
}

class _SearchDock extends StatelessWidget {
  const _SearchDock();
  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    return GestureDetector(
      onTap: () => _openSearch(context),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.line),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: c.inkFaint, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Ask, or hold to speak…',
                  style: TextStyle(color: c.inkFaint, fontSize: 15)),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.accent.withValues(alpha: 0.18),
                boxShadow: [BoxShadow(color: c.glow.withValues(alpha: 0.45), blurRadius: 20)],
              ),
              child: Icon(Icons.mic_none, color: c.accent, size: 18),
            ),
          ],
        ),
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
    final c = context.pic;
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
                  child: _orbitCard(c),
                ),
              child!,
            ],
          );
        },
        child: Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: c.accent.withValues(alpha: 0.26)),
            boxShadow: [BoxShadow(color: c.glow.withValues(alpha: 0.42), blurRadius: 46)],
          ),
          child: Icon(Icons.lock_outline, color: c.accent, size: 38),
        ),
      ),
    );
  }

  Widget _orbitCard(PicColors c) => Container(
        width: 38,
        height: 27,
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: c.line),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 6))],
        ),
      );
}
