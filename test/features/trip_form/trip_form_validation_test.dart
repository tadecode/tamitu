import 'package:flutter_test/flutter_test.dart';
import 'package:tamitu/features/plan_generation/domain/trip_input.dart';
import 'package:tamitu/features/trip_form/domain/trip_form_validation.dart';

void main() {
  group('validateText', () {
    test('required, length and allowed characters (model-danych.md pkt 1)', () {
      expect(validateText('  ', max: 80), TextFieldError.required);
      expect(validateText('', max: 10, required: false), isNull);
      expect(validateText('a' * 81, max: 80), TextFieldError.tooLong);
      expect(validateText('a' * 80, max: 80), isNull);
      expect(
        validateText("Łódź, ul. Św. Anny (3/5) & Co-op's", max: 80),
        isNull,
      );
      expect(validateText('Lisboa 🙂', max: 80), TextFieldError.chars);
      expect(validateText('a​b', max: 80), TextFieldError.chars);
      expect(validateText('<script>', max: 80), TextFieldError.chars);
    });

    test('cleanText trims and collapses whitespace', () {
      expect(cleanText('  Baixa \n  Rossio '), 'Baixa Rossio');
    });
  });

  group('arrival date range (from yesterday to +2 years)', () {
    final now = DateTime(2026, 11, 24, 15);

    test('bounds', () {
      final r = arrivalDateRange(now);
      expect(r.from, const LocalDate(2026, 11, 23));
      expect(r.to, const LocalDate(2028, 11, 24));
    });

    test('inside and outside', () {
      expect(dateInRange(const LocalDate(2026, 11, 23), now), isTrue);
      expect(dateInRange(const LocalDate(2026, 11, 22), now), isFalse);
      expect(dateInRange(const LocalDate(2028, 11, 24), now), isTrue);
      expect(dateInRange(const LocalDate(2028, 11, 25), now), isFalse);
    });
  });

  test('server field paths map to form fields', () {
    expect(fieldFromApiPath('trip.destination'), TripField.destination);
    expect(fieldFromApiPath('trip.arrival.airport'), TripField.airport);
    expect(fieldFromApiPath('preferences.interests'), isNull);
    expect(fieldFromApiPath(null), isNull);
  });
}
