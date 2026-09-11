// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keyboard/main.dart';

void main() {
  testWidgets('keyboard keeps letter input while adding accessories', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KeyboardApp());

    expect(find.text('Start typing'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Clipboard'), findsOneWidget);

    await tester.tap(find.text('1'));
    await tester.tap(find.text('q'));
    await tester.pump();

    expect(find.text('1q'), findsOneWidget);

    await tester.tap(find.byKey(const Key('clipboard-Thank you!')));
    await tester.pump();
    expect(find.text('1qThank you!'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Backspace'));
    await tester.pump();
    expect(find.text('1qThank you'), findsOneWidget);
  });
}
