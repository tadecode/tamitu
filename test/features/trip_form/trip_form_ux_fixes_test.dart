// TAM-105: fixes from QA PR #164 decided by UX in TAM-102 (EK-05 v0.2, EK-07 v0.2,
// CMP-06 v0.2): Q4 (date/time layout), Q5 (focus and keyboard after EK-07 and the
// pickers), TAM101-2 (EK-07 bar title).
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tamitu/core/config/app_constants.dart';
import 'package:tamitu/core/errors/app_failure.dart';
import 'package:tamitu/features/auth/domain/auth_gateway.dart';
import 'package:tamitu/features/consent/domain/consent_record.dart';
import 'package:tamitu/features/consent/presentation/ai_consent_screen.dart';
import 'package:tamitu/features/generation/presentation/ai_busy_view.dart';
import 'package:tamitu/features/plan_generation/presentation/generation_screen.dart';
import 'package:tamitu/features/trip_form/presentation/trip_form_screen.dart';

import '../../helpers.dart';

/// [aiConsent] false = AI consent never given (EK-06 opens before EK-07).
Future<TestEnv> _ready({bool aiConsent = true}) async {
  final env = TestEnv(user: const AuthUser('u1'));
  await env.acceptCurrentPolicy('u1');
  if (!aiConsent) return env;
  await env.local.upsert(
    'u1',
    ConsentRecord(
      id: 'ai-u1',
      type: ConsentType.aiProcessing,
      granted: true,
      policyVersion: AppConstants.aiConsentVersion,
      lang: 'pl',
      clientAt: DateTime.utc(2026, 11, 16),
      receivedAt: DateTime.utc(2026, 11, 16),
      synced: true,
    ),
  );
  return env;
}

/// Opens EK-05 on a window of [width] × 800 dp.
Future<void> _openForm(
  WidgetTester tester,
  TestEnv env, {
  double width = 360,
  double textScale = 1,
  String locale = 'pl',
}) async {
  await pumpApp(tester, env, locale: locale, textScale: textScale);
  tester.view.physicalSize = Size(width * 3, 2400);
  await tester.pumpAndSettle();
  final newTrip = find.byKey(const Key('homeNewTrip'));
  await tester.ensureVisible(newTrip);
  await tester.pumpAndSettle();
  await tester.tap(newTrip);
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

final _destination = find.byKey(const Key('tripForm.destination'));
final _date = find.byKey(const Key('tripForm.date'));
final _time = find.byKey(const Key('tripForm.time'));

/// Valid car trip, 2 days.
Future<void> _fillCarTrip(WidgetTester tester, {String locale = 'pl'}) async {
  await tester.enterText(_destination, 'Lizbona');
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
  await tester.tap(_date);
  await tester.pumpAndSettle();
  await _tapDialogOk(tester, DatePickerDialog);
  await tester.tap(_time);
  await tester.pumpAndSettle();
  await _tapDialogOk(tester, TimePickerDialog);
}

/// Puts the cursor in the destination field (keyboard open), like a user who typed
/// last and then pressed "Create plan" without closing the keyboard.
Future<void> _typeInDestination(WidgetTester tester) async {
  await _show(tester, _destination);
  await tester.showKeyboard(_destination);
  await tester.pump();
  expect(tester.testTextInput.isVisible, isTrue);
}

/// Presses "Create plan" without taking the focus off the text field first.
Future<void> _pressGenerate(WidgetTester tester) async {
  final button = find.descendant(
    of: find.byKey(const Key('tripFormGenerate')),
    matching: find.byType(FilledButton),
  );
  tester.widget<FilledButton>(button).onPressed!();
  await tester.pump();
}

bool _textFieldFocused() {
  final ctx = FocusManager.instance.primaryFocus?.context;
  return ctx != null &&
      (ctx.widget is EditableText ||
          ctx.findAncestorWidgetOfExactType<EditableText>() != null);
}

/// True when the primary focus node wraps (or sits inside) [target].
bool _focusOn(WidgetTester tester, Finder target) {
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx == null) return false;
  final focused = find.byElementPredicate((e) => e == ctx);
  return tester.any(find.descendant(of: focused, matching: target)) ||
      tester.any(find.ancestor(of: focused, matching: target));
}

void _expectFocusOnGenerate(WidgetTester tester) {
  expect(_textFieldFocused(), isFalse);
  expect(tester.testTextInput.isVisible, isFalse);
  expect(_focusOn(tester, find.byKey(const Key('tripFormGenerate'))), isTrue);
}

void main() {
  group('Q4: date and time layout (EK-05 v0.2 "Układ", CMP-06 v0.2)', () {
    bool twoColumns(WidgetTester tester) =>
        tester.getTopLeft(_date).dy == tester.getTopLeft(_time).dy;

    // The test font (every glyph 1 em wide) does not measure like Roboto, so the label
    // itself cannot be measured here. The spec guarantee is geometric: on a phone the
    // time field (with "Godzina przylotu") gets the full content width, i.e. well over
    // the ~190 dp the label needs at 16 sp (EK-05 v0.2 "Układ").
    void expectFullWidth(WidgetTester tester, double width) {
      expect(twoColumns(tester), isFalse);
      expect(
        tester.getTopLeft(_time).dy,
        greaterThan(tester.getBottomLeft(_date).dy),
      );
      // Content column minus 16 dp margins on both sides.
      expect(tester.getSize(_date).width, width - 32);
      expect(tester.getSize(_time).width, width - 32);
    }

    for (final width in [360.0, 411.0]) {
      testWidgets(
        'phone ${width.toInt()} dp at 100 %: one column, full width',
        (tester) async {
          final env = await _ready();
          await _openForm(tester, env, width: width);
          await _show(tester, _time);
          expect(find.text('Godzina przylotu'), findsOneWidget);
          expectFullWidth(tester, width);
        },
      );
    }

    testWidgets('EN 360 dp at 100 %: "Landing time" in one column', (
      tester,
    ) async {
      final env = await _ready();
      await _openForm(tester, env, locale: 'en');
      await _show(tester, _time);
      expect(find.text('Landing time'), findsOneWidget);
      expectFullWidth(tester, 360);
    });

    // Boundary of the compact window class (EK-05 v0.2: < 600 dp = one column).
    testWidgets('window 599 dp at 100 %: one column', (tester) async {
      final env = await _ready();
      await _openForm(tester, env, width: 599);
      await _show(tester, _time);
      expect(twoColumns(tester), isFalse);
    });

    testWidgets('window 600 dp at 100 %: two columns', (tester) async {
      final env = await _ready();
      await _openForm(tester, env, width: 600);
      await _show(tester, _time);
      expect(twoColumns(tester), isTrue);
    });

    testWidgets('phone 360 dp at 200 % text: one column, full width', (
      tester,
    ) async {
      final env = await _ready();
      await _openForm(tester, env, textScale: 2);
      await _show(tester, _time);
      expectFullWidth(tester, 360);
    });

    testWidgets('window 800 dp at 100 %: two columns', (tester) async {
      final env = await _ready();
      await _openForm(tester, env, width: 800);
      await _show(tester, _time);
      expect(twoColumns(tester), isTrue);
      // Two halves of the 560 dp content column (minus margins and the 16 dp gap).
      expect(tester.getSize(_time).width, (560 - 32 - 16) / 2);
    });

    testWidgets('window 800 dp at 150 %: one column', (tester) async {
      final env = await _ready();
      await _openForm(tester, env, width: 800, textScale: 1.5);
      await _show(tester, _time);
      expect(twoColumns(tester), isFalse);
    });
  });

  group('Q5: focus and keyboard (EK-05 v0.2 "Fokus i klawiatura po powrocie")', () {
    testWidgets('"Stop" in EK-07: keyboard closed, focus on "Create plan", '
        'snackbar at the bottom edge', (tester) async {
      final env = await _ready();
      env.plans.gate = Completer<void>();
      await _openForm(tester, env);
      await _fillCarTrip(tester);
      await _typeInDestination(tester);
      await _pressGenerate(tester);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(GenerationScreen), findsOneWidget);
      // The keyboard closed before EK-07.
      expect(tester.testTextInput.isVisible, isFalse);
      await tester.tap(find.byKey(const Key('generationCancel')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const Key('generationCancelConfirm')));
      await tester.pump(const Duration(milliseconds: 500));
      env.plans.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(TripFormScreen), findsOneWidget);
      _expectFocusOnGenerate(tester);
      final snack = find.text('Generowanie przerwane. Nic nie zapisano.');
      expect(snack, findsOneWidget);
      // Bottom edge of the 800 dp window, not pushed up by a keyboard.
      final bar = tester.getRect(find.byType(SnackBar));
      expect(bar.bottom, greaterThan(800 - 80));
      expect(bar.bottom, lessThanOrEqualTo(800));
    });

    testWidgets('back from ai_busy: no text field focused, keyboard closed', (
      tester,
    ) async {
      final env = await _ready();
      env.plans.failures.add(
        const AppFailure(FailureKind.aiBusy, slotReleased: false),
      );
      await _openForm(tester, env);
      await _fillCarTrip(tester);
      await _typeInDestination(tester);
      await _pressGenerate(tester);
      await tester.pumpAndSettle();
      expect(find.byType(AiBusyView), findsOneWidget);
      await tester.tap(find.byKey(const Key('aiBusyBack')));
      await tester.pumpAndSettle();
      expect(find.byType(TripFormScreen), findsOneWidget);
      _expectFocusOnGenerate(tester);
    });

    testWidgets('error with CMP-13: no text field focused, keyboard closed', (
      tester,
    ) async {
      final env = await _ready();
      env.plans.failures.add(const AppFailure(FailureKind.aiUnavailable));
      await _openForm(tester, env);
      await _fillCarTrip(tester);
      await _typeInDestination(tester);
      await _pressGenerate(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tripFormFailure')), findsOneWidget);
      _expectFocusOnGenerate(tester);
    });

    testWidgets('"I do not agree" in EK-06 (first question): back on EK-05, '
        'data kept, focus on "Create plan", keyboard closed', (tester) async {
      final env = await _ready(aiConsent: false);
      await _openForm(tester, env);
      await _fillCarTrip(tester);
      await _typeInDestination(tester);
      await _pressGenerate(tester);
      await tester.pumpAndSettle();
      expect(find.byType(AiConsentScreen), findsOneWidget);
      expect(tester.testTextInput.isVisible, isFalse);
      final disagree = find.byKey(const Key('aiConsentDisagree'));
      await tester.ensureVisible(disagree);
      await tester.pumpAndSettle();
      await tester.tap(disagree);
      await tester.pumpAndSettle();

      expect(find.byType(TripFormScreen), findsOneWidget);
      expect(find.text('Lizbona'), findsOneWidget);
      // Nothing sent, no message (EK-06 "Nie zgadzam się" = back without sending).
      expect(env.plans.calls, 0);
      expect(find.byKey(const Key('tripFormFailure')), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      _expectFocusOnGenerate(tester);
    });

    testWidgets('consent_required from EK-07, "I do not agree" in EK-06 '
        '"updated": focus on "Create plan", keyboard closed', (tester) async {
      final env = await _ready(aiConsent: false);
      // A local, unsynced record: the server asks for consent again and the app
      // shows EK-06 "updated" (same setup as plan_flow_test).
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
      env.api.failures.addAll(const [
        AppFailure(FailureKind.offline),
        AppFailure(FailureKind.offline),
      ]);
      env.plans.failures.add(
        const AppFailure(
          FailureKind.consentRequired,
          consentType: ConsentType.aiProcessing,
        ),
      );
      await _openForm(tester, env);
      await _fillCarTrip(tester);
      await _typeInDestination(tester);
      await _pressGenerate(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('aiConsentUpdated')), findsOneWidget);
      final disagree = find.byKey(const Key('aiConsentDisagree'));
      await tester.ensureVisible(disagree);
      await tester.pumpAndSettle();
      await tester.tap(disagree);
      await tester.pumpAndSettle();

      expect(find.byType(TripFormScreen), findsOneWidget);
      _expectFocusOnGenerate(tester);
    });

    testWidgets('success: EK-08 keeps the focus, the form does not take it', (
      tester,
    ) async {
      final env = await _ready();
      await _openForm(tester, env);
      await _fillCarTrip(tester);
      await _typeInDestination(tester);
      await _pressGenerate(tester);
      await tester.pumpAndSettle();
      expect(find.byType(GenerationScreen), findsNothing);
      expect(find.byType(TripFormScreen), findsNothing);
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('invalid_argument with a field: focus goes to that field', (
      tester,
    ) async {
      final env = await _ready();
      env.plans.failures.add(
        const AppFailure(
          FailureKind.invalidArgument,
          field: 'trip.destination',
        ),
      );
      await _openForm(tester, env);
      await _fillCarTrip(tester);
      await _typeInDestination(tester);
      await _pressGenerate(tester);
      await tester.pumpAndSettle();
      expect(find.byType(TripFormScreen), findsOneWidget);
      expect(_focusOn(tester, _destination), isTrue);
      expect(
        _focusOn(tester, find.byKey(const Key('tripFormGenerate'))),
        isFalse,
      );
    });

    for (final picker in ['date', 'time']) {
      testWidgets(
        '$picker picker closed: focus on its field, keyboard closed',
        (tester) async {
          final env = await _ready();
          await _openForm(tester, env);
          await _typeInDestination(tester);
          final field = picker == 'date' ? _date : _time;
          await _show(tester, field);
          await tester.tap(field);
          await tester.pumpAndSettle();
          await _tapDialogOk(
            tester,
            picker == 'date' ? DatePickerDialog : TimePickerDialog,
          );
          expect(_textFieldFocused(), isFalse);
          expect(tester.testTextInput.isVisible, isFalse);
          expect(_focusOn(tester, field), isTrue);
        },
      );
    }
  });

  group('TAM101-2: EK-07 bar title (EK-07 v0.2)', () {
    for (final locale in languages) {
      testWidgets('bar "New trip", heading in the body ($locale)', (
        tester,
      ) async {
        final env = await _ready();
        env.plans.gate = Completer<void>();
        env.plans.failures.add(
          const AppFailure(FailureKind.aiBusy, slotReleased: false),
        );
        await _openForm(tester, env, locale: locale);
        await _fillCarTrip(tester, locale: locale);
        await _pressGenerate(tester);
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(GenerationScreen), findsOneWidget);

        final title = locale == 'pl' ? 'Nowa podróż' : 'New trip';
        final heading = locale == 'pl'
            ? 'Układamy plan…'
            : 'Building your plan…';
        final bar = find.descendant(
          of: find.byType(GenerationScreen),
          matching: find.byType(AppBar),
        );
        // Loading: the task on the bar, what is happening in the body.
        expect(
          find.descendant(of: bar, matching: find.text(title)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: bar, matching: find.text(heading)),
          findsNothing,
        );
        expect(find.text(heading), findsOneWidget);

        // ai_busy: the same bar, which does not contradict the body.
        env.plans.gate!.complete();
        await tester.pumpAndSettle();
        expect(find.byType(AiBusyView), findsOneWidget);
        expect(
          find.descendant(of: bar, matching: find.text(title)),
          findsOneWidget,
        );
      });
    }
  });
}
