import 'package:flutter_test/flutter_test.dart';
import 'package:picsearch/src/analyzer.dart';
import 'package:picsearch/src/models.dart';
import 'package:picsearch/src/search.dart';

ScreenshotRecord _rec(String path, String text) =>
    ScreenshotRecord(imagePath: path, ocrText: text, analysis: analyzeText(text));

void main() {
  final records = [
    _rec('a.png', 'HDFC Bank credit card 4111 1111 1111 1111'),
    _rec('b.png', 'WiFi network Airbnb-Goa password hunter2'),
    _rec('c.png', 'CAFE COFFEE DAY Invoice Grand Total Rs 450'),
  ];

  test('ranks the HDFC card first for "hdfc card"', () {
    expect(searchRecords(records, 'hdfc card').first.imagePath, 'a.png');
  });

  test('natural-language query works — filler words are stripped', () {
    // "give me my cafe bill" -> [cafe, bill]; "cafe" hits the receipt.
    final r = searchRecords(records, 'give me my cafe bill');
    expect(r.map((x) => x.imagePath), contains('c.png'));
  });

  test('matches any meaningful token, ranked (not strict AND)', () {
    final r = searchRecords(records, 'card wifi');
    expect(r.map((x) => x.imagePath), containsAll(['a.png', 'b.png']));
  });

  test('blank or stopword-only query returns nothing', () {
    expect(searchRecords(records, '   '), isEmpty);
    expect(searchRecords(records, 'give me the'), isEmpty);
  });
}
