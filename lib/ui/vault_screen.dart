import 'package:flutter/material.dart';

import '../src/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault'),
        actions: [Padding(padding: const EdgeInsets.only(right: 16), child: Icon(Icons.lock_outline, color: c.inkDim))],
      ),
      body: state.records.isEmpty
          ? const _Empty()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cats.length,
              separatorBuilder: (_, _) => const SizedBox(height: 9),
              itemBuilder: (context, i) => _CategoryRow(category: cats[i], count: counts[cats[i]]!),
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
                decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(9)),
                child: Icon(categoryIcon(category), size: 18, color: c.inkDim),
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
                          Text(primary?.label ?? categoryLabel(category),
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(primary?.masked ?? _snippet(r.ocrText),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: dataStyle.copyWith(color: c.inkDim, fontSize: 14)),
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

  String _snippet(String text) {
    final t = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    return t.length <= 40 ? t : '${t.substring(0, 40)}…';
  }
}
