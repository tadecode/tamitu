import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tamitu/app/app.dart';

Future<void> _pumpWithLocale(WidgetTester tester, String code) async {
  tester.platformDispatcher.localesTestValue = [Locale(code)];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(const TamituApp());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows Polish title for Polish locale', (tester) async {
    await _pumpWithLocale(tester, 'pl');
    expect(find.text('Planer podróży'), findsOneWidget);
  });

  testWidgets('shows English title for English locale', (tester) async {
    await _pumpWithLocale(tester, 'en');
    expect(find.text('Travel planner'), findsOneWidget);
  });

  testWidgets('falls back to Polish for unsupported locale', (tester) async {
    await _pumpWithLocale(tester, 'de');
    expect(find.text('Planer podróży'), findsOneWidget);
  });
}
