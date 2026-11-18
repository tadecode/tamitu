import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tamitu/app/environment.dart';
import 'package:tamitu/app/firebase_emulators.dart';

/// QA13: the Firebase emulator switch exists only in debug `dev` builds.
void main() {
  group('emulator switch rules', () {
    test('allowed only in a debug dev build', () {
      expect(firebaseEmulatorsAllowed(flavor: 'dev', debugMode: true), isTrue);
      expect(
        firebaseEmulatorsAllowed(flavor: 'dev', debugMode: false),
        isFalse,
      );
      expect(
        firebaseEmulatorsAllowed(flavor: 'prod', debugMode: true),
        isFalse,
      );
      expect(firebaseEmulatorsAllowed(flavor: null, debugMode: true), isFalse);
    });

    test('requested in prod or release -> StateError', () {
      for (final (flavor, debug) in [
        ('prod', true),
        ('prod', false),
        ('dev', false),
        (null, true),
      ]) {
        expect(
          () => assertFirebaseEmulatorsAllowed(
            requested: true,
            fakeBackendRequested: false,
            flavor: flavor,
            debugMode: debug,
          ),
          throwsStateError,
          reason: '$flavor debug=$debug',
        );
      }
    });

    test('not requested -> always fine; with the fake backend -> error', () {
      expect(
        () => assertFirebaseEmulatorsAllowed(
          requested: false,
          fakeBackendRequested: true,
          flavor: 'prod',
          debugMode: false,
        ),
        returnsNormally,
      );
      expect(
        () => assertFirebaseEmulatorsAllowed(
          requested: true,
          fakeBackendRequested: false,
          flavor: 'dev',
          debugMode: true,
        ),
        returnsNormally,
      );
      expect(
        () => assertFirebaseEmulatorsAllowed(
          requested: true,
          fakeBackendRequested: true,
          flavor: 'dev',
          debugMode: true,
        ),
        throwsStateError,
      );
    });

    test('the switch is off by default (tests run without dart-define)', () {
      expect(useFirebaseEmulators, isFalse);
    });
  });

  group('FirebaseEmulatorConfig', () {
    test('defaults: Android emulator host, ports of backend/firebase.json', () {
      final c = FirebaseEmulatorConfig.fromEnvironment();
      expect(c.host, '10.0.2.2');
      expect(c.projectId, 'demo-tamitu');
      final firebaseJson = File('backend/firebase.json').readAsStringSync();
      expect(firebaseJson, contains('"auth": { "port": ${c.authPort} }'));
      expect(
        firebaseJson,
        contains('"functions": { "port": ${c.functionsPort} }'),
      );
      expect(c.validate, returnsNormally);
    });

    test('only demo-* projects (never the real dev/prod project)', () {
      for (final p in ['tamitu-dev-tadecode', 'tamitu-prod-tadecode', '']) {
        expect(
          FirebaseEmulatorConfig(projectId: p).validate,
          throwsStateError,
          reason: p,
        );
      }
      expect(
        const FirebaseEmulatorConfig(projectId: 'demo-tamitu-qa').validate,
        returnsNormally,
      );
      expect(
        const FirebaseEmulatorConfig().firebaseOptions.projectId,
        'demo-tamitu',
      );
    });

    test('only local hosts', () {
      for (final h in ['10.0.2.2', '127.0.0.1', 'localhost']) {
        expect(FirebaseEmulatorConfig(host: h).validate, returnsNormally);
      }
      for (final h in ['192.168.1.10', 'example.com', '']) {
        expect(
          FirebaseEmulatorConfig(host: h).validate,
          throwsStateError,
          reason: h,
        );
      }
    });

    test('test subject is a plain identifier', () {
      expect(
        const FirebaseEmulatorConfig(testSub: 'qa-1').validate,
        returnsNormally,
      );
      expect(
        const FirebaseEmulatorConfig(testSub: 'a@b.pl').validate,
        throwsStateError,
      );
    });
  });

  group('wiring', () {
    final bootstrap = File('lib/app/bootstrap.dart').readAsStringSync();

    test('bootstrap guards the switch before using it', () {
      final guard = bootstrap.indexOf('assertFirebaseEmulatorsAllowed(');
      final use = bootstrap.indexOf('connectFirebaseEmulators(');
      expect(guard, greaterThan(0));
      expect(use, greaterThan(guard));
    });

    test('emulator wiring uses a named demo app and no App Check', () {
      final src = File('lib/app/firebase_emulators.dart').readAsStringSync();
      expect(src, contains('name: emulatorAppName'));
      expect(src, contains('useAuthEmulator('));
      expect(src, contains('useFunctionsEmulator('));
      expect(src, isNot(contains('FirebaseAppCheck')));
    });

    test('cleartext only in devDebug and only to local hosts', () {
      final manifest = File('android/app/src/devDebug/AndroidManifest.xml')
          .readAsStringSync();
      expect(manifest, contains('@xml/network_security_config_emulators'));
      final config = File(
        'android/app/src/devDebug/res/xml/network_security_config_emulators.xml',
      ).readAsStringSync();
      expect(
        config,
        contains('<base-config cleartextTrafficPermitted="false"'),
      );
      final domains = RegExp(r'<domain[^>]*>([^<]+)</domain>')
          .allMatches(config)
          .map((m) => m.group(1))
          .toSet();
      expect(domains, FirebaseEmulatorConfig.allowedHosts);
      for (final set in ['main', 'debug', 'profile', 'dev', 'prod']) {
        final dir = Directory('android/app/src/$set');
        if (!dir.existsSync()) continue;
        for (final f in dir.listSync(recursive: true).whereType<File>()) {
          if (!f.path.endsWith('.xml')) continue;
          expect(
            f.readAsStringSync(),
            isNot(contains('cleartextTrafficPermitted="true"')),
            reason: f.path,
          );
        }
      }
    });
  });
}
