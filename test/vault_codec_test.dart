import 'package:encrypt/encrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picsearch/src/analyzer.dart';
import 'package:picsearch/src/models.dart';
import 'package:picsearch/src/vault_codec.dart';

ScreenshotRecord _rec(String path, String text) =>
    ScreenshotRecord(imagePath: path, ocrText: text, analysis: analyzeText(text));

void main() {
  test('records survive an encrypt → decrypt round-trip', () {
    final recs = [
      _rec('a.png', 'HDFC card 4111 1111 1111 1111'),
      _rec('b.png', 'WiFi password hunter2'),
    ];
    final codec = VaultCodec(Key.fromLength(32));

    final back = codec.decode(codec.encode(recs));

    expect(back.length, 2);
    expect(back[0].imagePath, 'a.png');
    expect(back[0].category, Category.card);
    expect(back[0].fields.first.value, '4111111111111111');
    expect(back[0].fields.first.masked, '••••••••••••1111');
    expect(back[0].fields.first.sensitive, isTrue);
    expect(back[1].category, Category.credential);
  });

  test('the stored bytes do not contain the plaintext card number', () {
    final bytes = VaultCodec(Key.fromLength(32))
        .encode([_rec('a', 'card 4111 1111 1111 1111')]);
    expect(String.fromCharCodes(bytes).contains('4111111111111111'), isFalse);
  });
}
