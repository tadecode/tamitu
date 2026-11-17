import 'package:flutter_test/flutter_test.dart';
import 'package:tamitu/app/home_screen.dart';
import 'package:tamitu/features/auth/domain/auth_gateway.dart';

import 'helpers.dart';

Future<TestEnv> _ready() async {
  final env = TestEnv(user: const AuthUser('u1'));
  await env.acceptCurrentPolicy('u1');
  return env;
}

void main() {
  testWidgets('restored session with accepted policy opens home (PL)', (
    tester,
  ) async {
    await pumpApp(tester, await _ready(), locale: 'pl');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Planer podróży'), findsOneWidget);
  });

  testWidgets('home in English', (tester) async {
    await pumpApp(tester, await _ready(), locale: 'en');
    expect(find.text('Travel planner'), findsOneWidget);
  });

  testWidgets('unsupported device language falls back to English (ADR-0006)', (
    tester,
  ) async {
    await pumpApp(tester, await _ready(), locale: 'de');
    expect(find.text('Travel planner'), findsOneWidget);
  });
}
