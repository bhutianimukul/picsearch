import 'package:flutter_test/flutter_test.dart';
import 'package:picsearch/src/validators.dart';

void main() {
  group('Luhn (card numbers)', () {
    test('accepts known-valid card numbers', () {
      expect(isValidLuhn('4111111111111111'), isTrue); // Visa test number
      expect(isValidLuhn('4539148803436467'), isTrue);
      expect(isValidLuhn('5500005555555559'), isTrue); // Mastercard test
    });

    test('rejects a single-digit tamper', () {
      expect(isValidLuhn('4111111111111112'), isFalse);
    });

    test('rejects non-digits and wrong lengths', () {
      expect(isValidLuhn('4111-1111-1111-1111'), isFalse); // separators
      expect(isValidLuhn('411111'), isFalse); // too short
      expect(isValidLuhn(''), isFalse);
    });
  });

  group('Verhoeff', () {
    test('accepts a known-valid number', () {
      expect(isValidVerhoeff('2363'), isTrue);
    });

    test('rejects a tampered check digit', () {
      expect(isValidVerhoeff('2364'), isFalse);
    });

    test('generated check digit always validates (round-trip)', () {
      for (final payload in ['123456789', '23456789012', '9', '5551212']) {
        final full = '$payload${verhoeffCheckDigit(payload)}';
        expect(isValidVerhoeff(full), isTrue, reason: 'payload=$payload');
      }
    });
  });

  group('Aadhaar', () {
    // Build a genuinely valid 12-digit Aadhaar from an 11-digit base.
    final base = '23456789012'; // 11 digits, first digit in [2-9]
    final validAadhaar = '$base${verhoeffCheckDigit(base)}';

    test('accepts a checksum-valid Aadhaar', () {
      expect(isValidAadhaar(validAadhaar), isTrue);
    });

    test('accepts the same number formatted with spaces', () {
      final spaced = '${validAadhaar.substring(0, 4)} '
          '${validAadhaar.substring(4, 8)} '
          '${validAadhaar.substring(8, 12)}';
      expect(isValidAadhaar(spaced), isTrue);
    });

    test('rejects a checksum tamper', () {
      final lastDigit = int.parse(validAadhaar[11]);
      final tampered = validAadhaar.substring(0, 11) + ((lastDigit + 1) % 10).toString();
      expect(isValidAadhaar(tampered), isFalse);
    });

    test('rejects reserved leading digits 0 and 1', () {
      expect(isValidAadhaar('012345678901'), isFalse);
      expect(isValidAadhaar('112345678901'), isFalse);
    });

    test('rejects wrong length', () {
      expect(isValidAadhaar('2345678901'), isFalse);
    });
  });

  group('PAN', () {
    test('accepts a valid PAN, case-insensitively', () {
      expect(isValidPan('ABCDE1234F'), isTrue);
      expect(isValidPan('abcde1234f'), isTrue);
    });
    test('rejects structural violations', () {
      expect(isValidPan('ABCD1234F'), isFalse); // 4 leading letters
      expect(isValidPan('ABCDE12345'), isFalse); // trailing digit
      expect(isValidPan('ABCDE1234'), isFalse); // too short
    });
  });

  group('IFSC', () {
    test('accepts a valid IFSC', () {
      expect(isValidIfsc('HDFC0001234'), isTrue);
      expect(isValidIfsc('hdfc0abcdef'), isTrue);
    });
    test('requires the mandatory 0 in position 5', () {
      expect(isValidIfsc('HDFC1001234'), isFalse);
    });
    test('rejects wrong length', () {
      expect(isValidIfsc('HDFC000123'), isFalse);
    });
  });

  group('UPI URI', () {
    test('parses payee, name and amount with url-decoding', () {
      final m = parseUpiUri('upi://pay?pa=shop@okaxis&pn=Corner%20Store&am=250&cu=INR');
      expect(m, isNotNull);
      expect(m!['pa'], 'shop@okaxis');
      expect(m['pn'], 'Corner Store');
      expect(m['am'], '250');
    });
    test('returns null for non-UPI strings', () {
      expect(parseUpiUri('https://example.com'), isNull);
    });
  });

  group('detectFromText (verify, don\'t guess)', () {
    final base = '23456789012';
    final validAadhaar = '$base${verhoeffCheckDigit(base)}';

    test('finds every valid artifact in a messy block', () {
      final text = '''
        Name: Rahul   PAN ABCDE1234F
        Aadhaar ${validAadhaar.substring(0, 4)} ${validAadhaar.substring(4, 8)} ${validAadhaar.substring(8, 12)}
        HDFC Bank  IFSC: HDFC0001234
        Card 4111 1111 1111 1111
        Pay: upi://pay?pa=shop@okaxis&pn=Store
      ''';
      final found = detectFromText(text);
      final types = found.map((d) => d.type).toSet();
      expect(types, containsAll([
        DocType.pan,
        DocType.aadhaar,
        DocType.ifsc,
        DocType.card,
        DocType.upiQr,
      ]));
      expect(found.firstWhere((d) => d.type == DocType.card).value,
          '4111111111111111');
      expect(found.firstWhere((d) => d.type == DocType.aadhaar).value,
          validAadhaar);
    });

    test('does NOT report a checksum-invalid 12-digit number as Aadhaar', () {
      // 000000000000 is 12 digits but fails leading-digit + Verhoeff.
      final found = detectFromText('ref 0000 0000 0000 end');
      expect(found.where((d) => d.type == DocType.aadhaar), isEmpty);
    });

    test('deduplicates repeated values', () {
      final found = detectFromText('PAN ABCDE1234F and again ABCDE1234F');
      expect(found.where((d) => d.type == DocType.pan).length, 1);
    });
  });
}
