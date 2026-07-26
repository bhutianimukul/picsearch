import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../src/models.dart';
import '../src/search.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'record_detail.dart';
import 'ui_helpers.dart';

const _suggestions = ['My HDFC card', 'Airbnb wifi', 'PAN number', 'Rent UPI QR'];

/// Search over the analysed screenshots — the core "find the pic you mean" flow,
/// by text or voice.
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

  final SpeechToText _speech = SpeechToText();
  bool _speechReady = false;
  bool _listening = false;

  String? _geminiAnswer;
  bool _geminiBusy = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize(
      onStatus: (s) {
        if ((s == 'notListening' || s == 'done') && mounted) {
          setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _speech.stop();
    _ctrl.dispose();
    super.dispose();
  }

  void _setQuery(String v) {
    _ctrl.text = v;
    _ctrl.selection = TextSelection.collapsed(offset: v.length);
    setState(() => _q = v);
  }

  Future<void> _toggleListen() async {
    if (!_speechReady) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice input isn\'t available on this device')));
      return;
    }
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (r) => _setQuery(r.recognizedWords),
      listenOptions: SpeechListenOptions(partialResults: true),
    );
  }

  Future<void> _askGemini() async {
    final state = AppScope.of(context);
    setState(() => _geminiBusy = true);
    try {
      final answer = await state.askGemini(_q);
      if (mounted) setState(() => _geminiAnswer = answer);
    } catch (_) {
      if (mounted) {
        setState(() => _geminiAnswer =
            'Couldn\'t reach Gemini — check your key and connection.');
      }
    } finally {
      if (mounted) setState(() => _geminiBusy = false);
    }
  }

  Widget _geminiPanel(PicColors c) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: _geminiAnswer == null
            ? Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _geminiBusy ? null : _askGemini,
                  icon: _geminiBusy
                      ? SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2, color: c.accent))
                      : Icon(Icons.auto_awesome, size: 16, color: c.accent),
                  label: Text(_geminiBusy ? 'Asking Gemini…' : 'Ask Gemini',
                      style: TextStyle(color: c.accent)),
                ),
              )
            : Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Color.alphaBlend(c.accent.withValues(alpha: 0.08), c.surface),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.accent.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.auto_awesome, size: 15, color: c.accent),
                      const SizedBox(width: 8),
                      Text('GEMINI', style: labelStyle.copyWith(color: c.accent)),
                    ]),
                    const SizedBox(height: 8),
                    Text(_geminiAnswer!,
                        style: TextStyle(color: c.ink, fontSize: 14, height: 1.4)),
                  ],
                ),
              ),
      );

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
                border: Border.all(
                    color: _listening ? c.accent : c.line, width: _listening ? 1.5 : 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: c.inkFaint, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      onChanged: (v) => setState(() {
                        _q = v;
                        _geminiAnswer = null;
                      }),
                      style: TextStyle(color: c.ink, fontSize: 15),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: _listening ? 'Listening…' : 'Ask your screenshots…',
                        hintStyle: TextStyle(
                            color: _listening ? c.accent : c.inkFaint),
                      ),
                    ),
                  ),
                  _MicButton(listening: _listening, onTap: _toggleListen),
                ],
              ),
            ),
          ),
          if (AppScope.of(context).hasGemini && _q.trim().isNotEmpty)
            _geminiPanel(c),
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
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
        children: [
          if (!AppScope.of(context).hasGemini) _aiHint(c),
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: c.accent),
              const SizedBox(width: 8),
              Text('ASK ME THINGS LIKE', style: labelStyle.copyWith(color: c.inkFaint)),
            ],
          ),
          const SizedBox(height: 18),
          for (final s in _suggestions)
            _ThoughtBubble(text: s, onTap: () => _setQuery(s)),
        ],
      );

  Widget _aiHint(PicColors c) => Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Color.alphaBlend(c.accent.withValues(alpha: 0.10), c.surface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.accent.withValues(alpha: 0.35)),
        ),
        child: Row(children: [
          Icon(Icons.auto_awesome, color: c.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Turn on AI search',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text('Add a Gemini key in Settings to ask in your own words. Until then, search matches keywords on-device.',
                    style: TextStyle(color: c.inkDim, fontSize: 12)),
              ],
            ),
          ),
        ]),
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
                    Icon(categoryIcon(r.category), color: categoryColor(r.category), size: 20),
                    const SizedBox(width: 12),
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
                    Icon(Icons.chevron_right, color: c.inkFaint, size: 20),
                  ],
                ),
              ),
            ),
          );
        },
      );

}

/// A suggestion styled as an AI chat bubble — soft accent gradient, a small
/// tail on the bottom-left, sparkle glyph. Left-aligned so they read as a tidy
/// stream rather than scattered chips.
class _ThoughtBubble extends StatelessWidget {
  const _ThoughtBubble({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(c.accent.withValues(alpha: 0.18), c.surface),
                  c.surface,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(6),
              ),
              boxShadow: [
                BoxShadow(
                  color: c.glow.withValues(alpha: 0.13),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 15, color: c.accent),
                const SizedBox(width: 10),
                Text(text,
                    style: TextStyle(
                        color: c.ink, fontSize: 14.5, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.listening, required this.onTap});
  final bool listening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.pic;
    return IconButton(
      onPressed: onTap,
      tooltip: listening ? 'Stop' : 'Voice',
      icon: Icon(listening ? Icons.mic : Icons.mic_none,
          color: listening ? c.accent : c.inkDim),
      style: listening
          ? IconButton.styleFrom(backgroundColor: c.accent.withValues(alpha: 0.16))
          : null,
    );
  }
}
