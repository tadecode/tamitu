import 'dart:async';

import '../../../core/errors/app_failure.dart';
import '../domain/auth_gateway.dart';

/// In-memory stand-in used by tests and by the demo build
/// (`--dart-define=TAMITU_FAKE_BACKEND=true`) until the Firebase projects exist (P3-03).
class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({
    AuthUser? initialUser,
    this.nextUser = const AuthUser('demo-user'),
  }) : _user = initialUser;

  AuthUser? _user;

  /// Who signs in on the next successful [signInWithGoogle].
  AuthUser nextUser;

  /// When set, the next sign-in throws this failure instead (then resets).
  AppFailure? nextSignInFailure;

  /// Completes sign-in only when this completer completes (to test loading states).
  Completer<void>? signInGate;

  int signInCalls = 0;
  int signOutCalls = 0;

  final _controller = StreamController<AuthUser?>.broadcast();

  @override
  Stream<AuthUser?> sessionChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<AuthUser> signInWithGoogle() async {
    signInCalls++;
    final gate = signInGate;
    if (gate != null) await gate.future;
    final failure = nextSignInFailure;
    if (failure != null) {
      nextSignInFailure = null;
      throw failure;
    }
    _user = nextUser;
    _controller.add(_user);
    return nextUser;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _user = null;
    _controller.add(null);
  }

  Future<void> dispose() => _controller.close();
}
