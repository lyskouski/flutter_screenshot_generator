// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_screenshot_generator/flutter_screenshot_generator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:test/main.dart';

void main() {
  final gen = ScreenshotGenerator(
    locales: [Locale('en', 'US'), Locale('de', 'DE')],
    fnGetApp: () => const MyApp(),
  );
  gen.inject('1_home');
  gen.inject('2_tap', before: (tester) async {
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
  });
  gen.run();
}
