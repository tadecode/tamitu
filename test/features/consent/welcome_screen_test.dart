import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tamitu/app/home_screen.dart';
import 'package:tamitu/core/config/app_constants.dart';
import 'package:tamitu/core/errors/app_failure.dart';
import 'package:tamitu/features/consent/presentation/welcome_screen.dart';
import 'package:tamitu/l10n/app_localizations.dart';

import '../../helpers.dart';

AppLocalizations l10nOf(WidgetTester t) =>
    AppLocalizations.of(t.element(find.byType(WelcomeScreen)))!;

Finder signInButton() => find.byKey(const Key('welcomeSignIn'));

bool buttonEnabled(WidgetTester t) =>
    t
        .widget<FilledButton>(
          find.descendant(
            of: signInButton(),
            matching: find.byType(FilledButton),
          ),
        )
        .onPressed !=
    null;

Future<void> check(WidgetTester t) async {
  await t.tap(find.byType(Checkbox));
  await t.pumpAndSettle();
}

Future<void> tapSignIn(WidgetTester t) async {
  await t.ensureVisible(signInButton());
  await t.tap(signInButton());
  await t.pumpAndSettle();
}

void main() {
  for (final lang in languages) {
    for (final b in brightnesses) {
      testWidgets('EK-02 default state ($lang, ${b.name})', (t) async {
        final env = TestEnv();
        await pumpApp(t, env, locale: lang, brightness: b);
        final l10n = l10nOf(t);
        expect(find.byType(WelcomeScreen), findsOneWidget);
        expect(find.text(l10n.welcomeTagline), findsOneWidget);
        expect(find.text(l10n.welcomePrivacyTitle), findsOneWidget);
        expect(find.text(l10n.welcomeAdultsOnly), findsOneWidget);
        expect(find.text(l10n.welcomeSignIn), findsOneWidget);
        expect(find.text(l10n.welcomeSignInHint), findsOneWidget);
        expect(
          t.widget<Checkbox>(find.byType(Checkbox)).value,
          isFalse,
          reason: 'never pre-checked',
        );
        expect(buttonEnabled(t), isFalse);
        expect(find.byKey(const Key('welcomeHero')), findsOneWidget);
        final scheme = Theme.of(t.element(find.byType(WelcomeScreen)))
            .colorScheme;
        expect(scheme.brightness, b);
        expect(
          scheme.primary,
          b == Brightness.light
              ? const Color(0xFF006A6A)
              : const Color(0xFF80D5D4),
        );
        await expectLater(t, meetsGuideline(androidTapTargetGuideline));
        await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(t, meetsGuideline(textContrastGuideline));
      });
    }
  }

  testWidgets('unsupported device language falls back to English (ADR-0006)', (
    t,
  ) async {
    await pumpApp(t, TestEnv(), locale: 'de');
    expect(find.text('Sign in with Google'), findsOneWidget);
  });

  testWidgets(
    'checking enables sign-in; success goes to EK-04 and records the consent',
    (t) async {
      final env = TestEnv();
      await pumpApp(t, env, locale: 'en');
      await check(t);
      expect(buttonEnabled(t), isTrue);
      expect(find.text(l10nOf(t).welcomeSignInHint), findsNothing);
      await tapSignIn(t);
      expect(find.byType(HomeScreen), findsOneWidget);
      final stored = env.api.stored.values.single.record;
      expect(stored.type, ConsentType.privacyPolicy);
      expect(stored.lang, 'en');
      expect(stored.policyVersion, AppConstants.privacyPolicyVersion);
      expect(env.pending.value, isNull);
    },
  );

  testWidgets(
    'loading: button busy, checkbox and language disabled, one sign-in only',
    (t) async {
      final env = TestEnv();
      env.auth.signInGate = Completer<void>();
      await pumpApp(t, env);
      await check(t);
      await t.ensureVisible(signInButton());
      await t.tap(signInButton());
      await t.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(t.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
      expect(
        t
            .widget<SegmentedButton<String>>(
              find.byType(SegmentedButton<String>),
            )
            .onSelectionChanged,
        isNull,
      );
      expect(env.pending.value, isNotNull, reason: 'staged at the tap');
      await t.tap(signInButton(), warnIfMissed: false);
      expect(env.auth.signInCalls, 1);
      env.auth.signInGate!.complete();
      await t.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets(
    'cancelled at Google: snackbar, box stays checked, staged entry cleared',
    (t) async {
      final env = TestEnv();
      env.auth.nextSignInFailure = const AppFailure(FailureKind.cancelled);
      await pumpApp(t, env);
      await check(t);
      await tapSignIn(t);
      expect(find.text(l10nOf(t).welcomeSignInCancelled), findsOneWidget);
      expect(t.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      expect(env.pending.value, isNull);
      expect(buttonEnabled(t), isTrue);
    },
  );

  testWidgets(
    'offline after a failed attempt: warning notice, retry possible',
    (t) async {
      final env = TestEnv();
      env.auth.nextSignInFailure = const AppFailure(FailureKind.offline);
      await pumpApp(t, env);
      await check(t);
      await tapSignIn(t);
      expect(find.byKey(const Key('welcomeOffline')), findsOneWidget);
      expect(find.text(l10nOf(t).commonOfflineNotice), findsOneWidget);
      expect(env.pending.value, isNull);
      await tapSignIn(t);
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets('BUG-5: the notice sits directly above the sign-in button', (
    t,
  ) async {
    final env = TestEnv();
    env.auth.nextSignInFailure = const AppFailure(FailureKind.offline);
    await pumpApp(t, env);
    await check(t);
    await tapSignIn(t);
    final notice = t.getRect(find.byKey(const Key('welcomeOffline')));
    final checkbox = t.getRect(find.byType(Checkbox));
    final button = t.getRect(signInButton());
    expect(notice.top, greaterThan(checkbox.bottom));
    expect(notice.bottom, lessThanOrEqualTo(button.top));
  });

  testWidgets('other error: error notice without technical details', (t) async {
    final env = TestEnv();
    env.auth.nextSignInFailure = const AppFailure(FailureKind.generic);
    await pumpApp(t, env, locale: 'en');
    await check(t);
    await tapSignIn(t);
    expect(find.byKey(const Key('welcomeError')), findsOneWidget);
    expect(find.text("Couldn't sign in. Please try again."), findsOneWidget);
  });

  testWidgets(
    'switching language changes texts and clears the acceptance (P-3)',
    (t) async {
      final env = TestEnv();
      await pumpApp(t, env, locale: 'pl');
      await check(t);
      expect(find.text('Zaloguj przez Google'), findsOneWidget);
      await t.tap(find.text('EN'));
      await t.pumpAndSettle();
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(t.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      expect(buttonEnabled(t), isFalse);
      expect(env.savedLanguages, ['en']);
    },
  );

  testWidgets(
    'policy link opens the policy in the UI language and does not toggle',
    (t) async {
      final env = TestEnv();
      await pumpApp(t, env, locale: 'en');
      await t.ensureVisible(find.text('Read the Privacy Policy'));
      await t.pumpAndSettle();
      await t.tap(find.text('Read the Privacy Policy'));
      await t.pumpAndSettle();
      expect(env.opened, [AppConstants.privacyPolicyUrls['en']]);
      expect(t.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    },
  );

  testWidgets(
    'TalkBack: checkbox label = visible text; disabled button reads the reason',
    (t) async {
      final handle = t.ensureSemantics();
      await pumpApp(t, TestEnv(), locale: 'pl');
      expect(
        find.bySemanticsLabel(
          RegExp(
            '^Potwierdzam zapoznanie się z polityką prywatności i akceptuję ją',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Zaloguj przez Google. Zaznacz akceptację polityki, aby się zalogować.',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp('^Przeczytaj politykę prywatności, otwiera przeglądarkę'),
        ),
        findsOneWidget,
      );
      handle.dispose();
    },
  );

  testWidgets(
    '200 % text: illustration hidden, everything reachable by scrolling',
    (t) async {
      await pumpApp(t, TestEnv(), textScale: 2);
      expect(find.byKey(const Key('welcomeHero')), findsNothing);
      await t.ensureVisible(signInButton());
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('150 % text: illustration 96 dp', (t) async {
    await pumpApp(t, TestEnv(), textScale: 1.5);
    expect(t.getSize(find.byKey(const Key('welcomeHero'))).height, 96);
  });
}
