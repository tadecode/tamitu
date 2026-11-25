/// `generatePlan` 200 response (posrednik-api.md pkt 2,
/// `docs/api/schemas/generate-plan.response.schema.json`). Saved on the phone by
/// `PlanRepository` (P3-06, TAM-19).
library;

class PlanItem {
  const PlanItem({
    required this.startTime,
    required this.name,
    required this.locality,
    required this.description,
  });

  /// `HH:MM`, local time at the destination.
  final String startTime;
  final String name;
  final String locality;
  final String description;
}

class PlanDay {
  const PlanDay({
    required this.dayNumber,
    required this.title,
    required this.items,
  });

  final int dayNumber;
  final String title;
  final List<PlanItem> items;
}

class PlanQuota {
  const PlanQuota({
    required this.limit,
    required this.remainingToday,
    required this.resetAt,
  });

  final int limit;
  final int remainingToday;

  /// UTC.
  final DateTime resetAt;
}

class GeneratedPlan {
  const GeneratedPlan({
    required this.requestId,
    required this.language,
    required this.days,
    this.promptVersion,
    this.quota,
  });

  final String requestId;

  /// Prompt version from the server (`trips.prompt_version`, diagnostics only).
  final String? promptVersion;

  /// `pl` or `en` – language of the plan content (TalkBack locale in EK-08).
  final String language;
  final List<PlanDay> days;
  final PlanQuota? quota;

  /// Parses the callable result. Throws [FormatException] on anything outside the
  /// contract (the caller maps it to a generic failure; content is never logged).
  factory GeneratedPlan.fromJson(Object? json) {
    final m = _map(json);
    final language = m['language'];
    if (language != 'pl' && language != 'en') {
      throw const FormatException('language');
    }
    final rawDays = m['days'];
    if (rawDays is! List || rawDays.isEmpty) {
      throw const FormatException('days');
    }
    final days = <PlanDay>[];
    for (final d in rawDays) {
      final dm = _map(d);
      final items = dm['items'];
      if (items is! List) throw const FormatException('items');
      days.add(
        PlanDay(
          dayNumber: _int(dm['dayNumber']),
          title: _str(dm['title']),
          items: [
            for (final i in items)
              PlanItem(
                startTime: _str(_map(i)['startTime']),
                name: _str(_map(i)['name']),
                locality: _str(_map(i)['locality']),
                description: _str(_map(i)['description']),
              ),
          ],
        ),
      );
    }
    days.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    PlanQuota? quota;
    final q = m['quota'];
    if (q is Map) {
      final resetAt = DateTime.tryParse('${q['resetAt']}');
      final limit = q['limit'];
      final remaining = q['remainingToday'];
      if (resetAt != null && limit is int && remaining is int) {
        quota = PlanQuota(
          limit: limit,
          remainingToday: remaining,
          resetAt: resetAt.toUtc(),
        );
      }
    }
    return GeneratedPlan(
      requestId: _str(m['requestId']),
      language: language as String,
      days: List.unmodifiable(days),
      promptVersion: m['promptVersion'] is String
          ? m['promptVersion'] as String
          : null,
      quota: quota,
    );
  }
}

Map<Object?, Object?> _map(Object? v) =>
    v is Map ? v : throw const FormatException('object');

String _str(Object? v) =>
    v is String ? v : throw const FormatException('string');

int _int(Object? v) => v is int ? v : throw const FormatException('int');

/// Parses a `generatePlan` answer and rejects one for another attempt (review PR #164
/// #6: answers are matched by `requestId`, posrednik-api.md "Slot limitu").
GeneratedPlan parsePlanResponse(Object? json, {required String requestId}) {
  final plan = GeneratedPlan.fromJson(json);
  if (plan.requestId != requestId) {
    throw const FormatException('requestId');
  }
  return plan;
}
