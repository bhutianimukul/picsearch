import 'package:flutter_test/flutter_test.dart';
import 'package:picsearch/src/validators.dart';
import 'package:picsearch/src/models.dart';
import 'package:picsearch/src/analyzer.dart';

void main() {
  test('card screenshot → card category + one masked field', () {
    final r = analyzeText('HDFC Bank card 4111 1111 1111 1111 valid thru 05/28');
    expect(r.category, Category.card);
    final card = r.fields.firstWhere((f) => f.type == DocType.card);
    expect(card.masked, '••••••••••••1111');
    expect(card.value, '4111111111111111');
  });

  test('wifi screenshot → credential, exposes no sensitive fields', () {
    final r = analyzeText('WiFi: MyHome   Password: s3cret!');
    expect(r.category, Category.credential);
    expect(r.fields.where((f) => f.sensitive), isEmpty);
  });

  test('otp screenshot is tagged deletable', () {
    final r = analyzeText('995123 is your OTP. Do not share with anyone.');
    expect(r.category, Category.otp);
    expect(r.tags, contains('deletable:otp'));
  });
}
