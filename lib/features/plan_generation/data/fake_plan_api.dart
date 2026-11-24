import 'dart:async';

import '../../../core/errors/app_failure.dart';
import '../domain/generated_plan.dart';
import '../domain/plan_api.dart';
import '../domain/trip_input.dart';

/// Server double for tests and the demo build (`TAMITU_FAKE_BACKEND`). Builds a short,
/// deterministic plan from the form data; never calls a model.
class FakePlanApi implements PlanApi {
  FakePlanApi({this.delay = Duration.zero});

  /// Simulated generation time (demo build only).
  final Duration delay;

  /// Request ids of all calls (including failed ones), in order.
  final requestIds = <String>[];

  /// Inputs of all calls, in order.
  final inputs = <TripInput>[];

  /// Failures to throw on the next calls, in order.
  final failures = <AppFailure>[];

  /// When set, calls wait for it (to test loading states).
  Completer<void>? gate;

  int get calls => requestIds.length;

  @override
  Future<GeneratedPlan> generatePlan(
    TripInput input, {
    required String requestId,
  }) async {
    requestIds.add(requestId);
    inputs.add(input);
    final g = gate;
    if (g != null) await g.future;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (failures.isNotEmpty) throw failures.removeAt(0);
    return samplePlan(input, requestId: requestId);
  }

  /// Deterministic sample: day 1 = arrival only, other days three places.
  static GeneratedPlan samplePlan(
    TripInput input, {
    required String requestId,
  }) {
    final en = input.planLanguage == 'en';
    return GeneratedPlan(
      requestId: requestId,
      language: input.planLanguage,
      days: [
        for (var d = 1; d <= input.days; d++)
          PlanDay(
            dayNumber: d,
            title: d == 1
                ? (en ? 'Arrival' : 'Przyjazd')
                : (en ? 'Day of exploring' : 'Dzień zwiedzania'),
            items: d == 1
                ? const []
                : [
                    for (final (i, t) in const [
                      '09:30',
                      '12:30',
                      '16:00',
                    ].indexed)
                      PlanItem(
                        startTime: t,
                        name: en ? 'Place ${i + 1}' : 'Miejsce ${i + 1}',
                        locality: input.destination,
                        description: en
                            ? 'Sample description (demo).'
                            : 'Przykładowy opis (demo).',
                      ),
                  ],
          ),
      ],
      quota: PlanQuota(
        limit: 5,
        remainingToday: 4,
        resetAt: DateTime.utc(2026, 11, 25, 23),
      ),
    );
  }
}
