import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tamitu/app/environment.dart';

void main() {
  test('App Check: Play Integrity in prod (and unknown flavors), debug only in dev', () {
    expect(appCheckModeFor('prod'), AppCheckMode.playIntegrity);
    expect(appCheckModeFor(null), AppCheckMode.playIntegrity);
    expect(appCheckModeFor('staging'), AppCheckMode.playIntegrity);
    expect(appCheckModeFor('dev'), AppCheckMode.debug);
  });

  test('fake backend only in a non-release dev build (review PR #57 #3)', () {
    expect(fakeBackendAllowed(flavor: 'dev', releaseMode: false), isTrue);
    expect(fakeBackendAllowed(flavor: 'dev', releaseMode: true), isFalse);
    expect(fakeBackendAllowed(flavor: 'prod', releaseMode: false), isFalse);
    expect(fakeBackendAllowed(flavor: null, releaseMode: false), isFalse);
    expect(
      () => assertFakeBackendAllowed(
        requested: true,
        flavor: 'prod',
        releaseMode: true,
      ),
      throwsStateError,
    );
    expect(
      () => assertFakeBackendAllowed(
        requested: false,
        flavor: 'prod',
        releaseMode: true,
      ),
      returnsNormally,
    );
  });

  test('bootstrap activates App Check before creating the callable API', () {
    final src = File('lib/app/bootstrap.dart').readAsStringSync();
    final activate = src.indexOf('FirebaseAppCheck.instance.activate(');
    final callable = src.indexOf('CallableConsentApi(');
    expect(activate, greaterThan(0));
    expect(callable, greaterThan(activate));
    expect(src, contains('assertFakeBackendAllowed('));
    expect(src, isNot(contains('InMemoryConsentLocalStore')));
  });
}
