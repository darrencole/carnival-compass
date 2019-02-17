// This is a basic Flutter widget test.
// To perform an interaction with a widget in your test, use the WidgetTester utility that Flutter
// provides. For example, you can send tap and scroll gestures. You can also use WidgetTester to
// find child widgets in the widget tree, read text, and verify that the values of widget properties
// are correct.

import 'package:carnival_compass_mobile/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return new MaterialApp(home: new CarnivalCompassHome());
    }));

    expect(find.text('Fetes'), findsOneWidget);
    expect(find.text('Bands'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.filter_list), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);

    await tester.tap(find.byIcon(Icons.local_shipping));
    await tester.pump();
    await tester.pump(Duration(seconds: 1));

    expect(find.text('Bands'), findsOneWidget);
    expect(find.text('Fetes'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.byIcon(Icons.filter_list), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });
}
