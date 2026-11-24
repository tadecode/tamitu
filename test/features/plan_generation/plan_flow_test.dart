import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tamitu/core/config/app_constants.dart';
import 'package:tamitu/core/errors/app_failure.dart';
import 'package:tamitu/core/ui/update_app_view.dart';
import 'package:tamitu/features/auth/domain/auth_gateway.dart';
import 'package:tamitu/features/consent/domain/consent_record.dart';
import 'package:tamitu/features/consent/presentation/ai_consent_screen.dart';
import 'package:tamitu/features/consent/presentation/welcome_screen.dart';
import 'package:tamitu/features/generation/presentation/ai_busy_view.dart';
import 'package:tamitu/features/plan_generation/domain/generated_plan.dart';
import 'package:tamitu/features/plan_generation/domain/trip_input.dart';
import 'package:tamitu/features/plan_generation/presentation/generation_screen.dart';
import 'package:tamitu/features/plan_generation/presentation/plan_screen.dart';
import 'package:tamitu/features/trip_form/presentation/trip_form_screen.dart';

import '../../helpers.dart';

Future<TestEnv> _ready({bool? aiConsent = true}) async {
  final env = TestEnv(user: const AuthUser('u1'));
  await env.acceptCurrentPolicy('u1');
  if (aiConsent != null) {
    await env.local.upsert(
      'u1',
      ConsentRecord(
        id: 'ai-u1',
        type: ConsentType.aiProcessing,
        granted: aiConsent,
        policyVersion: AppConstants.aiConsentVersion,
        lang: 'pl',
        clientAt: DateTime.utc(2026, 11, 16),
        receivedAt: DateTime.utc(2026, 11, 16),
        synced: true,
      ),
    );
  }
  return env;
}

Future<void> _openForm(
  WidgetTester tester,
  TestEnv env, {
  String locale = 'pl',
}) async {
  await pumpApp(tester, env, locale: locale);
  await tester.tap(find.byKey(const Key('homeNewTrip')));
  await tester.pumpAndSettle();
  expect(find.byType(TripFormScreen), findsOneWidget);
}

Future<void> _show(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
}

Future<void> _tapDialogOk(WidgetTester tester, Type dialog) async {
  final buttons = find.descendant(
    of: find.byType(dialog),
    matching: find.byType(TextButton),
  );
  await tester.tap(buttons.last);
  await tester.pumpAndSettle();
}

/// Valid car trip (no airport), 2 days, flight number field hidden.
Future<void> _fillCarTrip(WidgetTester tester, {String locale = 'pl'}) async {
  await tester.enterText(
    find.byKey(const Key('tripForm.destination')),
    'Lizbona',
  );
  await tester.enterText(find.byKey(const Key('tripForm.lodging')), 'Baixa');
  final daysPlus = find.descendant(
    of: find.byKey(const Key('tripFormDays')),
    matching: find.byKey(const Key('stepperIncrease')),
  );
  await _show(tester, daysPlus);
  await tester.tap(daysPlus);
  await tester.pump();
  await tester.tap(daysPlus);
  await tester.pump();
  await _show(tester, find.byKey(const Key('tripFormArrivalMode')));
  await tester.tap(find.text(locale == 'en' ? 'Car' : 'Auto'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('tripForm.date')));
  await tester.pumpAndSettle();
  await _tapDialogOk(tester, DatePickerDialog);
  await tester.tap(find.byKey(const Key('tripForm.time')));
  await tester.pumpAndSettle();
  await _tapDialogOk(tester, TimePickerDialog);
}

Future<void> _tapGenerate(WidgetTester tester) async {
  // A focused text field scrolls itself back into view on rebuild: close it first.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final button = find.byKey(const Key('tripFormGenerate'));
  await _show(tester, button);
  await tester.tap(button);
}

void main() {
  testWidgets('empty form shows field errors and sends nothing', (
    tester,
  ) async {
    final env = await _ready();
    await _openForm(tester, env);
    await _tapGenerate(tester);
    await tester.pumpAndSettle();
    // Focus and scroll went to the first invalid field (destination).
    expect(find.text('To pole jest wymagane'), findsWidgets);
    expect(env.plans.calls, 0);
  });

  for (final locale in languages) {
    testWidgets('happy path: form -> EK-07 -> EK-08 ($locale)', (tester) async {
      final env = await _ready();
      env.plans.gate = Completer<void>();
      await _openForm(tester, env, locale: locale);
      await _fillCarTrip(tester, locale: locale);
      await _tapGenerate(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(GenerationScreen), findsOneWidget);
      expect(find.byKey(const Key('generationTitle')), findsOneWidget);
      env.plans.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(PlanScreen), findsOneWidget);
      expect(find.byType(TripFormScreen), findsNothing);
      expect(find.text('Lizbona'), findsWidgets);
      expect(find.byKey(const Key('planAiNotice')), findsOneWidget);
      final input = env.plans.inputs.single;
      expect(input.arrivalMode, ArrivalMode.car);
      expect(input.days, 2);
      expect(input.airport, isNull);
      expect(input.planLanguage, locale);
      // Day 1 of the sample plan has no items.
      expect(find.byKey(const Key('planDayOnlyArrival')), findsOneWidget);
    });
  }

  testWidgets('ai_unavailable returns to the form with the EK-16 message', (
    tester,
  ) async {
    final env = await _ready();
    env.plans.failures.add(
      const AppFailure(FailureKind.aiUnavailable, slotReleased: true),
    );
    await _openForm(tester, env);
    await _fillCarTrip(tester);
    await _tapGenerate(tester);
    await tester.pumpAndSettle();
    expect(find.byType(TripFormScreen), findsOneWidget);
    expect(find.text('Nie udało się ułożyć planu'), findsOneWidget);
    // Form data kept.
    expect(find.text('Lizbona'), findsOneWidget);
  });

  testWidgets('offline after the attempt shows the form notice', (
    tester,
  ) async {
    final env = await _ready();
    env.plans.failures.add(const AppFailure(FailureKind.offline));
    await _openForm(tester, env);
    await _fillCarTrip(tester);
    await _tapGenerate(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tripFormOffline')), findsOneWidget);
  });

  testWidgets(
    'ai_busy without slotReleased: state E, "Try now" retries with a new '
    'requestId and opens EK-08',
    (tester) async {
      final env = await _ready();
      env.plans.failures.add(
        const AppFailure(
          FailureKind.aiBusy,
          retryAfterSec: 60,
          slotReleased: false,
        ),
      );
      await _openForm(tester, env);
      await _fillCarTrip(tester);
      await _tapGenerate(tester);
      await tester.pumpAndSettle();
      expect(find.byType(AiBusyView), findsOneWidget);
      expect(find.byKey(const Key('aiBusyCountdown')), findsNothing);
      await tester.tap(find.byKey(const Key('aiBusyTryNow')));
      await tester.pumpAndSettle();
      expect(find.byType(PlanScreen), findsOneWidget);
      expect(env.plans.requestIds, hasLength(2));
      expect(env.plans.requestIds.toSet(), hasLength(2));
    },
  );

  testWidgets('ai_busy "Back to the form" returns without a message', (
    tester,
  ) async {
    final env = await _ready();
    env.plans.failures.add(
      const AppFailure(FailureKind.aiBusy, slotReleased: false),
    );
    await _openForm(tester, env);
    await _fillCarTrip(tester);
    await _tapGenerate(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('aiBusyBack')));
    await tester.pumpAndSettle();
    expect(find.byType(TripFormScreen), findsOneWidget);
    expect(find.byKey(const Key('tripFormFailure')), findsNothing);
  });

  testWidgets('cancel with confirmation returns with the snackbar', (
    tester,
  ) async {
    final env = await _ready();
    env.plans.gate = Completer<void>();
    await _openForm(tester, env);
    await _fillCarTrip(tester);
    await _tapGenerate(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('generationCancel')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('generationCancelConfirm')));
    await tester.pump(const Duration(milliseconds: 500));
    env.plans.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(TripFormScreen), findsOneWidget);
    expect(
      find.text('Generowanie przerwane. Nic nie zapisano.'),
      findsOneWidget,
    );
    expect(find.byType(PlanScreen), findsNothing);
  });

  testWidgets('without AI consent EK-06 opens first', (tester) async {
    final env = await _ready(aiConsent: null);
    await _openForm(tester, env);
    await _fillCarTrip(tester);
    await _tapGenerate(tester);
    await tester.pumpAndSettle();
    expect(find.byType(AiConsentScreen), findsOneWidget);
    expect(env.plans.calls, 0);
  });

  testWidgets('withdrawn AI consent shows the notice with "Give consent"', (
    tester,
  ) async {
    final env = await _ready(aiConsent: false);
    await _openForm(tester, env);
    await _fillCarTrip(tester);
    await _tapGenerate(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tripFormConsentWithdrawn')), findsOneWidget);
    expect(find.byKey(const Key('tripFormGiveConsent')), findsOneWidget);
    expect(env.plans.calls, 0);
  });

  testWidgets('flight shows airport and flight number; number never sent', (
    tester,
  ) async {
    final env = await _ready();
    await _openForm(tester, env);
    await tester.enterText(
      find.byKey(const Key('tripForm.destination')),
      'Lizbona',
    );
    await tester.enterText(find.byKey(const Key('tripForm.lodging')), 'Baixa');
    final daysPlus = find.descendant(
      of: find.byKey(const Key('tripFormDays')),
      matching: find.byKey(const Key('stepperIncrease')),
    );
    await _show(tester, daysPlus);
    await tester.tap(daysPlus);
    await _show(tester, find.byKey(const Key('tripFormArrivalMode')));
    await tester.tap(find.text('Lot'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tripForm.date')));
    await tester.pumpAndSettle();
    await _tapDialogOk(tester, DatePickerDialog);
    await tester.tap(find.byKey(const Key('tripForm.time')));
    await tester.pumpAndSettle();
    await _tapDialogOk(tester, TimePickerDialog);
    await _show(tester, find.byKey(const Key('tripForm.airport')));
    await tester.enterText(find.byKey(const Key('tripForm.airport')), 'LIS');
    await tester.enterText(
      find.byKey(const Key('tripForm.flightNumber')),
      'TP1234',
    );
    await _tapGenerate(tester);
    await tester.pumpAndSettle();
    expect(find.byType(PlanScreen), findsOneWidget);
    final input = env.plans.inputs.single;
    expect(input.airport, 'LIS');
    expect(input.flightNumber, 'TP1234');
    expect(
      input.toRequest(requestId: 'r', apiVersion: 1, testData: true).toString(),
      isNot(contains('TP1234')),
    );
    // Shown locally in the summary.
    expect(find.text('Lot TP1234'), findsOneWidget);
  });

  testWidgets('EK-08 without data shows the error with "Back to list"', (
    tester,
  ) async {
    final env = await _ready();
    await tester.pumpWidget(hostScreen(env, const PlanScreen(data: null)));
    await tester.pumpAndSettle();
    expect(find.text('Nie udało się otworzyć planu'), findsOneWidget);
    expect(find.byKey(const Key('planBackToList')), findsOneWidget);
  });

  // ------------------------------------------------ review PR #164

  testWidgets(
    '#1 an error while the cancel dialog is open closes the dialog and '
    'returns to the form with the message',
    (tester) async {
      final env = await _ready();
      env.plans.gate = Completer<void>();
      env.plans.failures.add(
        const AppFailure(FailureKind.aiUnavailable, slotReleased: true),
      );
      await _openForm(tester, env);
      await _fillCarTrip(tester);
      await _tapGenerate(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const Key('generationCancel')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('generationCancelConfirm')), findsOneWidget);
      env.plans.gate!.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('generationCancelConfirm')), findsNothing);
      expect(find.byType(GenerationScreen), findsNothing);
      expect(find.byType(TripFormScreen), findsOneWidget);
      expect(find.byKey(const Key('tripFormFailure')), findsOneWidget);
    },
  );

  Future<void> submitWith(
    WidgetTester tester,
    TestEnv env,
    AppFailure f,
  ) async {
    env.plans.failures.add(f);
    await _openForm(tester, env);
    await _fillCarTrip(tester);
    await _tapGenerate(tester);
    await tester.pumpAndSettle();
  }

  testWidgets('limit_exceeded: EK-05 with the limit message', (tester) async {
    final env = await _ready();
    await submitWith(
      tester,
      env,
      AppFailure(
        FailureKind.limitExceeded,
        limit: 5,
        resetAt: DateTime.utc(2026, 11, 24, 23),
      ),
    );
    expect(find.text('Dzisiejszy limit planów wykorzystany'), findsOneWidget);
    expect(find.textContaining('Kolejne od jutra'), findsOneWidget);
  });

  testWidgets('timeout: EK-05 with the timeout message', (tester) async {
    final env = await _ready();
    await submitWith(tester, env, const AppFailure(FailureKind.timeout));
    expect(find.textContaining('trwało zbyt długo'), findsOneWidget);
  });

  testWidgets('invalid_argument with a known field marks that field', (
    tester,
  ) async {
    final env = await _ready();
    await submitWith(
      tester,
      env,
      const AppFailure(FailureKind.invalidArgument, field: 'trip.destination'),
    );
    expect(
      find.text('Sprawdź dane w formularzu i spróbuj ponownie.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('tripFormFailure')), findsNothing);
  });

  testWidgets('invalid_argument without a field: CMP-13 notice', (
    tester,
  ) async {
    final env = await _ready();
    await submitWith(
      tester,
      env,
      const AppFailure(FailureKind.invalidArgument),
    );
    expect(find.byKey(const Key('tripFormFailure')), findsOneWidget);
  });

  testWidgets('unauthenticated: session expires, EK-02 opens', (tester) async {
    final env = await _ready();
    await submitWith(
      tester,
      env,
      const AppFailure(FailureKind.unauthenticated),
    );
    expect(find.byType(TripFormScreen), findsNothing);
    expect(find.byType(GenerationScreen), findsNothing);
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('consent_required ai_processing with a synced record in the app '
      'version: "Update the app" (CMP-18)', (tester) async {
    final env = await _ready();
    await submitWith(
      tester,
      env,
      const AppFailure(
        FailureKind.consentRequired,
        consentType: ConsentType.aiProcessing,
      ),
    );
    expect(find.byType(UpdateAppView), findsOneWidget);
  });

  testWidgets('consent_required ai_processing without a synced record: EK-06 '
      '"updated"', (tester) async {
    final env = await _ready(aiConsent: null);
    await env.local.upsert(
      'u1',
      ConsentRecord(
        id: 'ai-unsynced',
        type: ConsentType.aiProcessing,
        granted: true,
        policyVersion: AppConstants.aiConsentVersion,
        lang: 'pl',
        clientAt: DateTime.utc(2026, 11, 20),
      ),
    );
    // The pending record cannot be sent: neither by the background sync at session
    // start nor before generatePlan (offline twice).
    env.api.failures.addAll(const [
      AppFailure(FailureKind.offline),
      AppFailure(FailureKind.offline),
    ]);
    await submitWith(
      tester,
      env,
      const AppFailure(
        FailureKind.consentRequired,
        consentType: ConsentType.aiProcessing,
      ),
    );
    expect(find.byType(AiConsentScreen), findsOneWidget);
    expect(find.byKey(const Key('aiConsentUpdated')), findsOneWidget);
  });

  testWidgets('ai_busy with slotReleased: one automatic retry after the '
      'countdown opens EK-08', (tester) async {
    final env = await _ready();
    await submitWith(
      tester,
      env,
      const AppFailure(
        FailureKind.aiBusy,
        retryAfterSec: 60,
        slotReleased: true,
      ),
    );
    expect(find.byKey(const Key('aiBusyCountdown')), findsOneWidget);
    for (var i = 0; i < 61; i++) {
      env.mono += const Duration(seconds: 1);
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();
    expect(find.byType(PlanScreen), findsOneWidget);
    expect(env.plans.requestIds, hasLength(2));
    expect(env.plans.requestIds.toSet(), hasLength(2));
  });

  testWidgets('#2 plan content carries the plan language in semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final env = await _ready();
    const input = TripInput(
      destination: 'Lisbon',
      lodging: 'Baixa',
      days: 1,
      arrivalMode: ArrivalMode.car,
      arrivalDate: LocalDate(2027, 3, 2),
      arrivalTime: LocalTime(9, 0),
      planLanguage: 'en',
    );
    final plan = GeneratedPlan(
      requestId: 'r',
      language: 'en',
      days: const [
        PlanDay(
          dayNumber: 1,
          title: 'Old town',
          items: [
            PlanItem(
              startTime: '10:00',
              name: 'Castle',
              locality: 'Lisbon',
              description: 'Views.',
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      hostScreen(
        env,
        PlanScreen(
          data: PlanViewData(input: input, plan: plan),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final locales = <Locale>[];
    void visit(SemanticsNode node) {
      for (final a in node.getSemanticsData().attributedLabel.attributes) {
        if (a is LocaleStringAttribute) locales.add(a.locale);
      }
      node.visitChildren((c) {
        visit(c);
        return true;
      });
    }

    visit(tester.getSemantics(find.byType(PlanScreen)));
    expect(locales, contains(const Locale('en')));
    handle.dispose();
  });
}
