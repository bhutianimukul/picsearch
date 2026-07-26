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

void main() {
  testWidgets('MaskedField hides a sensitive value and reveals it on tap',
      (tester) async {
    const field = ExtractedField(
      type: DocType.card,
      label: 'Card number',
      value: '4539148803436467',
      masked: '••••••••••••6467',
      sensitive: true,
    );
    await tester.pumpWidget(_wrap(const MaskedField(field: field)));

    expect(find.text('••••••••••••6467'), findsOneWidget);
    expect(find.text('4539148803436467'), findsNothing);

    await tester.tap(find.byIcon(Icons.lock_outline));
    await tester.pump();
    expect(find.text('4539148803436467'), findsOneWidget);
  });

  testWidgets('MaskedField adds no reveal control for public values',
      (tester) async {
    const field = ExtractedField(
      type: DocType.ifsc,
      label: 'IFSC',
      value: 'HDFC0001234',
      masked: 'HDFC0001234',
      sensitive: false,
    );
    await tester.pumpWidget(_wrap(const MaskedField(field: field)));
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    expect(find.text('HDFC0001234'), findsOneWidget);
  });
}
