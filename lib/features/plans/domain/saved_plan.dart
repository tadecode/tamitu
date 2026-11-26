/// Plans saved on the phone (P3-06, TAM-19; US-008, US-009). Data stays in the encrypted
/// account database only (ADR-0005, docs/data/model-danych.md pkt 2.2).
library;

import '../../plan_generation/domain/generated_plan.dart';
import '../../plan_generation/domain/trip_input.dart';

/// One card on EK-04.
class SavedPlanSummary {
  const SavedPlanSummary({
    required this.id,
    required this.destination,
    required this.daysCount,
    required this.arrivalMode,
    required this.createdAt,
  });

  final String id;
  final String destination;
  final int daysCount;
  final ArrivalMode arrivalMode;

  /// UTC.
  final DateTime createdAt;
}

/// A saved plan opened in EK-08: the form data and the plan content.
class SavedPlan {
  const SavedPlan({
    required this.id,
    required this.createdAt,
    required this.input,
    required this.plan,
  });

  final String id;

  /// UTC.
  final DateTime createdAt;
  final TripInput input;
  final GeneratedPlan plan;
}

/// Why the account database could not be written (EK-08 v0.2 "Plan nie jest zapisany":
/// only the cause that changes the advice for the user is told apart).
enum PlanStorageFailure {
  /// The phone is out of storage (SQLITE_FULL, ENOSPC): `planNotSavedStorageBody`.
  noSpace,

  /// Any other failure: `planNotSavedBody`.
  other,
}

/// Read or write failure of the account database (EK-04 / EK-08 / EK-11 error states).
/// Carries no plan content (nothing personal reaches logs).
class PlanStorageException implements Exception {
  const PlanStorageException([this.failure = PlanStorageFailure.other]);

  final PlanStorageFailure failure;

  @override
  String toString() => 'PlanStorageException(${failure.name})';
}

/// Saved plans of one account. Every method throws [PlanStorageException] when the
/// database cannot be read or written.
abstract interface class PlanRepository {
  /// Saves [input] and [plan] in one transaction (US-005: never a partial plan) and
  /// returns the new trip id.
  Future<String> save(String uid, TripInput input, GeneratedPlan plan);

  /// All plans of [uid], newest first (EK-04).
  Future<List<SavedPlanSummary>> list(String uid);

  /// The plan [id] of [uid], or null when it does not exist (deleted, other account).
  Future<SavedPlan?> load(String uid, String id);

  /// Deletes the plan [id] with its days and items (US-009). No-op when missing.
  Future<void> delete(String uid, String id);
}
