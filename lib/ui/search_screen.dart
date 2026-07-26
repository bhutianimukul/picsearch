import 'package:flutter/material.dart';

import '../src/models.dart';
import '../src/search.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'record_detail.dart';
import 'ui_helpers.dart';

const _suggestions = ['My HDFC card', 'Airbnb wifi', 'PAN number', 'Rent UPI QR'];

/// Search over the analysed screenshots — the core "find the pic you mean" flow.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});
  final String initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initialQuery);
  late String _q = widget.initialQuery;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setQuery(String v) {
    _ctrl.text = v;
    _ctrl.selection = TextSelection.collapsed(offset: v.length);
    setState(() => _q = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    final records = AppScope.of(context).records;
    final results = searchRecords(records, _q);
    final showSuggestions = _q.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 2, 4, 2),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.line),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: c.inkFaint, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      onChanged: (v) => setState(() => _q = v),
                      style: TextStyle(color: c.ink, fontSize: 15),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Ask your screenshots…',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.mic_none, color: c.accent),
                    tooltip: 'Voice',
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Voice search is coming soon'))),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: showSuggestions
                ? _suggestionsView(c)
                : results.isEmpty
                    ? _noResults(c)
                    : _resultsView(c, results),
          ),
        ],
      ),
    );
  }

  Widget _suggestionsView(PicColors c) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('TRY ASKING', style: labelStyle.copyWith(color: c.inkFaint)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _suggestions)
                GestureDetector(
                  onTap: () => _setQuery(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: c.line),
                    ),
                    child: Text(s, style: TextStyle(color: c.ink, fontSize: 13)),
                  ),
                ),
            ],
          ),
        ],
      );

  Widget _noResults(PicColors c) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, color: c.inkFaint, size: 36),
            const SizedBox(height: 12),
            Text('No matches for “$_q”', style: TextStyle(color: c.inkDim)),
          ],
        ),
      );

  Widget _resultsView(PicColors c, List<ScreenshotRecord> results) =>
      ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        separatorBuilder: (_, _) => const SizedBox(height: 9),
        itemBuilder: (context, i) {
          final r = results[i];
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
                    Icon(categoryIcon(r.category), color: c.inkDim, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(categoryLabel(r.category),
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(primary?.masked ?? _snippet(r.ocrText),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: dataStyle.copyWith(color: c.inkDim, fontSize: 13)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: c.inkFaint, size: 20),
                  ],
                ),
              ),
            ),
          );
        },
      );

  String _snippet(String text) {
    final t = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    return t.length <= 44 ? t : '${t.substring(0, 44)}…';
  }
}
