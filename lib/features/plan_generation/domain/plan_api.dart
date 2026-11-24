import 'generated_plan.dart';
import 'trip_input.dart';

/// `generatePlan` callable (posrednik-api.md pkt 2). Throws `AppFailure` (classified by
/// `classifyCallableError`); never retries on its own – the only automatic retry is the
/// single `ai_busy` one in EK-07 (posrednik-api.md pkt 6).
abstract interface class PlanApi {
  /// [requestId] is a new UUID v4 for every attempt (also for the `ai_busy` retry).
  Future<GeneratedPlan> generatePlan(
    TripInput input, {
    required String requestId,
  });
}
