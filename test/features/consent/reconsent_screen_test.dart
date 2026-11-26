import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tamitu/app/home_screen.dart';
import 'package:tamitu/core/config/app_constants.dart';
import 'package:tamitu/core/errors/app_failure.dart';
import 'package:tamitu/features/auth/domain/auth_gateway.dart';
import 'package:tamitu/features/consent/presentation/reconsent_screen.dart';
import 'package:tamitu/features/consent/presentation/welcome_screen.dart';
import 'package:tamitu/l10n/app_localizations.dart';

import '../../helpers.dart';

AppLocalizations l10nOf(WidgetTester t) =>
    AppLocalizations.of(t.element(find.byType(ReconsentScreen)))!;

Finder acceptButton() => find.byKey(const Key('reconsentAccept'));

bool acceptEnabled(WidgetTester t) =>
    t
        .widget<FilledButton>(
          find.descendant(
            of: acceptButton(),
            matching: find.byType(FilledButton),
          ),
        )
        .onPressed !=
    null;

Future<void> checkAndAccept(WidgetTester t) async {
  await t.tap(find.byType(Checkbox));
  await t.pumpAndSettle();
  await t.ensureVisible(acceptButton());
  await t.tap(acceptButton());
  await t.pumpAndSettle();
}

/// Signed in, no local acceptance of the app's policy -> EK-03.
TestEnv signedInWithoutAcceptance() => TestEnv(user: const AuthUser('u1'));

void main() {
  for (final lang in languages) {
    for (final b in brightnesses) {
      testWidgets('EK-03 default state ($lang, ${b.name})', (t) async {
        await pumpApp(
          t,
          signedInWithoutAcceptance(),
          locale: lang,
          brightness: b,
        );
        final l10n = l10nOf(t);
        expect(find.text(l10n.reconsentTitle), findsOneWidget);
        expect(find.text(l10n.reconsentBody), findsOneWidget);
        expect(find.text(l10n.reconsentLink), findsOneWidget);
        expect(find.text(l10n.reconsentSignOut), findsOneWidget);
        expect(
          find.text(l10n.reconsentDeleteAccount),
          findsNothing,
          reason: 'P3-08',
        );
        expect(
          find.byType(BackButton),
          findsNothing,
          reason: 'blocking, no back arrow',
        );
        expect(t.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
        expect(acceptEnabled(t), isFalse);
        await expectLater(t, meetsGuideline(androidTapTargetGuideline));
        await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(t, meetsGuideline(textContrastGuideline));
      });
    }
  }

  testWidgets('accept saves the acceptance on the server, then EK-04', (
    t,
  ) async {
    final env = signedInWithoutAcceptance();
    await pumpApp(t, env, locale: 'en');
    await checkAndAccept(t);
    expect(find.byType(HomeScreen), findsOneWidget);
    final r = env.api.stored.values.single.record;
    expect(r.policyVersion, AppConstants.privacyPolicyVersion);
    expect(r.lang, 'en');
  });

  testWidgets(
    'offline: notice, not let through; retry uses the same consentId',
    (t) async {
      final env = signedInWithoutAcceptance();
      env.api.failures.add(const AppFailure(FailureKind.offline));
      await pumpApp(t, env);
      await checkAndAccept(t);
      expect(find.byKey(const Key('reconsentOffline')), findsOneWidget);
      expect(find.text(l10nOf(t).reconsentOffline), findsOneWidget);
      expect(find.byType(ReconsentScreen), findsOneWidget);
      expect(await env.local.all('u1'), isEmpty);
      await t.tap(acceptButton());
      await t.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(env.api.stored.length, 1);
    },
  );

  testWidgets('save error: error notice, stays on EK-03', (t) async {
    final env = signedInWithoutAcceptance();
    env.api.failures.add(const AppFailure(FailureKind.generic));
    await pumpApp(t, env, locale: 'en');
    await checkAndAccept(t);
    expect(
      find.text("Couldn't save your acceptance. Please try again."),
      findsOneWidget,
    );
    expect(find.byType(ReconsentScreen), findsOneWidget);
  });

  testWidgets('session expired: back to EK-02 with a snackbar', (t) async {
    final env = signedInWithoutAcceptance();
    env.api.failures.add(const AppFailure(FailureKind.unauthenticated));
    await pumpApp(t, env, locale: 'en');
    await checkAndAccept(t);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(
      find.text(
        'Your session has expired. Sign in again – your trips are on this device.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('sign out from EK-03 -> EK-02', (t) async {
    final env = signedInWithoutAcceptance();
    await pumpApp(t, env);
    await t.ensureVisible(find.text('Wyloguj'));
    await t.tap(find.text('Wyloguj'));
    await t.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(env.auth.signOutCalls, 1);
  });

  testWidgets(
    'BUG-4: unsupported_version -> "Update the app" (Play), sign-out stays',
    (t) async {
      final env = signedInWithoutAcceptance();
      env.api.failures.add(const AppFailure(FailureKind.unsupportedVersion));
      await pumpApp(t, env, locale: 'en');
      await checkAndAccept(t);
      expect(find.byKey(const Key('updateApp')), findsOneWidget);
      expect(find.text('Update the app'), findsOneWidget);
      expect(
        find.text("Couldn't save your acceptance. Please try again."),
        findsNothing,
      );
      await t.tap(find.text('Update app'));
      await t.pumpAndSettle();
      expect(env.opened, [AppConstants.playStoreUrl]);
      expect(find.text('Sign out'), findsOneWidget);
    },
  );

  testWidgets('data reset variant text', (t) async {
    final env = TestEnv();
    await t.pumpWidget(
      hostScreen(env, const ReconsentScreen(uid: 'u1', dataReset: true)),
    );
    await t.pumpAndSettle();
    expect(
      find.textContaining('Dane na tym urządzeniu zostały wyczyszczone'),
      findsOneWidget,
    );
  });

  testWidgets('TAM-111: TalkBack can open the policy link and press accept', (
    t,
  ) async {
    final env = signedInWithoutAcceptance();
    await pumpApp(t, env, locale: 'en');
    final handle = t.ensureSemantics();
    final link = find.bySemanticsLabel(RegExp(r', opens in browser$'));
    // EK-03 link above the consent row (the row has no separate link button here).
    expect(link, findsOneWidget);
    expect(hasSemanticsTap(t, link), isTrue);
    semanticsTap(t, link);
    await t.pumpAndSettle();
    expect(env.opened, [AppConstants.privacyPolicyUrls['en']]);
    expect(hasSemanticsTap(t, acceptButton()), isFalse);
    await t.tap(find.byType(Checkbox));
    await t.pumpAndSettle();
    expect(hasSemanticsTap(t, acceptButton()), isTrue);
    handle.dispose();
  });
}
