// TAM-99: EK-07 "AI busy" (ai_busy) – docs/ux/screens/ek-07-ai-busy.md, ADR-0016 pkt 10-14.
// The countdown runs on the fake async clock of testWidgets plus a fake monotonic clock;
// expected texts are copied from the owner-approved table of the spec (no changes allowed).
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tamitu/core/errors/app_failure.dart';
import 'package:tamitu/features/generation/application/ai_busy_controller.dart';
import 'package:tamitu/features/generation/presentation/ai_busy_view.dart';

import '../../helpers.dart';

class _Mono {
  Duration t = Duration.zero;
  Duration call() => t;
}

AppFailure _busy({bool? slotReleased = true, Object? retryAfterSec = 60}) =>
    classifyCallableError(
      code: 'unavailable',
      details: {
        'code': 'ai_busy',
        'retryAfterSec': ?retryAfterSec,
        'slotReleased': ?slotReleased,
      },
    );

/// Host of the view: records retries (completed by the test), success, failures and back.
class _Harness {
  _Harness(AppFailure failure, {this.mono}) {
    controller = AiBusyController(
      failure: failure,
      retry: () {
        final c = Completer<AppFailure?>();
        pending.add(c);
        return c.future;
      },
      onSuccess: () => successes++,
      onFailure: failures.add,
      clock: mono?.call,
    );
  }

  final _Mono? mono;
  late final AiBusyController controller;
  final pending = <Completer<AppFailure?>>[];
  final failures = <AppFailure>[];
  int successes = 0;
  int backs = 0;

  Widget widget(String locale, {Brightness brightness = Brightness.light}) =>
      hostScreen(
        TestEnv(),
        Scaffold(
          appBar: AppBar(title: const Text('Nowa podróż')),
          body: AiBusyView(controller: controller, onBack: () => backs++),
        ),
        locale: locale,
        brightness: brightness,
      );
}

Future<_Harness> _pump(
  WidgetTester tester,
  AppFailure failure, {
  String locale = 'pl',
  Brightness brightness = Brightness.light,
  _Mono? mono,
}) async {
  final h = _Harness(failure, mono: mono ?? _Mono());
  addTearDown(h.controller.dispose);
  await tester.pumpWidget(h.widget(locale, brightness: brightness));
  await tester.pump();
  return h;
}

/// Advances both clocks second by second (timers fire on the fake async clock).
Future<void> _advance(WidgetTester tester, _Harness h, int seconds) async {
  for (var i = 0; i < seconds; i++) {
    h.mono!.t += const Duration(seconds: 1);
    await tester.pump(const Duration(seconds: 1));
  }
}

const _texts = {
  'pl': {
    'title': 'Nasz asystent AI jest chwilowo przeciążony',
    'still': 'Nasz asystent AI nadal jest przeciążony',
    'auto1': 'Spróbujemy ponownie za minutę. Nie musisz nic robić.',
    'auto2': 'Spróbujemy ponownie za 2 minuty. Nie musisz nic robić.',
    'manual': 'Spróbuj ponownie za chwilę. Twoje dane w formularzu zostały zachowane.',
    'paused': 'Gdy aplikacja była w tle, nie ponawialiśmy próby. Możesz spróbować teraz.',
    'released': 'Ta próba nie wlicza się do limitu.',
    'counted': 'Ta próba została wliczona do dzisiejszego limitu.',
    'unknown': 'Ta próba mogła zostać wliczona do dzisiejszego limitu.',
    'countdown': 'Ponowna próba za 1:00',
    'countdown42': 'Ponowna próba za 0:42',
    'a11y42': 'Ponowna próba za 42 sekundy',
    'a11y45': 'Ponowna próba za 45 sekund',
    'a11y1': 'Ponowna próba za 1 sekundę',
    'tryNow': 'Spróbuj teraz',
    'back': 'Wróć do formularza',
    'retrying': 'Próbujemy ponownie…',
  },
  'en': {
    'title': 'Our AI assistant is busy right now',
    'still': 'Our AI assistant is still busy',
    'auto1': "We'll try again in a minute. You don't need to do anything.",
    'auto2': "We'll try again in 2 minutes. You don't need to do anything.",
    'manual':
        'Please try again in a moment. Your trip details are kept in the form.',
    'paused':
        "We didn't retry while the app was in the background. You can try now.",
    'released': "This attempt doesn't count towards your limit.",
    'counted': "This attempt counted towards today's limit.",
    'unknown': "This attempt may have counted towards today's limit.",
    'countdown': 'Retrying in 1:00',
    'countdown42': 'Retrying in 0:42',
    'a11y42': 'Retrying in 42 seconds',
    'a11y45': 'Retrying in 45 seconds',
    'a11y1': 'Retrying in 1 second',
    'tryNow': 'Try now',
    'back': 'Back to the form',
    'retrying': 'Trying again…',
  },
};

String _countdownLabel(WidgetTester tester) =>
    tester.getSemantics(find.byKey(const Key('aiBusyCountdown'))).label;

double? _bar(WidgetTester tester) => tester
    .widget<LinearProgressIndicator>(find.byKey(const Key('aiBusyBar')))
    .value;

void main() {
  group('formatting', () {
    test('m:ss without a leading zero for minutes', () {
      expect(formatCountdown(60), '1:00');
      expect(formatCountdown(42), '0:42');
      expect(formatCountdown(5), '0:05');
      expect(formatCountdown(120), '2:00');
      expect(formatCountdown(-3), '0:00');
    });
    test('{minutes} = retryAfterSec / 60 rounded up', () {
      expect(countdownMinutes(30), 1);
      expect(countdownMinutes(60), 1);
      expect(countdownMinutes(61), 2);
      expect(countdownMinutes(120), 2);
    });
  });

  for (final lang in languages) {
    final t = _texts[lang]!;
    for (final brightness in brightnesses) {
      testWidgets('A: countdown state texts ($lang, ${brightness.name})', (
        tester,
      ) async {
        await _pump(tester, _busy(), locale: lang, brightness: brightness);
        expect(find.text(t['title']!), findsOneWidget);
        expect(find.text('${t['auto1']} ${t['released']}'), findsOneWidget);
        expect(find.text(t['countdown']!), findsOneWidget);
        expect(find.text(t['tryNow']!), findsOneWidget);
        expect(find.text(t['back']!), findsOneWidget);
        expect(_bar(tester), 1.0);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
      'A: ticks every second, a11y label in words, bar empties ($lang)',
      (tester) async {
        final h = await _pump(tester, _busy(), locale: lang);
        await _advance(tester, h, 18);
        expect(find.text(t['countdown42']!), findsOneWidget);
        expect(_countdownLabel(tester), t['a11y42']);
        expect(_bar(tester), closeTo(42 / 60, 1e-9));
        await _advance(tester, h, 41);
        expect(_countdownLabel(tester), t['a11y1']);
        expect(h.pending, isEmpty);
      },
    );

    testWidgets('A -> C -> B: one automatic retry, then button only ($lang)', (
      tester,
    ) async {
      final h = await _pump(tester, _busy(), locale: lang);
      await _advance(tester, h, 60);
      expect(h.pending, hasLength(1));
      expect(find.text(t['retrying']!), findsOneWidget);
      expect(
        find.text(t['tryNow']!),
        findsNothing,
      ); // no double retry from a tap
      h.pending.single.complete(_busy(slotReleased: true));
      await tester.pump();
      expect(find.text(t['still']!), findsOneWidget);
      expect(find.text('${t['manual']} ${t['released']}'), findsOneWidget);
      expect(find.byKey(const Key('aiBusyCountdown')), findsNothing);
      expect(find.byKey(const Key('aiBusyBar')), findsNothing);
      await _advance(tester, h, 180);
      expect(h.pending, hasLength(1), reason: 'never a second automat');
      await tester.tap(find.text(t['tryNow']!));
      await tester.pump();
      expect(h.pending, hasLength(2));
    });

    testWidgets(
      'D: deadline passed in the background -> paused text, no retry ($lang)',
      (tester) async {
        final h = await _pump(tester, _busy(slotReleased: true), locale: lang);
        await _advance(tester, h, 10);
        h.controller.setForeground(false);
        await _advance(tester, h, 55);
        expect(h.pending, isEmpty);
        h.controller.setForeground(true);
        await tester.pump();
        expect(h.controller.phase, AiBusyPhase.paused);
        expect(find.text(t['title']!), findsOneWidget);
        expect(find.text('${t['paused']} ${t['released']}'), findsOneWidget);
        expect(find.byKey(const Key('aiBusyCountdown')), findsNothing);
        await _advance(tester, h, 120);
        expect(h.pending, isEmpty);
      },
    );

    for (final v in {false: 'counted', null: 'unknown'}.entries) {
      testWidgets(
        'E: slotReleased ${v.key} -> no countdown, no automat ($lang)',
        (tester) async {
          final h = await _pump(
            tester,
            _busy(slotReleased: v.key),
            locale: lang,
          );
          expect(h.controller.phase, AiBusyPhase.noAuto);
          expect(find.text(t['title']!), findsOneWidget);
          expect(find.text('${t['manual']} ${t[v.value]}'), findsOneWidget);
          expect(find.byKey(const Key('aiBusyCountdown')), findsNothing);
          await _advance(tester, h, 180);
          expect(h.pending, isEmpty);
          await tester.tap(find.text(t['tryNow']!));
          await tester.pump();
          expect(h.pending, hasLength(1));
          // the quota sentence in B follows the LAST answer
          h.pending.single.complete(_busy(slotReleased: true));
          await tester.pump();
          expect(find.text('${t['manual']} ${t['released']}'), findsOneWidget);
        },
      );
    }

    testWidgets('retryAfterSec 120 -> "2 minutes" and 2:00 ($lang)', (
      tester,
    ) async {
      await _pump(tester, _busy(retryAfterSec: 120), locale: lang);
      expect(find.text('${t['auto2']} ${t['released']}'), findsOneWidget);
      expect(
        find.text(t['countdown']!.replaceFirst('1:00', '2:00')),
        findsOneWidget,
      );
    });
  }

  testWidgets(
    '"Try now" during the countdown replaces the automat (one call only)',
    (tester) async {
      final h = await _pump(tester, _busy());
      await _advance(tester, h, 10);
      await tester.tap(find.byKey(const Key('aiBusyTryNow')));
      await tester.pump();
      expect(h.pending, hasLength(1));
      expect(h.controller.autoUsed, isTrue);
      h.pending.single.complete(_busy());
      await tester.pump();
      expect(h.controller.phase, AiBusyPhase.manual);
      await _advance(tester, h, 120);
      expect(h.pending, hasLength(1));
    },
  );

  testWidgets('double tap on "Try now" starts one retry', (tester) async {
    final h = await _pump(tester, _busy(slotReleased: false));
    h.controller.tryNow();
    h.controller.tryNow();
    await tester.pump();
    expect(h.pending, hasLength(1));
  });

  testWidgets('"Back to the form" cancels the scheduled retry, no dialog', (
    tester,
  ) async {
    final h = await _pump(tester, _busy());
    await _advance(tester, h, 5);
    await tester.tap(find.byKey(const Key('aiBusyBack')));
    await tester.pump();
    expect(h.backs, 1);
    expect(find.byType(Dialog), findsNothing);
    await _advance(tester, h, 120);
    expect(h.pending, isEmpty);
  });

  testWidgets('system back in A behaves like "Back to the form"', (
    tester,
  ) async {
    final h = await _pump(tester, _busy());
    final popped = await tester.binding.handlePopRoute();
    await tester.pump();
    expect(popped, isTrue);
    expect(h.backs, 1);
    await _advance(tester, h, 120);
    expect(h.pending, isEmpty);
  });

  testWidgets(
    'retry success -> onSuccess; another error -> onFailure (EK-16)',
    (tester) async {
      final ok = await _pump(tester, _busy(slotReleased: false));
      ok.controller.tryNow();
      ok.pending.single.complete(null);
      await tester.pump();
      expect(ok.successes, 1);
      expect(ok.controller.phase, AiBusyPhase.done);

      final other = await _pump(tester, _busy());
      await _advance(tester, other, 60);
      other.pending.single.complete(
        const AppFailure(FailureKind.aiUnavailable, slotReleased: true),
      );
      await tester.pump();
      expect(other.failures.single.kind, FailureKind.aiUnavailable);
    },
  );

  testWidgets('a throwing retry ends as a generic failure, not a crash', (
    tester,
  ) async {
    final h = await _pump(tester, _busy(slotReleased: false));
    h.controller.tryNow();
    h.pending.single.completeError(StateError('boom'));
    await tester.pump();
    expect(h.failures.single.kind, FailureKind.generic);
  });

  testWidgets(
    'back from the background before the deadline: countdown continues, automat fires',
    (tester) async {
      final h = await _pump(tester, _busy());
      h.controller.setForeground(false);
      await _advance(tester, h, 20);
      h.controller.setForeground(true);
      await tester.pump();
      expect(find.text('Ponowna próba za 0:40'), findsOneWidget);
      await _advance(tester, h, 40);
      expect(h.pending, hasLength(1));
    },
  );

  testWidgets(
    'resume after the deadline with frozen timers -> D, never a late automat',
    (tester) async {
      final h = await _pump(tester, _busy());
      h.controller.setForeground(false);
      h.mono!.t += const Duration(
        seconds: 90,
      ); // the isolate was paused: no ticks
      h.controller.setForeground(true);
      await tester.pump(const Duration(seconds: 1));
      expect(h.controller.phase, AiBusyPhase.paused);
      expect(h.pending, isEmpty);
    },
  );

  testWidgets(
    'app lifecycle: paused at the deadline -> D (AppLifecycleListener)',
    (tester) async {
      final h = await _pump(tester, _busy());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await _advance(tester, h, 61);
      expect(h.controller.phase, AiBusyPhase.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(h.pending, isEmpty);
      expect(
        find.text('${_texts['pl']!['paused']} ${_texts['pl']!['released']}'),
        findsOneWidget,
      );
    },
  );

  testWidgets('polite announcements every 15 s: 45, 30, 15 (never 60 or 0)', (
    tester,
  ) async {
    final announced = <String>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      (message) async {
        final data = (message as Map)['data'] as Map;
        announced.add(data['message'] as String);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(
            SystemChannels.accessibility,
            null,
          ),
    );
    final h = await _pump(tester, _busy());
    await _advance(tester, h, 59);
    expect(announced, [
      _texts['pl']!['a11y45'],
      'Ponowna próba za 30 sekund',
      'Ponowna próba za 15 sekund',
    ]);
    await _advance(tester, h, 1);
    expect(announced.last, _texts['pl']!['retrying']);
  });

  testWidgets('text scale 200%: no overflow in A and B (pl, 360 dp)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    final h = await _pump(tester, _busy());
    expect(tester.takeException(), isNull);
    // content scrolls, the bottom button stays pinned (ek-07-ai-busy.md, 200%)
    expect(find.byKey(const Key('aiBusyBack')).hitTestable(), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('aiBusyTryNow')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('aiBusyTryNow')));
    await tester.pump();
    h.pending.single.complete(_busy());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
