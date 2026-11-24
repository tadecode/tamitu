/// Trip form data (EK-05) and its `generatePlan` request body (posrednik-api.md pkt 2).
///
/// The flight number is kept only locally (EK-05, D4/D5): [toRequest] never sends it.
library;

enum ArrivalMode {
  flight('flight'),
  car('car');

  const ArrivalMode(this.wire);
  final String wire;
}

enum Budget {
  low('low'),
  medium('medium'),
  high('high');

  const Budget(this.wire);
  final String wire;
}

enum Pace {
  relaxed('relaxed'),
  moderate('moderate'),
  intense('intense');

  const Pace(this.wire);
  final String wire;
}

/// Interest list (docs/data/model-danych.md, D15); order = order of the chips in EK-05.
enum Interest {
  monumentsHistory('monuments_history'),
  architecture('architecture'),
  artMuseums('art_museums'),
  natureParks('nature_parks'),
  beachesWater('beaches_water'),
  localFood('local_food'),
  activeSport('active_sport'),
  familyAttractions('family_attractions'),
  shopping('shopping'),
  nightlife('nightlife'),
  relaxation('relaxation');

  const Interest(this.wire);
  final String wire;
}

/// Limits shared by the form validation and the API contract.
abstract final class TripLimits {
  static const destinationMax = 80;
  static const lodgingMax = 80;
  static const airportMax = 60;
  static const flightNumberMax = 10;
  static const minDays = 1;
  static const maxDays = 14;
  static const maxInterests = 5;
  static const minPartySize = 1;
  static const maxPartySize = 10;
  static const defaultPartySize = 2;
}

/// A local calendar date (no time zone: local time at the destination, D5).
class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day);

  factory LocalDate.fromDateTime(DateTime t) =>
      LocalDate(t.year, t.month, t.day);

  final int year;
  final int month;
  final int day;

  DateTime toDateTime() => DateTime(year, month, day);

  /// `YYYY-MM-DD`.
  String get iso =>
      '${year.toString().padLeft(4, '0')}-${_two(month)}-${_two(day)}';

  @override
  int compareTo(LocalDate other) => iso.compareTo(other.iso);

  @override
  bool operator ==(Object other) => other is LocalDate && other.iso == iso;

  @override
  int get hashCode => iso.hashCode;

  @override
  String toString() => 'LocalDate($iso)';
}

/// A local time of day (`HH:MM`, 24 h).
class LocalTime {
  const LocalTime(this.hour, this.minute);

  final int hour;
  final int minute;

  String get hhmm => '${_two(hour)}:${_two(minute)}';

  @override
  bool operator ==(Object other) =>
      other is LocalTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => hour * 60 + minute;
}

String _two(int v) => v.toString().padLeft(2, '0');

/// Validated form data, ready to send. Built by the EK-05 form only after validation.
class TripInput {
  const TripInput({
    required this.destination,
    required this.lodging,
    required this.days,
    required this.arrivalMode,
    required this.arrivalDate,
    required this.arrivalTime,
    this.airport,
    this.flightNumber,
    this.interests = const [],
    this.budget = Budget.medium,
    this.pace = Pace.moderate,
    this.partySize = TripLimits.defaultPartySize,
    required this.planLanguage,
  });

  final String destination;
  final String lodging;
  final int days;
  final ArrivalMode arrivalMode;
  final LocalDate arrivalDate;
  final LocalTime arrivalTime;

  /// Required for [ArrivalMode.flight], null for [ArrivalMode.car].
  final String? airport;

  /// Local only: never sent to the server or the model.
  final String? flightNumber;
  final List<Interest> interests;
  final Budget budget;
  final Pace pace;
  final int partySize;

  /// `pl` or `en`.
  final String planLanguage;

  /// Request body for [requestId]. No UID, e-mail, location or flight number
  /// (posrednik-api.md pkt 1). Unknown fields are rejected by the server.
  Map<String, Object> toRequest({
    required String requestId,
    required int apiVersion,
    required bool testData,
  }) => {
    'apiVersion': apiVersion,
    'requestId': requestId,
    'planLanguage': planLanguage,
    'trip': {
      'destination': destination,
      'lodging': lodging,
      'days': days,
      'arrival': {
        'mode': arrivalMode.wire,
        'date': arrivalDate.iso,
        'time': arrivalTime.hhmm,
        if (arrivalMode == ArrivalMode.flight && airport != null)
          'airport': airport!,
      },
    },
    'preferences': {
      'interests': [for (final i in interests) i.wire],
      'budget': budget.wire,
      'pace': pace.wire,
      'partySize': partySize,
    },
    'testData': testData,
  };
}
