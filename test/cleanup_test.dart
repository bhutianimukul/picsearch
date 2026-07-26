import 'package:flutter_test/flutter_test.dart';
import 'package:picsearch/src/analyzer.dart';
import 'package:picsearch/src/cleanup.dart';
import 'package:picsearch/src/models.dart';

ScreenshotRecord _rec(String path, String text) =>
    ScreenshotRecord(imagePath: path, ocrText: text, analysis: analyzeText(text));

void main() {
  test('detects duplicate cards by extracted value', () {
    final records = [
      _rec('a.png', 'HDFC card 4539 1488 0343 6467'),
      _rec('b.png', 'card 4539-1488-0343-6467 screenshot 2'),
      _rec('c.png', 'WiFi pass hunter2'),
    ];
    final groups = duplicateGroups(records);
    expect(groups.length, 1);
    expect(groups.first.length, 2);
  });

  test('deletable = OTP screenshots + redundant duplicate copies', () {
    final a = _rec('a.png', 'card 4539 1488 0343 6467');
    final b = _rec('b.png', 'card 4539 1488 0343 6467'); // dup of a
    final otp = _rec('c.png', '995123 is your OTP, do not share');
    final unique = _rec('d.png', 'WiFi pass hunter2');

    final candidates = deletableCandidates([a, b, otp, unique]);

    expect(candidates.contains(otp), isTrue); // OTP flagged
    expect(candidates.contains(b), isTrue); // the second copy
    expect(candidates.contains(a), isFalse); // first copy kept
    expect(candidates.contains(unique), isFalse); // unique, keep
    expect(candidates.length, 2);
  });

  test('nothing to clear when everything is unique and non-OTP', () {
    final records = [
      _rec('a.png', 'card 4539 1488 0343 6467'),
      _rec('b.png', 'PAN ABCDE1234F'),
    ];
    expect(deletableCandidates(records), isEmpty);
  });
}
