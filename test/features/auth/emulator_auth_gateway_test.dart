import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamitu/core/errors/app_failure.dart';
import 'package:tamitu/features/auth/data/emulator_auth_gateway.dart';
import 'package:tamitu/features/auth/domain/auth_gateway.dart';

/// QA13: sign-in adapter for the Auth emulator.
void main() {
  test('fake Google ID token: subject + reserved example.com address', () {
    final claims =
        jsonDecode(emulatorGoogleIdToken('qa-1')) as Map<String, dynamic>;
    expect(claims, {
      'sub': 'qa-1',
      'email': 'qa-1@example.com',
      'email_verified': true,
    });
  });

  test(
    'signs in with a google.com credential carrying the fake token',
    () async {
      final auth = _FakeAuth();
      final gateway = EmulatorAuthGateway(auth, testSub: 'qa-7');
      final user = await gateway.signInWithGoogle();
      expect(user, const AuthUser('uid-qa-7'));
      final credential = auth.lastCredential! as OAuthCredential;
      expect(credential.providerId, 'google.com');
      expect(
        (jsonDecode(credential.idToken!) as Map<String, dynamic>)['sub'],
        'qa-7',
      );
      expect(gateway.currentUser, const AuthUser('uid-qa-7'));
    },
  );

  test('auth errors are classified, never surfaced', () async {
    final auth = _FakeAuth(
      error: FirebaseAuthException(
        code: 'network-request-failed',
        message: 'provider text',
      ),
    );
    final gateway = EmulatorAuthGateway(auth, testSub: 'qa-1');
    await expectLater(
      gateway.signInWithGoogle(),
      throwsA(
        isA<AppFailure>().having((f) => f.kind, 'kind', FailureKind.offline),
      ),
    );
  });

  test('sign-out clears the session', () async {
    final auth = _FakeAuth();
    final gateway = EmulatorAuthGateway(auth, testSub: 'qa-1');
    await gateway.signInWithGoogle();
    await gateway.signOut();
    expect(gateway.currentUser, isNull);
  });
}

class _FakeAuth implements FirebaseAuth {
  _FakeAuth({this.error});

  final FirebaseAuthException? error;
  AuthCredential? lastCredential;
  User? _user;

  @override
  User? get currentUser => _user;

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    lastCredential = credential;
    if (error != null) throw error!;
    final token = (credential as OAuthCredential).idToken!;
    final sub = (jsonDecode(token) as Map<String, dynamic>)['sub'];
    final user = _FakeUser('uid-$sub');
    _user = user;
    return _FakeUserCredential(user);
  }

  @override
  Future<void> signOut() async => _user = null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUser implements User {
  _FakeUser(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserCredential implements UserCredential {
  _FakeUserCredential(this.user);

  @override
  final User? user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
