import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tamitu/core/config/app_constants.dart';
import 'package:tamitu/core/errors/app_failure.dart';
import 'package:tamitu/features/consent/data/callable_consent_api.dart';
import 'package:tamitu/features/consent/domain/consent_record.dart';

/// Keys whose text is part of the consent shown to the user (ADR-0006 Aneks A pkt 1).
const policyKeys = ['consentPolicyCheckbox', 'consentPolicyLink'];
const aiConsentKeys = [
  'aiConsentTitle',
  'aiConsentIntro',
  'aiConsentSendTitle',
  'aiConsentSendList',
  'aiConsentNotSendTitle',
  'aiConsentNotSendList',
  'aiConsentRecipientTitle',
  'aiConsentRecipient',
  'aiConsentErrors',
  'aiConsentSensitive',
  'aiConsentWithdraw',
  'aiConsentController',
  'aiConsentPolicy',
  'aiConsentPolicyLink',
  'aiConsentAgree',
  'aiConsentDisagree',
];

/// Pinned fingerprints per version. Changing a consent text in PL or EN without a new
/// version (AppConstants) fails here; with a new version add its fingerprint.
const pinned = {
  'privacy-v1': 'ee5c09ea4f961f88',
  'ai-consent-v1': 'f7fb92f82db6dc35',
};

Map<String, dynamic> _arb(String lang) =>
    jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
        as Map<String, dynamic>;

/// FNV-1a 64-bit over "key=value\n" for PL then EN (stable, no extra dependency).
String fingerprint(List<String> keys) {
  var h = BigInt.parse('cbf29ce484222325', radix: 16);
  final prime = BigInt.parse('100000001b3', radix: 16);
  final mask = (BigInt.one << 64) - BigInt.one;
  for (final lang in ['pl', 'en']) {
    final arb = _arb(lang);
    for (final k in keys) {
      for (final byte in utf8.encode('$lang.$k=${arb[k]}\n')) {
        h = ((h ^ BigInt.from(byte)) * prime) & mask;
      }
    }
  }
  return h.toRadixString(16).padLeft(16, '0');
}

Iterable<File> _dartFiles(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where(
      (f) => f.path.endsWith('.dart') && !f.path.contains('app_localizations'),
    );

void main() {
  test(
    'consent texts are pinned to their versions (ADR-0006 Aneks A pkt 1)',
    () {
      expect(
        fingerprint(policyKeys),
        pinned[AppConstants.privacyPolicyVersion],
        reason: 'Policy acceptance text changed: bump privacyPolicyVersion (and the server list).',
      );
      expect(
        fingerprint(aiConsentKeys),
        pinned[AppConstants.aiConsentVersion],
        reason: 'AI consent text changed: bump aiConsentVersion (and the server list).',
      );
    },
  );

  test('app versions are well-formed and known to the server list', () {
    expect(AppConstants.versionNumber(AppConstants.privacyPolicyVersion), 1);
    expect(AppConstants.versionNumber(AppConstants.aiConsentVersion), 1);
    final server = File('backend/functions/src/consents.ts').readAsStringSync();
    expect(server, contains('"${AppConstants.privacyPolicyVersion}"'));
    expect(server, contains('"${AppConstants.aiConsentVersion}"'));
  });

  test('no logging in lib/ (SEC-29: no content or error details in logs)', () {
    final banned = RegExp(
      r'\b(print|debugPrint)\s*\(|dart:developer|\blog\s*\(',
    );
    for (final f in _dartFiles('lib')) {
      expect(banned.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
    }
  });

  test('only AppIcon imports hugeicons (ADR-0010 pkt 2)', () {
    for (final f in _dartFiles('lib')) {
      final uses = f.readAsStringSync().contains('package:hugeicons/');
      expect(
        uses,
        f.path.replaceAll(r'\', '/').endsWith('lib/core/ui/app_icon.dart'),
        reason: f.path,
      );
    }
  });

  test(
    'recordConsent request: contract fields only, no UID/e-mail, UTC seconds',
    () {
      final body = recordConsentRequest(
        ConsentRecord(
          id: '0d8f1c1e-33b8-4a3e-bf4a-0a3d8c1f9e22',
          type: ConsentType.aiProcessing,
          granted: true,
          policyVersion: 'ai-consent-v1',
          lang: 'pl',
          clientAt: DateTime.utc(2026, 11, 15, 10, 12, 3, 456),
        ),
      );
      expect(body, {
        'apiVersion': 1,
        'consentId': '0d8f1c1e-33b8-4a3e-bf4a-0a3d8c1f9e22',
        'type': 'ai_processing',
        'granted': true,
        'policyVersion': 'ai-consent-v1',
        'lang': 'pl',
        'clientAt': '2026-11-15T10:12:03Z',
      });
    },
  );
}
