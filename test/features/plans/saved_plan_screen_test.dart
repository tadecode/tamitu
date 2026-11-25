import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tamitu/app/home_screen.dart';
import 'package:tamitu/app/router.dart';
import 'package:tamitu/features/auth/domain/auth_gateway.dart';
import 'package:tamitu/features/plan_generation/presentation/plan_screen.dart';
import 'package:tamitu/features/plans/presentation/saved_plan_screen.dart';

import '../../helpers.dart';
import '../../home_screen_test.dart' show savePlan;

Future<TestEnv> _ready() async {
  final env = TestEnv(user: const AuthUser('u1'));
  await env.acceptCurrentPolicy('u1');
  return env;
}

Future<void> _openCard(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(Key('planCard-$id')));
  await tester.pumpAndSettle();
}

Future<void> _openDeleteDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('planMenu')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('planMenuDelete')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('planDeleteDialog')), findsOneWidget);
}

void main() {
  for (final locale in languages) {
    for (final brightness in brightnesses) {
      testWidgets(
        'card opens the saved plan (EK-08) ($locale, ${brightness.name})',
        (tester) async {
          final env = await _ready();
          final id = await savePlan(env, 'Lizbona', days: 3);
          await pumpApp(tester, env, locale: locale, brightness: brightness);
          await _openCard(tester, id);

          expect(find.byType(SavedPlanScreen), findsOneWidget);
          expect(find.byType(PlanScreen), findsOneWidget);
          expect(find.text('Lizbona'), findsOneWidget); // app bar title
          expect(find.byKey(const Key('planSummary')), findsOneWidget);
          expect(find.byKey(const Key('planDayTabs')), findsOneWidget);
          expect(find.byKey(const Key('planMenu')), findsOneWidget);
          // Opening a saved plan does not show the "saved" snackbar.
          expect(find.byKey(const Key('planSavedSnack')), findsNothing);

          // Back returns to EK-04.
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.byType(HomeScreen), findsOneWidget);
        },
      );
    }
  }

  testWidgets('a plan that cannot be read: CMP-18 with "Back to list"', (
    tester,
  ) async {
    final env = await _ready();
    final id = await savePlan(env, 'Lizbona');
    await pumpApp(tester, env);
    env.savedPlans.failLoad = 1;
    await _openCard(tester, id);
    expect(find.byKey(const Key('planBackToList')), findsOneWidget);
    expect(find.byKey(const Key('planMenu')), findsNothing);
    await tester.tap(find.byKey(const Key('planBackToList')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('route restored without extra reads the plan from the phone', (
    tester,
  ) async {
    final env = await _ready();
    final id = await savePlan(env, 'Porto');
    env.savedPlans.gate = Completer<void>();
    await pumpApp(tester, env, settle: false);
    env.savedPlans.gate!.complete();
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    env.savedPlans.gate = Completer<void>();
    router.go(Routes.savedPlan(id));
    await tester.pump();
    await tester.pump(savedPlanSkeletonDelay);
    expect(find.byKey(const Key('planLoading')), findsOneWidget);
    env.savedPlans.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Porto'), findsOneWidget);
    expect(find.byKey(const Key('planMenu')), findsOneWidget);
  });

  for (final locale in languages) {
    testWidgets('delete: confirm -> EK-04 with snackbar, plan gone ($locale)', (
      tester,
    ) async {
      final env = await _ready();
      final keep = await savePlan(env, 'Kraków');
      final id = await savePlan(env, 'Lizbona');
      await pumpApp(tester, env, locale: locale);
      await _openCard(tester, id);
      await _openDeleteDialog(tester);
      final en = locale == 'en';
      expect(
        find.text(en ? 'Delete this trip?' : 'Usunąć plan?'),
        findsOneWidget,
      );
      expect(
        find.text(
          en
              ? '“Lizbona” will be permanently deleted from this device. '
                    "This can't be undone."
              : 'Plan „Lizbona” zostanie trwale usunięty z tego urządzenia. '
                    'Tego nie da się cofnąć.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('planDeleteConfirm')));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(PlanScreen), findsNothing);
      expect(
        find.text(en ? 'Trip “Lizbona” deleted' : 'Plan „Lizbona” usunięty'),
        findsOneWidget,
      );
      expect(env.savedPlans.plansOf('u1').map((p) => p.id), [keep]);
      expect(find.byKey(Key('planCard-$id')), findsNothing);
      expect(find.byKey(Key('planCard-$keep')), findsOneWidget);
    });
  }

  testWidgets('deleting the last plan shows the empty state', (tester) async {
    final env = await _ready();
    final id = await savePlan(env, 'Lizbona');
    await pumpApp(tester, env);
    await _openCard(tester, id);
    await _openDeleteDialog(tester);
    await tester.tap(find.byKey(const Key('planDeleteConfirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('planListEmpty')), findsOneWidget);
    expect(find.text('Plan „Lizbona” usunięty'), findsOneWidget);
  });

  testWidgets('cancel keeps the plan and stays on EK-08', (tester) async {
    final env = await _ready();
    final id = await savePlan(env, 'Lizbona');
    await pumpApp(tester, env);
    await _openCard(tester, id);
    await _openDeleteDialog(tester);
    await tester.tap(find.byKey(const Key('planDeleteCancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('planDeleteDialog')), findsNothing);
    expect(find.byType(PlanScreen), findsOneWidget);
    expect(env.savedPlans.plansOf('u1'), hasLength(1));
  });

  testWidgets('loading: "Delete" busy, "Cancel" disabled, back blocked', (
    tester,
  ) async {
    final env = await _ready();
    final id = await savePlan(env, 'Lizbona');
    await pumpApp(tester, env);
    await _openCard(tester, id);
    await _openDeleteDialog(tester);
    env.savedPlans.gate = Completer<void>();
    await tester.tap(find.byKey(const Key('planDeleteConfirm')));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const Key('planDeleteConfirm')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextButton>(find.byKey(const Key('planDeleteCancel')))
          .onPressed,
      isNull,
    );
    // System back while deleting does not close the dialog.
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const Key('planDeleteDialog')), findsOneWidget);

    env.savedPlans.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(env.savedPlans.plansOf('u1'), isEmpty);
  });

  testWidgets('error: message, plan kept; "Try again" deletes', (tester) async {
    final env = await _ready();
    final id = await savePlan(env, 'Lizbona');
    await pumpApp(tester, env, locale: 'en');
    await _openCard(tester, id);
    await _openDeleteDialog(tester);
    env.savedPlans.failDelete = 1;
    await tester.tap(find.byKey(const Key('planDeleteConfirm')));
    await tester.pumpAndSettle();

    expect(
      find.text("Couldn't delete the trip. Nothing was changed."),
      findsOneWidget,
    );
    expect(find.byKey(const Key('planDeleteClose')), findsOneWidget);
    expect(env.savedPlans.plansOf('u1'), hasLength(1));

    await tester.tap(find.byKey(const Key('planDeleteRetry')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(env.savedPlans.plansOf('u1'), isEmpty);
  });

  testWidgets('error then "Close": back on EK-08, plan unchanged', (
    tester,
  ) async {
    final env = await _ready();
    final id = await savePlan(env, 'Lizbona');
    await pumpApp(tester, env);
    await _openCard(tester, id);
    await _openDeleteDialog(tester);
    env.savedPlans.failDelete = 1;
    await tester.tap(find.byKey(const Key('planDeleteConfirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('planDeleteClose')));
    await tester.pumpAndSettle();
    expect(find.byType(PlanScreen), findsOneWidget);
    expect(env.savedPlans.plansOf('u1'), hasLength(1));
  });
}
