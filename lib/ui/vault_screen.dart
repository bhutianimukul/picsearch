import 'package:flutter/material.dart';

import '../src/cleanup.dart';
import '../src/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'cleanup_screen.dart';
import 'record_detail.dart';
import 'ui_helpers.dart';

/// The "everything" view: categories with counts (the album grid, now a calm
/// list). Tapping a category drills into its records.
class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    final state = AppScope.of(context);
    final counts = state.categoryCounts;
    final cats = counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    final cleanup = deletableCandidates(state.records);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault'),
        actions: [Padding(padding: const EdgeInsets.only(right: 16), child: Icon(Icons.lock_outline, color: c.inkDim))],
      ),
      body: state.records.isEmpty
          ? const _Empty()
          : Column(
              children: [
                if (cleanup.isNotEmpty) _CleanupBanner(count: cleanup.length),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cats.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, i) => _CategoryRow(category: cats[i], count: counts[cats[i]]!),
                  ),
                ),
              ],
            ),
    );
  }
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

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.count});
  final Category category;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => _CategoryScreen(category: category)),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: categoryColor(category).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(categoryIcon(category), size: 18, color: categoryColor(category)),
              ),
              const SizedBox(width: 13),
              Text(categoryLabel(category), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('$count', style: dataStyle.copyWith(color: c.inkDim, fontSize: 13)),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: c.inkFaint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryScreen extends StatelessWidget {
  const _CategoryScreen({required this.category});
  final Category category;

  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    final records = AppScope.of(context).byCategory(category);
    return Scaffold(
      appBar: AppBar(title: Text(categoryLabel(category))),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(recordTitle(r),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(primary?.masked ?? categoryLabel(category),
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
