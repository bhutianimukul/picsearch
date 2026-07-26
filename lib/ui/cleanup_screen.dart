import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'record_detail.dart';
import 'ui_helpers.dart';

/// Lists the screenshots PicSearch suggests clearing (OTP codes + duplicates)
/// and clears them from the vault in one tap.
class CleanupScreen extends StatelessWidget {
  const CleanupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    final state = AppScope.of(context);
    final candidates = state.cleanupCandidates;

    return Scaffold(
      appBar: AppBar(title: const Text('Review & clear')),
      body: candidates.isEmpty
          ? Center(child: Text('Nothing to clear', style: TextStyle(color: c.inkDim)))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: candidates.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, i) {
                      final r = candidates[i];
                      final primary = r.fields.isNotEmpty ? r.fields.first : null;
                      return Material(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(13),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(13),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => RecordDetail(record: r)),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(color: c.line),
                            ),
                            child: Row(
                              children: [
                                categoryChip(r.category),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(state.cleanupReason(r),
                                          style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text(primary?.masked ?? _snippet(r.ocrText),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: dataStyle.copyWith(
                                              color: c.inkDim, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: c.inkFaint, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await state.removeRecords(candidates);
                        navigator.pop();
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: Text('Clear ${candidates.length} from vault'),
                      style: FilledButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: c.accentInk,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _snippet(String text) {
    final t = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    return t.length <= 44 ? t : '${t.substring(0, 44)}…';
  }
}
