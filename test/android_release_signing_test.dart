import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards ADR-0019 / TAM-119 (REL-MD-1): prodRelease is signed only with the
/// owner's upload key, read from outside the repository; never the debug key.
void main() {
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();

  String block(String start) {
    final i = gradle.indexOf(start);
    expect(i, isNot(-1), reason: 'missing block: $start');
    var depth = 0;
    for (var j = gradle.indexOf('{', i); j < gradle.length; j++) {
      if (gradle[j] == '{') depth++;
      if (gradle[j] == '}' && --depth == 0) return gradle.substring(i, j + 1);
    }
    fail('unbalanced block: $start');
  }

  test(
    'release build type has no signing config (debug key not inherited)',
    () {
      final release = block('buildTypes {');
      expect(release, contains('signingConfig = null'));
      expect(release, isNot(contains('getByName("debug")')));
    },
  );

  test('prod flavor uses only the upload signing config', () {
    final prod = block('create("prod")');
    expect(
      prod,
      contains('signingConfig = signingConfigs.findByName("upload")'),
    );
    expect(prod, isNot(contains('"debug"')));
  });

  test('upload values come from Gradle properties or environment only', () {
    for (final name in [
      'tamitu.upload.storeFile',
      'tamitu.upload.storePassword',
      'tamitu.upload.keyAlias',
      'tamitu.upload.keyPassword',
      'TAMITU_UPLOAD_STORE_FILE',
      'TAMITU_UPLOAD_STORE_PASSWORD',
      'TAMITU_UPLOAD_KEY_ALIAS',
      'TAMITU_UPLOAD_KEY_PASSWORD',
    ]) {
      expect(gradle, contains('"$name"'), reason: name);
    }
    final upload = block('create("upload")');
    // Only variables, no literal values in the repository.
    expect(upload, isNot(matches(RegExp(r'(Password|Alias)\s*=\s*"'))));
    expect(upload, isNot(matches(RegExp(r'storeFile\s*=\s*file\("'))));
  });

  test('missing config fails a prodRelease build (task-graph check)', () {
    expect(gradle, contains('(assemble|bundle|package|sign)ProdRelease'));
    expect(gradle, contains('"prodRelease must be signed with the upload key'));
  });

  test('signing files are git-ignored', () {
    final ignore = File('.gitignore').readAsStringSync();
    for (final p in [
      '*.jks',
      '*.keystore',
      'key.properties',
      '**/google-services.json',
    ]) {
      expect(ignore.split('\n').map((l) => l.trim()), contains(p), reason: p);
    }
  });
}
