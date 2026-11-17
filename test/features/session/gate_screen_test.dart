import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tamitu/app/home_screen.dart';
import 'package:tamitu/features/auth/domain/auth_gateway.dart';
import 'package:tamitu/features/consent/presentation/reconsent_screen.dart';

import '../../helpers.dart';

void main() {
  testWidgets(
    'database cannot be opened (not a lost key): error with retry, then EK-04',
    (t) async {
      final env = TestEnv(user: const AuthUser('u1'));
      await env.acceptCurrentPolicy('u1');
      env.local.failNextReads = 1;
      await pumpApp(t, env, locale: 'en');
      expect(find.byKey(const Key('gateRetry')), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      await t.tap(find.byKey(const Key('gateRetry')));
      await t.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets('lost key -> EK-03 data-reset variant', (t) async {
    final env = TestEnv(user: const AuthUser('u1'));
    env.local.resetFor.add('u1');
    await pumpApp(t, env);
    expect(find.byType(ReconsentScreen), findsOneWidget);
    expect(
      find.textContaining('Dane na tym urządzeniu zostały wyczyszczone'),
      findsOneWidget,
    );
  });
}
