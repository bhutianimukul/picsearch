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
    final state = AppScope.of(context);
    final counts = state.categoryCounts;
    final cats = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault'),
        backgroundColor: AppColors.ground,
        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.lock_outline, color: AppColors.inkDim))],
      ),
      body: state.records.isEmpty
          ? const _Empty()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cats.length,
              separatorBuilder: (_, _) => const SizedBox(height: 9),
              itemBuilder: (context, i) {
                final c = cats[i];
                return _CategoryRow(category: c, count: counts[c]!);
              },
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.inkFaint),
            SizedBox(height: 14),
            Text('Nothing here yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text('Tap Scan to read your screenshots', style: TextStyle(color: AppColors.inkDim)),
          ],
        ),
      );
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.count});
  final Category category;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
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
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(9)),
                child: Icon(categoryIcon(category), size: 18, color: AppColors.inkDim),
              ),
              const SizedBox(width: 13),
              Text(categoryLabel(category), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('$count', style: dataStyle.copyWith(color: AppColors.inkDim, fontSize: 13)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: AppColors.inkFaint, size: 20),
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
    final records = AppScope.of(context).byCategory(category);
    return Scaffold(
      appBar: AppBar(title: Text(categoryLabel(category)), backgroundColor: AppColors.ground),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        separatorBuilder: (_, _) => const SizedBox(height: 9),
        itemBuilder: (context, i) {
          final r = records[i];
          final primary = r.fields.isNotEmpty ? r.fields.first : null;
          return Material(
            color: AppColors.surface,
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
                  border: Border.all(color: AppColors.line),
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
                              style: dataStyle.copyWith(color: AppColors.inkDim, fontSize: 14)),
                        ],
                      ),
                    ),
                    if (r.fields.isNotEmpty)
                      const Icon(Icons.verified_outlined, size: 16, color: AppColors.accent),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right, color: AppColors.inkFaint, size: 20),
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
