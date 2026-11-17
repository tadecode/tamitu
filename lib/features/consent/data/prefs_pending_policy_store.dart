import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/consent_ports.dart';
import '../domain/consent_record.dart';

/// `shared_preferences` entry for the pre-login policy acceptance
/// (`version`, `lang`, `acceptedAt`, `consentId`; model-danych.md pkt 2.1). No UID.
class PrefsPendingPolicyStore implements PendingPolicyStore {
  PrefsPendingPolicyStore(this._prefs);

  static const key = 'pendingPolicyAcceptance';

  final SharedPreferencesAsync _prefs;

  @override
  Future<PendingPolicyAcceptance?> read() async {
    final raw = await _prefs.getString(key);
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return PendingPolicyAcceptance(
        consentId: m['consentId'] as String,
        version: m['version'] as String,
        lang: m['lang'] as String,
        acceptedAt: DateTime.parse(m['acceptedAt'] as String).toUtc(),
      );
    } catch (_) {
      // A corrupt entry is not a valid acceptance: drop it.
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(PendingPolicyAcceptance value) => _prefs.setString(
    key,
    jsonEncode({
      'consentId': value.consentId,
      'version': value.version,
      'lang': value.lang,
      'acceptedAt': value.acceptedAt.toUtc().toIso8601String(),
    }),
  );

  @override
  Future<void> clear() => _prefs.remove(key);
}

/// Test/demo double.
class MemoryPendingPolicyStore implements PendingPolicyStore {
  PendingPolicyAcceptance? value;

  @override
  Future<PendingPolicyAcceptance?> read() async => value;

  @override
  Future<void> write(PendingPolicyAcceptance v) async => value = v;

  @override
  Future<void> clear() async => value = null;
}
