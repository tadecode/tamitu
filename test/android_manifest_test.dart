import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards ADR-0005 / ADR-0007 / ADR-0008: permissions, backup, minSdk.
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml')
      .readAsStringSync();
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();

  test('only the allowed permissions are declared', () {
    final perms = RegExp(r'<uses-permission[^>]*android:name="([^"]+)"[^>]*>')
        .allMatches(manifest)
        .where((m) => !m.group(0)!.contains('tools:node="remove"'))
        .map((m) => m.group(1))
        .toSet();
    expect(perms, {'android.permission.INTERNET'});
  });

  test('library permissions are stripped from the merged manifest (P3-04)', () {
    for (final p in [
      'android.permission.ACCESS_NETWORK_STATE', // ADR-0011 pkt 2
      'android.permission.WAKE_LOCK',
      'android.permission.USE_BIOMETRIC',
      'android.permission.USE_FINGERPRINT',
      'com.google.android.c2dm.permission.RECEIVE',
      'com.google.android.providers.gsf.permission.READ_GSERVICES',
      'com.google.android.gms.permission.AD_ID',
    ]) {
      expect(
        manifest,
        contains('<uses-permission android:name="$p" tools:node="remove" />'),
        reason: p,
      );
    }
  });

  test('merged release manifest (when built) has only INTERNET', () {
    final dir = Directory('build/app/intermediates/merged_manifest');
    if (!dir.existsSync()) return; // no Android build in this run
    for (final f in dir.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('AndroidManifest.xml')) continue;
      final perms = RegExp(r'uses-permission[^>]*android:name="([^"]+)"')
          .allMatches(f.readAsStringSync())
          .map((m) => m.group(1)!)
          // androidx.core's own signature permission declared for the app itself.
          .where(
            (p) => !p.endsWith('.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION'),
          )
          .toSet();
      expect(perms, {'android.permission.INTERNET'}, reason: f.path);
    }
  });

  test('no location permissions', () {
    expect(manifest, isNot(contains('LOCATION')));
  });

  test('backup disabled and extraction rules set', () {
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:dataExtractionRules='));
    expect(manifest, contains('android:usesCleartextTraffic="false"'));
    final rules = File('android/app/src/main/res/xml/data_extraction_rules.xml')
        .readAsStringSync();
    expect(rules, contains('<cloud-backup>'));
    expect(rules, contains('<device-transfer>'));
  });

  test('minSdk is 26', () {
    expect(gradle, contains('minSdk = 26'));
  });

  // SEC-33/SEC-35: the missing-google-services flag is refused for release builds based on
  // the resolved task graph (covers `assemble`/`build`/`bundle`), not on command-line names.
  test('google-services flag is guarded on the task graph', () {
    expect(gradle, contains('tamitu.allowMissingGoogleServices'));
    expect(gradle, contains('gradle.taskGraph.whenReady'));
    expect(gradle, contains(r'Regex("process\\w*ReleaseGoogleServices")'));
    expect(gradle, isNot(contains('startParameter.taskNames')));
    expect(gradle, isNot(contains('System.getenv("CI")')));
  });

  test('application id and flavors', () {
    expect(gradle, contains('applicationId = "pl.tadecode.tamitu"'));
    expect(gradle, contains('applicationIdSuffix = ".dev"'));
    expect(gradle, contains('create("prod")'));
  });
}
