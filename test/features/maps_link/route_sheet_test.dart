import 'dart:async';
import 'dart:ui' show SemanticsActionEvent;

import 'package:flutter/rendering.dart' show SemanticsAction, SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tamitu/features/maps_link/domain/maps_link.dart';
import 'package:tamitu/features/maps_link/presentation/route_sheet.dart';
import 'package:tamitu/features/plan_generation/domain/generated_plan.dart';
import 'package:tamitu/features/plan_generation/domain/trip_input.dart';
import 'package:tamitu/features/plan_generation/presentation/plan_screen.dart';

import '../../helpers.dart';

/// EK-09 v0.4 (TAM-20): starts, remembered mode, opening the link, accessibility.
PlanViewData _data({String lodging = 'Pensjonat Przykładowy'}) => PlanViewData(
  input: TripInput(
    destination: 'Lizbona',
    lodging: lodging,
    days: 1,
    arrivalMode: ArrivalMode.car,
    arrivalDate: const LocalDate(2027, 5, 12),
    arrivalTime: const LocalTime(9, 0),
    planLanguage: 'pl',
  ),
  plan: const GeneratedPlan(
    requestId: 'r',
    language: 'pl',
    days: [
      PlanDay(
        dayNumber: 1,
        title: 'Dzień zwiedzania',
        items: [
          PlanItem(
            startTime: '10:00',
            name: 'Zamek św. Jerzego',
            locality: 'Alfama',
            description: 'Opis 1',
          ),
          PlanItem(
            startTime: '13:00',
            name: 'Tasca & Filhos #2',
            locality: 'Mouraria',
            description: 'Opis 2',
          ),
        ],
      ),
    ],
  ),
);

Future<void> _pump(
  WidgetTester tester,
  TestEnv env, {
  PlanViewData? data,
  String locale = 'pl',
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    hostScreen(
      env,
      PlanScreen(data: data ?? _data()),
      locale: locale,
      brightness: brightness,
    ),
  );
  await tester.pumpAndSettle();
}

/// Taps "Directions" of the item with [index] (0 = first item of the day).
Future<void> _openSheet(WidgetTester tester, int index) async {
  final name = find.text(
    _data().plan.days.single.items[index].name,
    findRichText: true,
  );
  // The plan list is lazy: scroll the item in first (large text).
  await tester.scrollUntilVisible(
    name,
    100,
    scrollable: find.byType(Scrollable).first,
  );
  final button = find.descendant(
    of: find.ancestor(of: name, matching: find.byType(InkWell)).first,
    matching: find.byKey(const Key('planItemRoute')),
  );
  await tester.scrollUntilVisible(
    button,
    100,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
  expect(find.byType(RouteSheet), findsOneWidget);
}

Finder _start(RouteStartKind kind) =>
    find.byKey(Key('routeStart-${kind.name}'));

RouteStartKind? _selectedStart(WidgetTester tester) => tester
    .widget<RadioGroup<RouteStartKind>>(find.byType(RadioGroup<RouteStartKind>))
    .groupValue;

TravelMode _selectedMode(WidgetTester tester) => tester
    .widget<SegmentedButton<TravelMode>>(
      find.byType(SegmentedButton<TravelMode>),
    )
    .selected
    .single;

/// Performs the TalkBack "double tap" on [node].
void _semanticsTap(WidgetTester tester, SemanticsNode node) =>
    tester.binding.performSemanticsAction(
      SemanticsActionEvent(
        type: SemanticsAction.tap,
        viewId: tester.view.viewId,
        nodeId: node.id,
      ),
    );

Future<void> _tapOpen(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('routeOpenMaps')));
  await tester.tap(find.byKey(const Key('routeOpenMaps')));
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in languages) {
    for (final brightness in brightnesses) {
      testWidgets('default: three starts, My location, Transit, one tap opens '
          'Maps without origin ($locale, ${brightness.name})', (tester) async {
        final env = TestEnv();
        await _pump(tester, env, locale: locale, brightness: brightness);
        final en = locale == 'en';
        expect(find.text(en ? 'Directions' : 'Trasa'), findsNWidgets(2));
        await _openSheet(tester, 1);

        expect(
          find.text(
            en
                ? 'Directions to: Tasca & Filhos #2'
                : 'Trasa do: Tasca & Filhos #2',
          ),
          findsOneWidget,
        );
        expect(find.text(en ? 'From' : 'Skąd'), findsOneWidget);
        expect(find.text(en ? 'How' : 'Czym'), findsOneWidget);
        expect(
          find.text(
            en
                ? 'Google Maps will find where you are. It may ask for access '
                      'to your location.'
                : 'Bieżącą pozycję ustali Google Maps. Może poprosić o dostęp '
                      'do lokalizacji.',
          ),
          findsOneWidget,
        );
        expect(_start(RouteStartKind.myLocation), findsOneWidget);
        expect(_start(RouteStartKind.previousPlace), findsOneWidget);
        expect(_start(RouteStartKind.lodging), findsOneWidget);
        // Previous place description = its name (plan language).
        expect(
          find.descendant(
            of: _start(RouteStartKind.previousPlace),
            matching: find.text('Zamek św. Jerzego'),
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            en
                ? 'Pensjonat Przykładowy · approximate point'
                : 'Pensjonat Przykładowy · punkt przybliżony',
          ),
          findsOneWidget,
        );
        expect(_selectedStart(tester), RouteStartKind.myLocation);
        expect(_selectedMode(tester), TravelMode.transit);

        await _tapOpen(tester);
        final uri = env.opened.single;
        expect(uri.queryParameters.containsKey('origin'), isFalse);
        expect(uri.queryParameters['travelmode'], 'transit');
        expect(
          uri.queryParameters['destination'],
          'Tasca & Filhos #2, Mouraria, Lizbona',
        );
        // The sheet stays open under Maps (EK-09 "Wejście i wyjście").
        expect(find.byType(RouteSheet), findsOneWidget);
        // Opening does not change the stored mode.
        expect(env.savedTravelModes, isEmpty);
      });
    }
  }

  testWidgets('first item of the day: no "Previous place"', (tester) async {
    final env = TestEnv();
    await _pump(tester, env);
    await _openSheet(tester, 0);
    expect(_start(RouteStartKind.myLocation), findsOneWidget);
    expect(_start(RouteStartKind.previousPlace), findsNothing);
    expect(_start(RouteStartKind.lodging), findsOneWidget);
    expect(find.text('Poprzedni punkt dnia'), findsNothing);
  });

  testWidgets('plan without lodging: "Your stay" hidden, no empty origin', (
    tester,
  ) async {
    final env = TestEnv();
    await _pump(tester, env, data: _data(lodging: '  '));
    await _openSheet(tester, 1);
    expect(_start(RouteStartKind.lodging), findsNothing);
    expect(find.text('Nocleg'), findsNothing);
    expect(_start(RouteStartKind.previousPlace), findsOneWidget);
    await _tapOpen(tester);
    expect(env.opened.single.query, isNot(contains('origin')));
  });

  testWidgets('first item and no lodging: only My location, selected', (
    tester,
  ) async {
    final env = TestEnv();
    await _pump(tester, env, data: _data(lodging: ''));
    await _openSheet(tester, 0);
    expect(find.byType(RadioListTile<RouteStartKind>), findsOneWidget);
    expect(_selectedStart(tester), RouteStartKind.myLocation);
    expect(find.text('Moja lokalizacja'), findsOneWidget);
  });

  testWidgets('"Previous place" and "Your stay" pass plan text as origin', (
    tester,
  ) async {
    final env = TestEnv();
    await _pump(tester, env);
    await _openSheet(tester, 1);

    await tester.tap(_start(RouteStartKind.previousPlace));
    await tester.pumpAndSettle();
    expect(_selectedStart(tester), RouteStartKind.previousPlace);
    await _tapOpen(tester);
    expect(
      env.opened.last.queryParameters['origin'],
      'Zamek św. Jerzego, Alfama, Lizbona',
    );

    await tester.tap(_start(RouteStartKind.lodging));
    await tester.pumpAndSettle();
    await _tapOpen(tester);
    expect(
      env.opened.last.queryParameters['origin'],
      'Pensjonat Przykładowy, Lizbona',
    );
    expect(env.opened, hasLength(2));
  });

  testWidgets('mode is remembered, start is not (UX11)', (tester) async {
    final env = TestEnv();
    await _pump(tester, env);
    await _openSheet(tester, 1);

    await tester.tap(find.byKey(const Key('routeMode-walking')));
    await tester.pumpAndSettle();
    expect(_selectedMode(tester), TravelMode.walking);
    expect(env.savedTravelModes, [TravelMode.walking]);
    await tester.tap(_start(RouteStartKind.lodging));
    await tester.pumpAndSettle();

    // Close (handle) and open again for another item.
    await tester.tap(find.byKey(const Key('routeSheetHandle')));
    await tester.pumpAndSettle();
    expect(find.byType(RouteSheet), findsNothing);
    await _openSheet(tester, 0);
    expect(_selectedMode(tester), TravelMode.walking);
    expect(_selectedStart(tester), RouteStartKind.myLocation);

    await _tapOpen(tester);
    expect(env.opened.single.queryParameters['travelmode'], 'walking');
    expect(env.opened.single.queryParameters.containsKey('origin'), isFalse);
  });

  testWidgets('mode saved at the previous run is used', (tester) async {
    final env = TestEnv()..initialTravelMode = TravelMode.driving;
    await _pump(tester, env);
    await _openSheet(tester, 1);
    expect(_selectedMode(tester), TravelMode.driving);
    await _tapOpen(tester);
    expect(env.opened.single.queryParameters['travelmode'], 'driving');
  });

  for (final locale in languages) {
    testWidgets('link cannot be opened: snackbar, sheet stays ($locale)', (
      tester,
    ) async {
      final env = TestEnv()..openSucceeds = false;
      await _pump(tester, env, locale: locale);
      await _openSheet(tester, 1);
      await _tapOpen(tester);
      expect(
        find.text(
          locale == 'en'
              ? "Couldn't open maps. Please try again."
              : 'Nie udało się otworzyć map. Spróbuj ponownie.',
        ),
        findsOneWidget,
      );
      expect(find.byType(RouteSheet), findsOneWidget);

      // Try again works once the system can open the link.
      env.openSucceeds = true;
      await _tapOpen(tester);
      expect(env.opened, hasLength(2));
    });
  }

  testWidgets('accessibility: labels, hint, handle closes, 48 dp targets', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final env = TestEnv();
    await _pump(tester, env);

    // EK-08 item: "Directions to {place}".
    expect(find.bySemanticsLabel('Trasa do Tasca & Filhos #2'), findsOneWidget);
    // TalkBack can press "Directions" (QA PR #178): the semantics tap opens EK-09.
    final route = tester.getSemantics(
      find.byKey(const Key('planItemRoute')).at(1),
    );
    expect(route.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    _semanticsTap(tester, route);
    await tester.pumpAndSettle();
    expect(find.byType(RouteSheet), findsOneWidget);

    final open = tester.getSemantics(find.byKey(const Key('routeOpenMaps')));
    expect(open.label, 'Otwórz w Google Maps');
    expect(open.hint, 'otwiera inną aplikację');
    expect(open.flagsCollection.isButton, isTrue);
    // TalkBack can press "Open in Google Maps" (QA PR #178); no action while opening.
    expect(open.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    env.pendingOpen = Completer<bool>();
    _semanticsTap(tester, open);
    await tester.pump();
    expect(env.opened, hasLength(1));
    expect(
      tester
          .getSemantics(find.byKey(const Key('routeOpenMaps')))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isFalse,
    );
    env.pendingOpen!.complete(true);
    env.pendingOpen = null;
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.byKey(const Key('routeOpenMaps')))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );

    final close = find.bySemanticsLabel('Zamknij arkusz');
    expect(close, findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('routeSheetHandle'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester
          .getSemantics(find.byKey(const Key('routeTitle')))
          .flagsCollection
          .isHeader,
      isTrue,
    );

    for (final kind in RouteStartKind.values) {
      expect(tester.getSize(_start(kind)).height, greaterThanOrEqualTo(48));
    }
    expect(
      tester.getSize(find.byKey(const Key('routeOpenMaps'))).height,
      greaterThanOrEqualTo(48),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    await tester.tap(find.byKey(const Key('routeSheetHandle')));
    await tester.pumpAndSettle();
    expect(find.byType(RouteSheet), findsNothing);
    handle.dispose();
  });

  testWidgets('200 % text: modes as a list, sheet scrolls, button reachable', (
    tester,
  ) async {
    final env = TestEnv();
    await _pump(tester, env, textScale: 2);
    await _openSheet(tester, 1);
    expect(find.byType(SegmentedButton<TravelMode>), findsNothing);
    expect(find.byType(RadioListTile<TravelMode>), findsNWidgets(3));
    await tester.ensureVisible(find.byKey(const Key('routeMode-driving')));
    await tester.tap(find.byKey(const Key('routeMode-driving')));
    await tester.pumpAndSettle();
    expect(env.savedTravelModes, [TravelMode.driving]);
    await _tapOpen(tester);
    expect(env.opened.single.queryParameters['travelmode'], 'driving');
    expect(tester.takeException(), isNull);
  });
}
