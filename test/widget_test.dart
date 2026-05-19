// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:umusaruro_p2p/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: UmusaruroApp()));

    // Wait for animations to finish
    await tester.pumpAndSettle();

    // Verify that the app is built by finding a MaterialApp or the main app widget
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
