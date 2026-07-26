import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picsearch/src/models.dart';
import 'package:picsearch/src/validators.dart';
import 'package:picsearch/theme.dart';
import 'package:picsearch/ui/ui_helpers.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: buildTheme(Brightness.dark),
      home: Scaffold(body: child),
    );

const _card = ExtractedField(
  type: DocType.card,
  label: 'Card number',
  value: '4539148803436467',
  masked: '••••••••••••6467',
  sensitive: true,
);

void main() {
  testWidgets('reveals the full value once the gate approves', (tester) async {
    await tester.pumpWidget(
        _wrap(MaskedField(field: _card, confirmReveal: (_) async => true)));

    expect(find.text('••••••••••••6467'), findsOneWidget);
    expect(find.text('4539148803436467'), findsNothing);

    await tester.tap(find.byIcon(Icons.lock_outline));
    await tester.pumpAndSettle();
    expect(find.text('4539148803436467'), findsOneWidget);
  });

  testWidgets('stays masked when the gate denies (biometric fail)', (tester) async {
    await tester.pumpWidget(
        _wrap(MaskedField(field: _card, confirmReveal: (_) async => false)));

    await tester.tap(find.byIcon(Icons.lock_outline));
    await tester.pumpAndSettle();
    expect(find.text('4539148803436467'), findsNothing);
    expect(find.text('••••••••••••6467'), findsOneWidget);
  });

  testWidgets('public values have no reveal control', (tester) async {
    const ifsc = ExtractedField(
      type: DocType.ifsc,
      label: 'IFSC',
      value: 'HDFC0001234',
      masked: 'HDFC0001234',
      sensitive: false,
    );
    await tester.pumpWidget(_wrap(const MaskedField(field: ifsc)));
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    expect(find.text('HDFC0001234'), findsOneWidget);
  });
}
