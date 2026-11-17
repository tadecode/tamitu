import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../domain/consent_ports.dart';
import '../domain/consent_record.dart';

/// `recordConsent` through the Cloud Functions SDK (ID token and App Check token are
/// attached by the SDK). Region per posrednik-api.md.
class CallableConsentApi implements ConsentApi {
  CallableConsentApi(this._functions);

  static const region = 'europe-west4';
  static const _timeout = Duration(seconds: 30);

  final FirebaseFunctions _functions;

  @override
  Future<DateTime> recordConsent(ConsentRecord record) async {
    try {
      final result = await _functions
          .httpsCallable(
            'recordConsent',
            options: HttpsCallableOptions(timeout: _timeout),
          )
          .call<Map<String, dynamic>>(recordConsentRequest(record));
      final at = DateTime.tryParse('${result.data['receivedAt']}');
      if (at == null) throw const AppFailure(FailureKind.generic);
      return at.toUtc();
    } on FirebaseFunctionsException catch (e) {
      // Only code + details.code/known fields are used; message is ignored (SEC-29).
      throw classifyCallableError(code: e.code, details: e.details);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure(FailureKind.generic);
    }
  }
}

/// Request body (posrednik-api.md pkt 3). Contains no UID, e-mail or name.
Map<String, Object> recordConsentRequest(ConsentRecord r) => {
  'apiVersion': AppConstants.apiVersion,
  'consentId': r.id,
  'type': r.type.wire,
  'granted': r.granted,
  'policyVersion': r.policyVersion,
  'lang': r.lang,
  'clientAt': formatUtcSeconds(r.clientAt),
};

/// `YYYY-MM-DDTHH:MM:SSZ` (UTC, whole seconds).
String formatUtcSeconds(DateTime t) {
  final u = t.toUtc();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${u.year.toString().padLeft(4, '0')}-${two(u.month)}-${two(u.day)}'
      'T${two(u.hour)}:${two(u.minute)}:${two(u.second)}Z';
}
