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
    _rec('c.png', 'ICICI account IFSC HDFC0001234'),
  ];

  test('finds the HDFC *card*, not the HDFC IFSC row', () {
    final r = searchRecords(records, 'hdfc card');
    expect(r.first.imagePath, 'a.png');
    expect(r.any((x) => x.imagePath == 'c.png'), isFalse);
  });

  test('matches loose OCR text (airbnb wifi)', () {
    final r = searchRecords(records, 'airbnb wifi');
    expect(r.map((x) => x.imagePath), contains('b.png'));
  });

  test('all tokens must match (AND, not OR)', () {
    // "card" matches a; "wifi" matches b; together → nothing.
    expect(searchRecords(records, 'card wifi'), isEmpty);
  });

  test('blank query returns nothing', () {
    expect(searchRecords(records, '   '), isEmpty);
  });
}
