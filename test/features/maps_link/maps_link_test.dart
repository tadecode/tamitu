import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tamitu/features/maps_link/domain/maps_link.dart';
import 'package:tamitu/features/maps_link/presentation/route_sheet.dart';
import 'package:tamitu/features/plan_generation/domain/generated_plan.dart';

/// ADR-0017 pkt 1 and pkt 4: Google Maps directions link.
const _item = PlanItem(
  startTime: '15:00',
  name: 'Oceanário',
  locality: 'Parque das Nações',
  description: '-',
);
const _previous = PlanItem(
  startTime: '12:30',
  name: 'Tasca „Zé” & Filhos #2',
  locality: 'Alfama',
  description: '-',
);

RouteTarget _target({PlanItem? previous = _previous, String? lodging}) =>
    RouteTarget(
      item: _item,
      previous: previous,
      lodging: lodging,
      tripDestination: 'Lizbona',
      planLocale: const Locale('pl'),
    );

void main() {
  group('directionsUri', () {
    test('base form: https, www.google.com, /maps/dir/, api=1 first', () {
      final uri = directionsUri(destination: 'A', mode: TravelMode.walking);
      expect(uri.scheme, 'https');
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/dir/');
      expect(uri.query, startsWith('api=1&'));
      expect(
        uri.toString(),
        'https://www.google.com/maps/dir/?api=1&destination=A&travelmode=walking',
      );
    });

    test('no origin, null or blank origin → no `origin` key at all', () {
      for (final origin in [null, '', '   ']) {
        final uri = directionsUri(
          destination: 'A',
          mode: TravelMode.driving,
          origin: origin,
        );
        expect(uri.queryParameters.containsKey('origin'), isFalse);
        expect(uri.query, isNot(contains('origin')));
      }
    });

    test('special characters and Polish letters are percent-encoded', () {
      const tricky = 'Żółć & Gęś #1 | 100% (Łódź) ?x=y/z+ą';
      final uri = directionsUri(
        destination: tricky,
        mode: TravelMode.transit,
        origin: 'Śródmieście, Kraków & co.',
      );
      // Round trip: Maps receives exactly the text.
      expect(uri.queryParameters['destination'], tricky);
      expect(uri.queryParameters['origin'], 'Śródmieście, Kraków & co.');
      expect(uri.queryParameters['travelmode'], 'transit');
      expect(uri.queryParameters.keys, {
        'api',
        'destination',
        'travelmode',
        'origin',
      });
      // Nothing unencoded that could break the query or add a fragment.
      expect(uri.hasFragment, isFalse);
      final raw = uri.toString();
      for (final c in ['#', '|', ' ', '(', ')', 'Ż', 'ą']) {
        expect(raw.contains(c), isFalse, reason: 'raw "$c" in $raw');
      }
      expect(raw, contains('%C5%BB')); // Ż
      expect(raw, contains('%26')); // &
      expect(raw, contains('%23')); // #
      expect(raw, contains('%25')); // %
    });

    test('URL stays below 2048 characters for long Polish names', () {
      // Field limits: name 100, locality 80, trip destination 80 (ADR-0017).
      String fill(int n) =>
          ('Zamek Królewski na Wawelu i ogród ' * 10).substring(0, n);
      final place = placeQuery(fill(100), fill(80), fill(79));
      final uri = directionsUri(
        destination: place,
        mode: TravelMode.transit,
        origin: place,
      );
      expect(uri.toString().length, lessThan(2048));
    });
  });

  group('travel mode', () {
    test('parameter values', () {
      expect(TravelMode.driving.param, 'driving');
      expect(TravelMode.transit.param, 'transit');
      expect(TravelMode.walking.param, 'walking');
    });

    test('first use is Transit; stored values round-trip', () {
      expect(TravelMode.initial, TravelMode.transit);
      for (final m in TravelMode.values) {
        expect(TravelMode.fromParam(m.param), m);
      }
      expect(TravelMode.fromParam(null), isNull);
      expect(TravelMode.fromParam('bicycling'), isNull);
    });
  });

  group('place text', () {
    test('name, locality, trip destination', () {
      expect(
        placeQuery('Oceanário', 'Parque das Nações', 'Lizbona'),
        'Oceanário, Parque das Nações, Lizbona',
      );
    });

    test('blank parts, repeated parts and extra spaces are dropped', () {
      expect(
        placeQuery('  Zamek  Królewski ', 'Kraków', 'kraków'),
        'Zamek Królewski, Kraków',
      );
      expect(placeQuery('Muzeum', ' ', 'Gdańsk'), 'Muzeum, Gdańsk');
    });

    test('lodging: lodging, trip destination', () {
      expect(
        lodgingQuery('Pensjonat Przykładowy, Alfama', 'Lizbona'),
        'Pensjonat Przykładowy, Alfama, Lizbona',
      );
    });
  });

  group('three starts × three modes (EK-09)', () {
    final target = _target(lodging: 'Hotel „Złota Rybka” & Spa');
    const destination = 'Oceanário, Parque das Nações, Lizbona';
    final expectedOrigin = {
      RouteStartKind.myLocation: null,
      RouteStartKind.previousPlace: 'Tasca „Zé” & Filhos #2, Alfama, Lizbona',
      RouteStartKind.lodging: 'Hotel „Złota Rybka” & Spa, Lizbona',
    };

    for (final start in RouteStartKind.values) {
      for (final mode in TravelMode.values) {
        test('${start.name} × ${mode.name}', () {
          final uri = target.uriFor(start, mode);
          final q = uri.queryParameters;
          expect(q['api'], '1');
          expect(q['destination'], destination);
          expect(q['travelmode'], mode.param);
          final origin = expectedOrigin[start];
          if (origin == null) {
            expect(q.containsKey('origin'), isFalse);
          } else {
            expect(q['origin'], origin);
          }
          // Never coordinates (ADR-0017): no "lat,lng"-like values.
          final coords = RegExp(r'^-?\d+(\.\d+)?,\s*-?\d+(\.\d+)?$');
          expect(q['destination'], isNot(matches(coords)));
          if (q['origin'] != null) {
            expect(q['origin'], isNot(matches(coords)));
          }
        });
      }
    }
  });

  group('available starts', () {
    test('later item with lodging: all three, in order', () {
      expect(_target(lodging: 'Alfama').starts, [
        RouteStartKind.myLocation,
        RouteStartKind.previousPlace,
        RouteStartKind.lodging,
      ]);
    });

    test('first item of the day: no "Previous place"', () {
      expect(_target(previous: null, lodging: 'Alfama').starts, [
        RouteStartKind.myLocation,
        RouteStartKind.lodging,
      ]);
    });

    test(
      'no lodging (null or blank): no "Your stay", never an empty origin',
      () {
        for (final lodging in [null, '', '  ']) {
          final t = _target(lodging: lodging);
          expect(t.starts, [
            RouteStartKind.myLocation,
            RouteStartKind.previousPlace,
          ]);
        }
        expect(_target(previous: null).starts, [RouteStartKind.myLocation]);
      },
    );
  });
}
