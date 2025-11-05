// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:educonnect_test/main.dart';

void main() {
  testWidgets('EduConnect app smoke test', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(EduConnectApp(isDark: false, prefs: prefs));

    // Verify that the login page title is displayed.
    expect(find.text('EduConnect Egypt'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
