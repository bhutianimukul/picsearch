import 'package:flutter/material.dart';

import '../src/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'cleanup_screen.dart';
import 'record_detail.dart';
import 'ui_helpers.dart';

/// The "everything" view. With a Gemini key set, screenshots are grouped into
/// AI-named smart folders; otherwise into the on-device type categories.
class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    final state = AppScope.of(context);
    final ai = state.aiReady;
    final groups = _buildGroups(state);
    final cleanup = state.cleanupCandidates;
    final firstRun = ai && state.grouping && groups.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault'),
        actions: [
          if (ai)
            state.grouping
                ? Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: c.accent),
                      ),
                    ),
                  )
                : IconButton(
                    icon: Icon(Icons.auto_awesome, color: c.accent, size: 20),
                    tooltip: 'Regroup with AI',
                    onPressed: () => state.regroupWithAi(),
                  ),
        ],
      ),
      body: state.records.isEmpty
          ? const _Empty()
          : firstRun
              ? _SortingState(c: c)
              : Column(
                  children: [
                    if (ai) _SmartHeader(c: c),
                    if (cleanup.isNotEmpty) _CleanupBanner(count: cleanup.length),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: groups.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 9),
                        itemBuilder: (context, i) =>
                            _GroupRow(group: groups[i], aiMode: ai),
                      ),
                    ),
                  ],
                ),
    );
  }

  List<_Group> _buildGroups(AppState state) {
    if (state.hasGemini) {
      final map = <String, List<ScreenshotRecord>>{};
      for (final r in state.records) {
        (map[r.aiGroup ?? 'Unsorted'] ??= <ScreenshotRecord>[]).add(r);
      }
      final keys = map.keys.toList()
        ..sort((a, b) => map[b]!.length.compareTo(map[a]!.length));
      return [for (final k in keys) _Group(k, groupChip(k), map[k]!)];
    }
    final map = <Category, List<ScreenshotRecord>>{};
    for (final r in state.records) {
      (map[r.category] ??= <ScreenshotRecord>[]).add(r);
    }
    final keys = map.keys.toList()
      ..sort((a, b) => map[b]!.length.compareTo(map[a]!.length));
    return [for (final k in keys) _Group(categoryLabel(k), categoryChip(k), map[k]!)];
  }
}

class _Group {
  _Group(this.label, this.chip, this.records);
  final String label;
  final Widget chip;
  final List<ScreenshotRecord> records;
}

class _SmartHeader extends StatelessWidget {
  const _SmartHeader({required this.c});
  final PicColors c;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
        child: Row(children: [
          Icon(Icons.auto_awesome, size: 14, color: c.accent),
          const SizedBox(width: 7),
          Text('Smart folders · grouped by AI',
              style: TextStyle(fontSize: 12, color: c.inkDim)),
        ]),
      );
}

class _SortingState extends StatelessWidget {
  const _SortingState({required this.c});
  final PicColors c;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: c.accent),
            ),
            const SizedBox(height: 18),
            const Text('Sorting into smart folders…',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Reading masked text only — never your images.',
                style: TextStyle(color: c.inkDim, fontSize: 12.5)),
          ],
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_a_photo_outlined, size: 40, color: c.inkFaint),
          const SizedBox(height: 14),
          const Text('Nothing here yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Tap Scan to read your screenshots', style: TextStyle(color: c.inkDim)),
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.group, required this.aiMode});
  final _Group group;
  final bool aiMode;

  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => _GroupScreen(title: group.label, aiMode: aiMode)),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: [
              group.chip,
              const SizedBox(width: 13),
              Expanded(
                child: Text(group.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              Text('${group.records.length}',
                  style: dataStyle.copyWith(color: c.inkDim, fontSize: 13)),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: c.inkFaint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupScreen extends StatelessWidget {
  const _GroupScreen({required this.title, required this.aiMode});
  final String title;
  final bool aiMode;

  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    final records = AppScope.of(context).records.where((r) {
      final key = aiMode ? (r.aiGroup ?? 'Unsorted') : categoryLabel(r.category);
      return key == title;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        separatorBuilder: (_, _) => const SizedBox(height: 9),
        itemBuilder: (context, i) {
          final r = records[i];
          final primary = r.fields.isNotEmpty ? r.fields.first : null;
          return Material(
            color: c.surface,
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => RecordDetail(record: r)),
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: c.line),
                ),
                child: Row(
                  children: [
                    categoryChip(r.category, size: 38),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(recordTitle(r),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(primary?.masked ?? categoryLabel(r.category),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: dataStyle.copyWith(color: c.inkDim, fontSize: 13)),
                        ],
                      ),
                    ),
                    if (r.fields.isNotEmpty) Icon(Icons.verified_outlined, size: 16, color: c.accent),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right, color: c.inkFaint, size: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CleanupBanner extends StatelessWidget {
  const _CleanupBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const CleanupScreen())),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: c.accent.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_delete_outlined, color: c.accent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('$count item${count == 1 ? '' : 's'} you can clear',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                ),
                Text('Review',
                    style: TextStyle(color: c.accent, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
