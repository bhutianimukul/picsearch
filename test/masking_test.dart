import 'package:flutter_test/flutter_test.dart';
import 'package:picsearch/src/validators.dart';
import 'package:picsearch/src/masking.dart';

void main() {
  group('mask', () {
    test('reveals the last 4, hides the rest', () {
      expect(mask('4111111111111111'), '••••••••••••1111');
    });
    test('ignores separators when counting', () {
      expect(mask('4111 1111 1111 1111'), '••••••••••••1111');
    });
    test('returns short values unchanged', () {
      expect(mask('123'), '123');
    });
  });

  group('toField', () {
    test('masks sensitive IDs and keeps the full value on-device', () {
      final f = toField(const Detection(DocType.card, '4111111111111111', '...'));
      expect(f.sensitive, isTrue);
      expect(f.masked, '••••••••••••1111');
      expect(f.value, '4111111111111111'); // full value retained, just not shown
      expect(f.label, 'Card number');
    });

    test('does NOT mask public values (IFSC is a branch code, not a secret)', () {
      final f = toField(const Detection(DocType.ifsc, 'HDFC0001234', 'HDFC0001234'));
      expect(f.sensitive, isFalse);
      expect(f.masked, 'HDFC0001234');
    });

    test('does NOT mask a UPI VPA', () {
      final f = toField(const Detection(DocType.upiQr, 'shop@okaxis', '...'));
      expect(f.sensitive, isFalse);
      expect(f.masked, 'shop@okaxis');
    });
  });
}
