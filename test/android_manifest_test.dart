import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards ADR-0005 / ADR-0007 / ADR-0008: permissions, backup, minSdk.
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml')
      .readAsStringSync();
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();

  test('only the allowed permissions are declared', () {
    final perms = RegExp(r'<uses-permission[^>]*android:name="([^"]+)"')
        .allMatches(manifest)
        .map((m) => m.group(1))
        .toSet();
    expect(perms, {'android.permission.INTERNET'});
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

  test('application id and flavors', () {
    expect(gradle, contains('applicationId = "pl.tadecode.tamitu"'));
    expect(gradle, contains('applicationIdSuffix = ".dev"'));
    expect(gradle, contains('create("prod")'));
  });
}
