import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../domain/generated_plan.dart';
import '../domain/plan_api.dart';
import '../domain/trip_input.dart';

/// `generatePlan` through the Cloud Functions SDK (same pattern as
/// `CallableConsentApi`): ID token and App Check token attached by the SDK, region per
/// posrednik-api.md, client timeout 120 s (EK-07). Only `code` and documented `details`
/// fields are used; messages, request and response content are never logged (SEC-29).
class CallablePlanApi implements PlanApi {
  CallablePlanApi(this._functions, {required this.testData});

  static const region = 'europe-west4';

  /// EK-07: client timeout 120 s (server budget 100 s, ADR-0016).
  static const timeout = Duration(seconds: 120);

  final FirebaseFunctions _functions;

  /// `testData` flag of every request (ADR-0011 pkt 6, environment.dart).
  final bool testData;

  @override
  Future<GeneratedPlan> generatePlan(
    TripInput input, {
    required String requestId,
  }) async {
    try {
      final result = await _functions
          .httpsCallable(
            'generatePlan',
            options: HttpsCallableOptions(timeout: timeout),
          )
          .call<Object?>(
            input.toRequest(
              requestId: requestId,
              apiVersion: AppConstants.apiVersion,
              testData: testData,
            ),
          );
      return parsePlanResponse(result.data, requestId: requestId);
    } on FirebaseFunctionsException catch (e) {
      throw classifyCallableError(code: e.code, details: e.details);
    } on AppFailure {
      rethrow;
    } catch (_) {
      // FormatException (contract mismatch) and anything unexpected.
      throw const AppFailure(FailureKind.generic);
    }
  }
}
