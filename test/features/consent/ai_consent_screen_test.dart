import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tamitu/core/config/app_constants.dart';
import 'package:tamitu/core/errors/app_failure.dart';
import 'package:tamitu/features/consent/application/consent_service.dart';
import 'package:tamitu/features/consent/presentation/ai_consent_screen.dart';
import 'package:tamitu/l10n/app_localizations.dart';

import '../../helpers.dart';

/// Opens EK-06 from a launcher page and records the popped result.
class _Launcher extends StatelessWidget {
  const _Launcher({required this.results, this.updated = false});

  final List<bool?> results;
  final bool updated;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () async {
          final r = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => AiConsentScreen(uid: 'u1', updated: updated),
            ),
          );
          results.add(r);
        },
        child: const Text('open'),
      ),
    ),
  );
}

Future<List<bool?>> openEk06(
  WidgetTester t,
  TestEnv env, {
  String locale = 'pl',
  Brightness brightness = Brightness.light,
  bool updated = false,
}) async {
  t.view.physicalSize = const Size(1080, 2400);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final results = <bool?>[];
  await t.pumpWidget(
    hostScreen(
      env,
      _Launcher(results: results, updated: updated),
      locale: locale,
      brightness: brightness,
    ),
  );
  await t.tap(find.text('open'));
  await t.pumpAndSettle();
  return results;
}

AppLocalizations l10nOf(WidgetTester t) =>
    AppLocalizations.of(t.element(find.byType(AiConsentScreen)))!;

Finder agree() => find.byKey(const Key('aiConsentAgree'));
Finder disagree() => find.byKey(const Key('aiConsentDisagree'));

Future<void> tapKey(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  for (final lang in languages) {
    for (final b in brightnesses) {
      testWidgets('EK-06 content ($lang, ${b.name})', (t) async {
        await openEk06(t, TestEnv(), locale: lang, brightness: b);
        final l10n = l10nOf(t);
        for (final s in [
          l10n.aiConsentTitle,
          l10n.aiConsentIntro,
          l10n.aiConsentSendTitle,
          l10n.aiConsentSendList,
          l10n.aiConsentNotSendTitle,
          l10n.aiConsentNotSendList,
          l10n.aiConsentRecipientTitle,
          l10n.aiConsentRecipient,
          l10n.aiConsentErrors,
          l10n.aiConsentSensitive,
          l10n.aiConsentWithdraw,
          l10n.aiConsentController,
        ]) {
          expect(find.text(s), findsOneWidget, reason: s);
        }
        expect(
          find.byType(Checkbox),
          findsNothing,
          reason: 'decision by buttons only',
        );
        expect(find.byKey(const Key('aiConsentUpdated')), findsNothing);
        // Equal weight: both outlined, same width; fixed order agree -> disagree.
        expect(
          find.descendant(of: agree(), matching: find.byType(OutlinedButton)),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: disagree(),
            matching: find.byType(OutlinedButton),
          ),
          findsOneWidget,
        );
        expect(t.getSize(agree()).width, t.getSize(disagree()).width);
        expect(t.getTopLeft(agree()).dy, lessThan(t.getTopLeft(disagree()).dy));
        await expectLater(t, meetsGuideline(androidTapTargetGuideline));
        await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(t, meetsGuideline(textContrastGuideline));
      });
    }
  }

  testWidgets('I agree: saves ai-consent-v1 with the UI language, pops true', (
    t,
  ) async {
    final env = TestEnv();
    final results = await openEk06(t, env, locale: 'en');
    await tapKey(t, agree());
    expect(results, [true]);
    final r = env.api.stored.values.single.record;
    expect(r.type, ConsentType.aiProcessing);
    expect(r.granted, isTrue);
    expect(r.policyVersion, AppConstants.aiConsentVersion);
    expect(r.lang, 'en');
    expect(await env.consents.aiConsentState('u1'), AiConsentState.granted);
  });

  testWidgets('I don\'t agree: pops false, no record (U-5)', (t) async {
    final env = TestEnv();
    final results = await openEk06(t, env);
    await tapKey(t, disagree());
    expect(results, [false]);
    expect(env.api.calls, 0);
    expect(await env.local.all('u1'), isEmpty);
  });

  testWidgets('back arrow = disagree, no record', (t) async {
    final env = TestEnv();
    final results = await openEk06(t, env);
    await t.tap(find.byType(BackButton));
    await t.pumpAndSettle();
    expect(results, [false]);
    expect(env.api.calls, 0);
  });

  testWidgets('offline: notice, nothing stored, can still go back', (t) async {
    final env = TestEnv();
    env.api.failures.add(const AppFailure(FailureKind.offline));
    final results = await openEk06(t, env);
    await tapKey(t, agree());
    expect(find.byKey(const Key('aiConsentOffline')), findsOneWidget);
    expect(results, isEmpty);
    expect(await env.local.all('u1'), isEmpty);
    await tapKey(t, disagree());
    expect(results, [false]);
  });

  testWidgets('save error: error notice says nothing was sent', (t) async {
    final env = TestEnv();
    env.api.failures.add(const AppFailure(FailureKind.generic));
    await openEk06(t, env, locale: 'en');
    await tapKey(t, agree());
    expect(
      find.text(
        "Couldn't save your consent. Nothing was sent. Please try again.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('loading: agree busy, disagree disabled', (t) async {
    final env = TestEnv();
    env.api.gate = Completer<void>();
    final results = await openEk06(t, env);
    await t.ensureVisible(agree());
    await t.tap(agree());
    await t.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      t
          .widget<OutlinedButton>(
            find.descendant(
              of: disagree(),
              matching: find.byType(OutlinedButton),
            ),
          )
          .onPressed,
      isNull,
    );
    env.api.gate!.complete();
    await t.pumpAndSettle();
    expect(results, [true]);
  });

  testWidgets('updated variant shows the intro (consent_required)', (t) async {
    await openEk06(t, TestEnv(), updated: true);
    expect(find.byKey(const Key('aiConsentUpdated')), findsOneWidget);
    expect(find.text(l10nOf(t).aiConsentUpdatedIntro), findsOneWidget);
  });

  testWidgets('policy link opens the policy in the UI language', (t) async {
    final env = TestEnv();
    await openEk06(t, env, locale: 'en');
    final handle = t.ensureSemantics();
    final link = find.bySemanticsLabel(
      RegExp(r'^Details in the Privacy Policy\., opens in browser'),
    );
    expect(link, findsOneWidget);
    handle.dispose();
    await t.ensureVisible(
      find.textContaining('Details in the', findRichText: true),
    );
    await t.tapOnText(find.textRange.ofSubstring('Privacy Policy'));
    expect(env.opened, [AppConstants.privacyPolicyUrls['en']]);
  });
}
