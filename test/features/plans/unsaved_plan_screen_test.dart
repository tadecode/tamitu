import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tamitu/app/home_screen.dart';
import 'package:tamitu/app/router.dart';
import 'package:tamitu/features/auth/domain/auth_gateway.dart';
import 'package:tamitu/features/plan_generation/data/fake_plan_api.dart';
import 'package:tamitu/features/plan_generation/domain/generated_plan.dart';
import 'package:tamitu/features/plan_generation/presentation/plan_screen.dart';
import 'package:tamitu/features/plans/domain/saved_plan.dart';
import 'package:tamitu/features/plans/presentation/unsaved_plan_screen.dart';

import '../../helpers.dart';
import '../../home_screen_test.dart' show trip;

/// EK-08 v0.2 "Plan nie jest zapisany" (TAM-104 design, TAM-113).

const _texts = {
  'pl': (
    title: 'Plan nie jest zapisany',
    body:
        'Nie udało się zapisać planu w telefonie. Jeśli wyjdziesz z tego ekranu '
        'albo zamkniesz aplikację, plan zniknie.',
    storage:
        'W telefonie brakuje miejsca, więc plan się nie zapisał. Zwolnij trochę '
        'miejsca i spróbuj ponownie. Jeśli wyjdziesz z tego ekranu albo zamkniesz '
        'aplikację, plan zniknie.',
    retry: 'Spróbuj zapisać ponownie',
    saving: 'Zapisywanie…',
    failedAgain: 'Nadal nie udało się zapisać planu.',
    saved: 'Plan zapisany. Dziś możesz utworzyć jeszcze 3 z 5.',
    leaveTitle: 'Wyjść bez zapisania planu?',
    leaveBody:
        'Plan zniknie i nie da się go odzyskać. To generowanie jest już wliczone '
        'do dzisiejszego limitu.',
    cancel: 'Anuluj',
    leave: 'Wyjdź bez zapisu',
  ),
  'en': (
    title: "This trip isn't saved",
    body:
        "We couldn't save this trip on your phone. If you leave this screen or "
        'close the app, the trip will be lost.',
    storage:
        "Your phone is out of storage, so the trip wasn't saved. Free up some "
        'space and try again. If you leave this screen or close the app, the '
        'trip will be lost.',
    retry: 'Try saving again',
    saving: 'Saving…',
    failedAgain: "The trip still couldn't be saved.",
    saved: 'Plan saved. You can create 3 more of 5 today.',
    leaveTitle: 'Leave without saving?',
    leaveBody:
        "The trip will be lost and can't be recovered. This generation already "
        "counts towards today's limit.",
    cancel: 'Cancel',
    leave: 'Leave without saving',
  ),
};

const _notice = Key('planNotSavedNotice');
const _retry = Key('planSaveRetry');
const _dialog = Key('planLeaveUnsavedDialog');
const _cancel = Key('planLeaveUnsavedCancel');
const _confirm = Key('planLeaveUnsavedConfirm');

Future<TestEnv> _ready() async {
  final env = TestEnv(user: const AuthUser('u1'));
  await env.acceptCurrentPolicy('u1');
  return env;
}

UnsavedPlan _unsaved(PlanStorageFailure failure, {String language = 'pl'}) {
  final input = trip('Lizbona', days: 3);
  final sample = FakePlanApi.samplePlan(input, requestId: 'r1');
  return UnsavedPlan(
    data: PlanViewData(
      input: input,
      plan: GeneratedPlan(
        requestId: sample.requestId,
        language: language,
        days: sample.days,
        quota: PlanQuota(
          limit: 5,
          remainingToday: 3,
          resetAt: DateTime.utc(2026, 11, 27),
        ),
      ),
    ),
    failure: failure,
  );
}

/// EK-04, then EK-08 in the "not saved" state as EK-07 opens it (`go` replaces EK-07).
Future<void> _open(
  WidgetTester tester,
  TestEnv env,
  PlanStorageFailure failure, {
  String locale = 'pl',
  Brightness brightness = Brightness.light,
}) async {
  await pumpApp(tester, env, locale: locale, brightness: brightness);
  GoRouter.of(tester.element(find.byType(HomeScreen)))
      .go(Routes.plan, extra: _unsaved(failure));
  await tester.pumpAndSettle();
  expect(find.byType(UnsavedPlanScreen), findsOneWidget);
}

Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

/// Label of the warning node (title + text as one element, EK-08 "Dostępność").
String _noticeLabel(WidgetTester tester, String title) =>
    tester.getSemantics(find.text(title)).label;

void main() {
  for (final locale in languages) {
    final t = _texts[locale]!;
    for (final brightness in brightnesses) {
      testWidgets('other error: warning above the plan, plan works, no menu '
          '($locale, ${brightness.name})', (tester) async {
        final env = await _ready();
        await _open(
          tester,
          env,
          PlanStorageFailure.other,
          locale: locale,
          brightness: brightness,
        );
        expect(find.byKey(_notice), findsOneWidget);
        expect(find.text(t.title), findsOneWidget);
        expect(find.text(t.body), findsOneWidget);
        expect(find.text(t.storage), findsNothing);
        expect(find.text(t.retry), findsOneWidget);
        // CMP-13 "Błąd": errorContainer, above the AI notice.
        final scheme = Theme.of(tester.element(find.byKey(_notice)))
            .colorScheme;
        final card = tester.widget<Card>(
          find.descendant(of: find.byKey(_notice), matching: find.byType(Card)),
        );
        expect(card.color, scheme.errorContainer);
        expect(
          tester.getTopLeft(find.byKey(_notice)).dy,
          lessThan(tester.getTopLeft(find.byKey(const Key('planAiNotice'))).dy),
        );
        // No delete menu, no "saved" snackbar.
        expect(find.byKey(const Key('planMenu')), findsNothing);
        expect(find.byKey(const Key('planSavedSnack')), findsNothing);
        // The plan works: day tabs and "Directions" (EK-09) without the dialog.
        expect(find.byKey(const Key('planDayTabs')), findsOneWidget);
        await tester.tap(find.text(locale == 'en' ? 'Day 2' : 'Dzień 2'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const Key('planItemRoute')).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('planItemRoute')).first);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('routeTitle')), findsOneWidget);
        expect(find.byKey(_dialog), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('out of storage: the storage text ($locale)', (tester) async {
      final env = await _ready();
      await _open(tester, env, PlanStorageFailure.noSpace, locale: locale);
      expect(find.text(t.title), findsOneWidget);
      expect(find.text(t.storage), findsOneWidget);
      expect(find.text(t.body), findsNothing);
    });

    testWidgets('retry succeeds: regular EK-08, menu, snackbar ($locale)', (
      tester,
    ) async {
      final env = await _ready();
      await _open(tester, env, PlanStorageFailure.noSpace, locale: locale);
      env.savedPlans.gate = Completer<void>();
      await tester.tap(find.byKey(_retry));
      await tester.pump();

      // CMP-02 loading: indicator + "Saving…", disabled.
      expect(find.text(t.saving), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(_retry),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(tester.widget<TextButton>(find.byKey(_retry)).onPressed, isNull);

      env.savedPlans.gate!.complete();
      env.savedPlans.gate = null;
      await tester.pumpAndSettle();
      final saved = env.savedPlans.plansOf('u1').single;
      expect(saved.input.destination, 'Lizbona');
      expect(find.byKey(_notice), findsNothing);
      expect(find.byKey(const Key('planMenu')), findsOneWidget);
      expect(find.text(t.saved), findsOneWidget);
      expect(find.byKey(const Key('planAiNotice')), findsOneWidget);

      // From now on back leaves without the dialog; the plan is on EK-04.
      await _back(tester);
      expect(find.byKey(_dialog), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byKey(Key('planCard-${saved.id}')), findsOneWidget);
    });

    testWidgets('retry fails: state unchanged, snackbar, text by cause '
        '($locale)', (tester) async {
      final env = await _ready();
      await _open(tester, env, PlanStorageFailure.other, locale: locale);
      env.savedPlans
        ..failSave = 1
        ..saveFailure = PlanStorageFailure.noSpace;
      await tester.tap(find.byKey(_retry));
      await tester.pumpAndSettle();
      expect(find.text(t.failedAgain), findsOneWidget);
      expect(find.byKey(_notice), findsOneWidget);
      // The cause changed: the notice now gives the storage advice.
      expect(find.text(t.storage), findsOneWidget);
      expect(find.text(t.body), findsNothing);
      expect(find.text(t.retry), findsOneWidget);
      expect(find.byKey(const Key('planMenu')), findsNothing);
      expect(find.byKey(const Key('planSavedSnack')), findsNothing);
      expect(env.savedPlans.plansOf('u1'), isEmpty);
      // The button is back and can be tried again (no limit).
      expect(
        tester.widget<TextButton>(find.byKey(_retry)).onPressed,
        isNotNull,
      );
    });

    testWidgets('back: dialog, Cancel stays, Leave goes to EK-04 ($locale)', (
      tester,
    ) async {
      final env = await _ready();
      await _open(tester, env, PlanStorageFailure.other, locale: locale);

      await _back(tester);
      expect(find.byKey(_dialog), findsOneWidget);
      expect(find.text(t.leaveTitle), findsOneWidget);
      expect(find.text(t.leaveBody), findsOneWidget);
      expect(find.text(t.cancel), findsOneWidget);
      expect(find.text(t.leave), findsOneWidget);
      // Destructive: confirm in `error`.
      final scheme = Theme.of(tester.element(find.byKey(_dialog))).colorScheme;
      final confirm = tester.widget<TextButton>(find.byKey(_confirm));
      expect(
        confirm.style!.foregroundColor!.resolve(<WidgetState>{}),
        scheme.error,
      );

      await tester.tap(find.byKey(_cancel));
      await tester.pumpAndSettle();
      expect(find.byKey(_dialog), findsNothing);
      expect(find.byType(UnsavedPlanScreen), findsOneWidget);

      // Back inside the dialog = Cancel.
      await _back(tester);
      expect(find.byKey(_dialog), findsOneWidget);
      await _back(tester);
      expect(find.byKey(_dialog), findsNothing);
      expect(find.byType(UnsavedPlanScreen), findsOneWidget);

      // The app bar arrow asks too; "Leave without saving" -> EK-04, plan lost.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byKey(_dialog), findsOneWidget);
      await tester.tap(find.byKey(_confirm));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(UnsavedPlanScreen), findsNothing);
      expect(env.savedPlans.plansOf('u1'), isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });
  }

  testWidgets('tapping outside the dialog keeps the plan', (tester) async {
    final env = await _ready();
    await _open(tester, env, PlanStorageFailure.other);
    await _back(tester);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byKey(_dialog), findsNothing);
    expect(find.byType(UnsavedPlanScreen), findsOneWidget);
  });

  testWidgets('back while saving waits for the result: saved -> EK-04', (
    tester,
  ) async {
    final env = await _ready();
    await _open(tester, env, PlanStorageFailure.other);
    env.savedPlans.gate = Completer<void>();
    await tester.tap(find.byKey(_retry));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(_dialog), findsNothing);
    env.savedPlans.gate!.complete();
    env.savedPlans.gate = null;
    await tester.pumpAndSettle();
    expect(find.byKey(_dialog), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(env.savedPlans.plansOf('u1'), hasLength(1));
  });

  testWidgets('back while saving waits for the result: failed -> dialog', (
    tester,
  ) async {
    final env = await _ready();
    await _open(tester, env, PlanStorageFailure.other);
    env.savedPlans
      ..gate = Completer<void>()
      ..failSave = 1;
    await tester.tap(find.byKey(_retry));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(_dialog), findsNothing);
    env.savedPlans.gate!.complete();
    env.savedPlans.gate = null;
    await tester.pumpAndSettle();
    expect(find.byKey(_dialog), findsOneWidget);
  });

  testWidgets('route without the plan shows CMP-18 "Back to list"', (
    tester,
  ) async {
    final env = await _ready();
    await pumpApp(tester, env);
    GoRouter.of(tester.element(find.byType(HomeScreen))).go(Routes.plan);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('planBackToList')), findsOneWidget);
  });

  group('TalkBack', () {
    testWidgets('warning is one live-region element before the retry button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final env = await _ready();
      await _open(tester, env, PlanStorageFailure.noSpace);
      final t = _texts['pl']!;
      final notice = tester.getSemantics(find.text(t.title));
      expect(notice.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      expect(_noticeLabel(tester, t.title), contains(t.title));
      expect(_noticeLabel(tester, t.title), contains(t.storage));
      // The button is its own node with a tap action and a 48 dp target.
      final button = tester.getSemantics(find.byKey(_retry));
      expect(button.label, t.retry);
      expect(button.rect.height, greaterThanOrEqualTo(48));
      expect(hasSemanticsTap(tester, find.byKey(_retry)), isTrue);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('retry via the semantics tap; while saving no tap action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final env = await _ready();
      await _open(tester, env, PlanStorageFailure.other);
      env.savedPlans.gate = Completer<void>();
      semanticsTap(tester, find.byKey(_retry));
      await tester.pump();
      final busy = tester.getSemantics(find.byKey(_retry));
      expect(busy.label, 'Zapisywanie…');
      expect(hasSemanticsTap(tester, find.byKey(_retry)), isFalse);
      expect(
        busy.getSemanticsData().flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      env.savedPlans.gate!.complete();
      env.savedPlans.gate = null;
      await tester.pumpAndSettle();
      expect(env.savedPlans.plansOf('u1'), hasLength(1));
      expect(find.byKey(_notice), findsNothing);
      handle.dispose();
    });

    testWidgets('dialog buttons have tap actions; Leave works via semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final env = await _ready();
      await _open(tester, env, PlanStorageFailure.other);
      await _back(tester);
      expect(hasSemanticsTap(tester, find.byKey(_cancel)), isTrue);
      expect(hasSemanticsTap(tester, find.byKey(_confirm)), isTrue);
      semanticsTap(tester, find.byKey(_confirm));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      handle.dispose();
    });
  });

  testWidgets('200% text: the warning wraps, no overflow', (tester) async {
    final env = await _ready();
    await pumpApp(tester, env, textScale: 2);
    GoRouter.of(tester.element(find.byType(HomeScreen)))
        .go(Routes.plan, extra: _unsaved(PlanStorageFailure.noSpace));
    await tester.pumpAndSettle();
    expect(find.byKey(_notice), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
