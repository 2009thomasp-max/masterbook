import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_app_one/main.dart';

void main() {
  testWidgets('BookApp master reader smoke test', (WidgetTester tester) async {
    // Build our master reader app and trigger a frame.
    await tester.pumpWidget(const BookApp());

    // Verify that our reader app loads properly.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}