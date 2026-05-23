// Basic Flutter widget smoke test for Flood Guard AI.

import 'package:flutter_test/flutter_test.dart';

import 'package:myapp/main.dart';

void main() {
  testWidgets('Welcome screen shows brand and CTA', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Flood Guard AI'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
