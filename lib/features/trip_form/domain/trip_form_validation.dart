/// EK-05 validation (docs/ux/screens/ek-05.md, docs/data/model-danych.md pkt 1,
/// posrednik-api.md pkt 1-2). Pure, so it is unit-tested directly.
library;

import '../../plan_generation/domain/trip_input.dart';

/// Text field errors (CMP-04): required, too long, characters outside the allowed set.
enum TextFieldError { required, tooLong, chars }

/// Letters, digits, space and `, . - ' ( ) / &` (model-danych.md pkt 1, CMP-04).
final _allowed = RegExp(r"^[\p{L}\p{M}\p{N} ,.\-'()/&]+$", unicode: true);

/// Trims the value and collapses inner whitespace (the server cleans it the same way).
String cleanText(String value) => value.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Validates a cleaned text value. Empty optional fields are valid.
TextFieldError? validateText(
  String value, {
  required int max,
  bool required = true,
}) {
  final v = cleanText(value);
  if (v.isEmpty) return required ? TextFieldError.required : null;
  if (v.length > max) return TextFieldError.tooLong;
  if (!_allowed.hasMatch(v)) return TextFieldError.chars;
  return null;
}

/// Allowed arrival dates (EK-05, U10): from yesterday to today + 2 years, counted in the
/// device time zone (the server accepts "today - 2 days" in Europe/Warsaw, ADR-0011 pkt 3).
({LocalDate from, LocalDate to}) arrivalDateRange(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final from = today.subtract(const Duration(days: 1));
  final to = DateTime(today.year + 2, today.month, today.day);
  return (from: LocalDate.fromDateTime(from), to: LocalDate.fromDateTime(to));
}

bool dateInRange(LocalDate date, DateTime now) {
  final r = arrivalDateRange(now);
  return date.compareTo(r.from) >= 0 && date.compareTo(r.to) <= 0;
}

/// Field identifiers in visual order (focus goes to the first invalid one).
enum TripField {
  destination,
  lodging,
  days,
  arrivalMode,
  date,
  time,
  airport,
  flightNumber,
}

/// Maps `invalid_argument.details.field` (path without value) to a form field.
TripField? fieldFromApiPath(String? path) => switch (path) {
  'trip.destination' => TripField.destination,
  'trip.lodging' => TripField.lodging,
  'trip.days' => TripField.days,
  'trip.arrival.mode' => TripField.arrivalMode,
  'trip.arrival.date' => TripField.date,
  'trip.arrival.time' => TripField.time,
  'trip.arrival.airport' => TripField.airport,
  _ => null,
};
