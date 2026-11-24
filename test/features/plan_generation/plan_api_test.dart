import 'package:flutter_test/flutter_test.dart';
import 'package:tamitu/app/environment.dart';
import 'package:tamitu/core/errors/app_failure.dart';
import 'package:tamitu/features/plan_generation/data/fake_plan_api.dart';
import 'package:tamitu/features/plan_generation/domain/generated_plan.dart';
import 'package:tamitu/features/plan_generation/domain/trip_input.dart';

TripInput flightTrip({String? flightNumber = 'TP1234'}) => TripInput(
  destination: 'Lizbona',
  lodging: 'Baixa',
  days: 3,
  arrivalMode: ArrivalMode.flight,
  arrivalDate: const LocalDate(2027, 3, 2),
  arrivalTime: const LocalTime(8, 5),
  airport: 'LIS',
  flightNumber: flightNumber,
  interests: const [Interest.localFood, Interest.monumentsHistory],
  planLanguage: 'pl',
);

void main() {
  group('TripInput.toRequest', () {
    test('matches the contract and never sends the flight number', () {
      final body = flightTrip().toRequest(
        requestId: 'r1',
        apiVersion: 1,
        testData: true,
      );
      expect(body, {
        'apiVersion': 1,
        'requestId': 'r1',
        'planLanguage': 'pl',
        'trip': {
          'destination': 'Lizbona',
          'lodging': 'Baixa',
          'days': 3,
          'arrival': {
            'mode': 'flight',
            'date': '2027-03-02',
            'time': '08:05',
            'airport': 'LIS',
          },
        },
        'preferences': {
          'interests': ['local_food', 'monuments_history'],
          'budget': 'medium',
          'pace': 'moderate',
          'partySize': 2,
        },
        'testData': true,
      });
      expect(body.toString(), isNot(contains('TP1234')));
    });

    test('car arrival has no airport', () {
      const trip = TripInput(
        destination: 'Kraków',
        lodging: 'Kazimierz',
        days: 1,
        arrivalMode: ArrivalMode.car,
        arrivalDate: LocalDate(2027, 1, 1),
        arrivalTime: LocalTime(23, 59),
        airport: 'ignored',
        planLanguage: 'en',
      );
      final arrival =
          (trip.toRequest(
                    requestId: 'r',
                    apiVersion: 1,
                    testData: false,
                  )['trip']
                  as Map)['arrival']
              as Map;
      expect(arrival.containsKey('airport'), isFalse);
      expect(arrival['mode'], 'car');
    });
  });

  group('GeneratedPlan.fromJson', () {
    test('parses the contract example and sorts days', () {
      final plan = GeneratedPlan.fromJson({
        'apiVersion': 1,
        'requestId': 'r1',
        'language': 'pl',
        'promptVersion': 'plan-v1',
        'days': [
          {'dayNumber': 2, 'title': 'B', 'items': []},
          {
            'dayNumber': 1,
            'title': 'A',
            'items': [
              {
                'startTime': '21:30',
                'name': 'Time Out Market',
                'locality': 'Lizbona',
                'description': 'Kolacja.',
              },
            ],
          },
        ],
        'quota': {
          'limit': 5,
          'remainingToday': 3,
          'resetAt': '2026-11-16T23:00:00Z',
        },
      });
      expect(plan.days.map((d) => d.dayNumber), [1, 2]);
      expect(plan.days.first.items.single.name, 'Time Out Market');
      expect(plan.quota!.remainingToday, 3);
      expect(plan.quota!.resetAt, DateTime.utc(2026, 11, 16, 23));
    });

    test('rejects data outside the contract', () {
      expect(() => GeneratedPlan.fromJson(null), throwsFormatException);
      expect(
        () => GeneratedPlan.fromJson({'language': 'de', 'days': []}),
        throwsFormatException,
      );
      expect(
        () => GeneratedPlan.fromJson({
          'requestId': 'r',
          'language': 'pl',
          'days': [
            {'dayNumber': '1', 'title': 'A', 'items': []},
          ],
        }),
        throwsFormatException,
      );
    });

    test('missing quota is tolerated', () {
      final plan = GeneratedPlan.fromJson({
        'requestId': 'r',
        'language': 'en',
        'days': [
          {'dayNumber': 1, 'title': 'A', 'items': []},
        ],
      });
      expect(plan.quota, isNull);
    });
  });

  test('an answer for another requestId is rejected (review PR #164 #6)', () {
    final json = {
      'requestId': 'other',
      'language': 'pl',
      'days': [
        {'dayNumber': 1, 'title': 'A', 'items': []},
      ],
    };
    expect(
      () => parsePlanResponse(json, requestId: 'mine'),
      throwsFormatException,
    );
    expect(parsePlanResponse(json, requestId: 'other').requestId, 'other');
  });

  test('testData: always in dev, in prod only on request', () {
    expect(testDataFor(flavor: 'dev', requested: false), isTrue);
    expect(testDataFor(flavor: 'prod', requested: false), isFalse);
    expect(testDataFor(flavor: 'prod', requested: true), isTrue);
    expect(testDataFor(flavor: null, requested: false), isFalse);
  });

  test('FakePlanApi records ids and throws queued failures', () async {
    final api = FakePlanApi()
      ..failures.add(const AppFailure(FailureKind.aiUnavailable));
    await expectLater(
      api.generatePlan(flightTrip(), requestId: 'a'),
      throwsA(isA<AppFailure>()),
    );
    final plan = await api.generatePlan(flightTrip(), requestId: 'b');
    expect(api.requestIds, ['a', 'b']);
    expect(plan.days, hasLength(3));
  });
}
