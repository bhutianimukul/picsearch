import 'package:flutter_test/flutter_test.dart';
import 'package:snapvault/src/validators.dart';
import 'package:snapvault/src/models.dart';
import 'package:snapvault/src/classifier.dart';

void main() {
  group('classifyByKeywords', () {
    test('detects credential / recipe / receipt / otp', () {
      expect(classifyByKeywords('WiFi password: hunter2'), Category.credential);
      expect(classifyByKeywords('Ingredients: 2 cups flour'), Category.recipe);
      expect(classifyByKeywords('Grand Total 450 incl GST'), Category.receipt);
      expect(classifyByKeywords('123456 is your OTP, do not share'), Category.otp);
    });

    test('falls back to other when nothing matches', () {
      expect(classifyByKeywords('just some random text'), Category.other);
    });
  });

  group('classify — validated IDs beat keywords', () {
    test('a validated card wins over receipt-ish words', () {
      final dets = [const Detection(DocType.card, '4111111111111111', '...')];
      expect(classify('grand total receipt', dets), Category.card);
    });

    test('Aadhaar outranks card when both are present', () {
      final dets = [
        const Detection(DocType.card, '4111111111111111', '...'),
        const Detection(DocType.aadhaar, '234567890123', '...'),
      ];
      expect(classify('', dets), Category.aadhaar);
    });
  });
}
