import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tamitu/app/home_screen.dart';
import 'package:tamitu/features/auth/domain/auth_gateway.dart';
import 'package:tamitu/features/plan_generation/data/fake_plan_api.dart';
import 'package:tamitu/features/plan_generation/domain/trip_input.dart';
import 'package:tamitu/features/trip_form/presentation/trip_form_screen.dart';

import 'helpers.dart';

Future<TestEnv> _ready() async {
  final env = TestEnv(user: const AuthUser('u1'));
  await env.acceptCurrentPolicy('u1');
  return env;
}

TripInput trip(String destination, {int days = 4, bool flight = true}) =>
    TripInput(
      destination: destination,
      lodging: 'Centrum',
      days: days,
      arrivalMode: flight ? ArrivalMode.flight : ArrivalMode.car,
      arrivalDate: const LocalDate(2027, 5, 12),
      arrivalTime: const LocalTime(14, 0),
      airport: flight ? 'LIS' : null,
      planLanguage: 'pl',
    );

/// Saves a sample plan for [destination] in the fake repository of [env].
Future<String> savePlan(
  TestEnv env,
  String destination, {
  String uid = 'u1',
  int days = 4,
  bool flight = true,
}) {
  final input = trip(destination, days: days, flight: flight);
  return env.savedPlans.save(
    uid,
    input,
    FakePlanApi.samplePlan(input, requestId: 'r'),
  );
}

void main() {
  for (final locale in languages) {
    for (final brightness in brightnesses) {
      testWidgets('EK-04 empty state ($locale, ${brightness.name})', (
        tester,
      ) async {
        await pumpApp(
          tester,
          await _ready(),
          locale: locale,
          brightness: brightness,
        );
        expect(find.byType(HomeScreen), findsOneWidget);
        final en = locale == 'en';
        expect(find.text(en ? 'Your trips' : 'Twoje podróże'), findsOneWidget);
        expect(
          find.text(en ? 'No trips yet' : 'Nie masz jeszcze planów'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('homeNewTrip')), findsOneWidget);
        expect(
          find.byKey(const Key('planListDeviceOnlyNotice')),
          findsOneWidget,
        );
        // One action only: the FAB is hidden in the empty state.
        expect(find.byKey(const Key('planListFab')), findsNothing);
      });
    }
  }

  testWidgets('unsupported device language falls back to English (ADR-0006)', (
    tester,
  ) async {
    await pumpApp(tester, await _ready(), locale: 'de');
    expect(find.text('Your trips'), findsOneWidget);
  });

  testWidgets('empty state "New trip" opens EK-05', (tester) async {
    await pumpApp(tester, await _ready());
    await tester.tap(find.byKey(const Key('homeNewTrip')));
    await tester.pumpAndSettle();
    expect(find.byType(TripFormScreen), findsOneWidget);
  });

  for (final locale in languages) {
    testWidgets('EK-04 list: newest first, card content, FAB ($locale)', (
      tester,
    ) async {
      final env = await _ready();
      await savePlan(env, 'Lizbona', days: 4);
      await savePlan(env, 'Kraków', days: 1, flight: false);
      await pumpApp(tester, env, locale: locale);
      final en = locale == 'en';

      final lisbon = tester.getTopLeft(find.text('Lizbona'));
      final krakow = tester.getTopLeft(find.text('Kraków'));
      expect(krakow.dy, lessThan(lisbon.dy)); // saved later = on top
      expect(find.text(en ? '4 days · flight' : '4 dni · lot'), findsOneWidget);
      expect(find.text(en ? '1 day · car' : '1 dzień · auto'), findsOneWidget);
      expect(
        find.text(en ? 'Created May 12, 2027' : 'Utworzono 12 maja 2027'),
        findsNWidgets(2),
      );
      expect(find.byKey(const Key('planListFab')), findsOneWidget);
      expect(find.byKey(const Key('planListEmpty')), findsNothing);

      await tester.tap(find.byKey(const Key('planListFab')));
      await tester.pumpAndSettle();
      expect(find.byType(TripFormScreen), findsOneWidget);
    });
  }

  testWidgets('a card is one TalkBack element with the full label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final env = await _ready();
    await savePlan(env, 'Lizbona', days: 4);
    await pumpApp(tester, env);
    expect(
      tester.getSemantics(find.byKey(const Key('planCard-trip-1'))),
      matchesSemantics(
        label: 'Lizbona, 4 dni, lot, Utworzono 12 maja 2027',
        isButton: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('long destination wraps to two lines, card at least 72 dp', (
    tester,
  ) async {
    final env = await _ready();
    await savePlan(
      env,
      'Walencja, Albufera i miasteczka na wybrzeżu Costa Blanca oraz okolice',
    );
    await pumpApp(tester, env);
    final text = tester.widget<Text>(find.textContaining('Walencja, Albufera'));
    expect(text.maxLines, 2);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(
      tester.getSize(find.byKey(const Key('planCard-trip-1'))).height,
      greaterThanOrEqualTo(72),
    );
  });

  testWidgets('plans of another account are not listed (US-008)', (
    tester,
  ) async {
    final env = await _ready();
    await savePlan(env, 'Cudze', uid: 'u2');
    await pumpApp(tester, env);
    expect(find.text('Cudze'), findsNothing);
    expect(find.byKey(const Key('planListEmpty')), findsOneWidget);
  });

  testWidgets('read error: CMP-18 with "Try again", retry loads the list', (
    tester,
  ) async {
    final env = await _ready();
    await savePlan(env, 'Lizbona');
    env.savedPlans.failList = 1;
    await pumpApp(tester, env, locale: 'en');
    expect(find.byKey(const Key('planListError')), findsOneWidget);
    expect(find.text("Couldn't load your trips"), findsOneWidget);
    expect(find.byKey(const Key('planListFab')), findsNothing);

    await tester.tap(find.byKey(const Key('planListRetry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('planListError')), findsNothing);
    expect(find.text('Lizbona'), findsOneWidget);
  });

  testWidgets('loading: nothing for 300 ms, then the skeleton, FAB hidden', (
    tester,
  ) async {
    final env = await _ready();
    await savePlan(env, 'Lizbona');
    env.savedPlans.gate = Completer<void>();
    final handle = tester.ensureSemantics();
    await pumpApp(tester, env, settle: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('planListLoading')), findsNothing);
    await tester.pump(planListSkeletonDelay);
    expect(find.byKey(const Key('planListLoading')), findsOneWidget);
    expect(find.bySemanticsLabel('Wczytywanie'), findsOneWidget);
    expect(find.byKey(const Key('planListFab')), findsNothing);

    env.savedPlans.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('planListLoading')), findsNothing);
    expect(find.text('Lizbona'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('200% text: cards grow, nothing overflows', (tester) async {
    final env = await _ready();
    await savePlan(env, 'Lizbona');
    await pumpApp(tester, env, textScale: 2);
    expect(tester.takeException(), isNull);
    expect(find.text('Lizbona'), findsOneWidget);
  });

  testWidgets('semantics: list title is a header', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, await _ready());
    expect(
      tester.getSemantics(find.text('Twoje podróże')),
      matchesSemantics(label: 'Twoje podróże', isHeader: true),
    );
    handle.dispose();
  });
}
