import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/consent/presentation/ai_consent_screen.dart';
import '../features/consent/presentation/reconsent_screen.dart';
import '../features/consent/presentation/welcome_screen.dart';
import '../features/session/session_controller.dart';
import '../features/session/session_gate_screen.dart';
import 'home_screen.dart';

abstract final class Routes {
  static const start = '/start';
  static const welcome = '/welcome';
  static const reconsent = '/reconsent';
  static const home = '/home';

  /// EK-06; pushed by the plan flow (P3-05) with `extra: true` for the "updated" variant.
  /// Pops `true` when consent was saved.
  static const aiConsent = '/ai-consent';
}

/// Session gate redirects (EK-01). Pure, so it is unit-tested directly.
String? sessionRedirect(SessionStatus status, String location) {
  switch (status) {
    case SessionLoading():
      return location == Routes.start ? null : Routes.start;
    case SessionSignedOut():
      return location == Routes.welcome ? null : Routes.welcome;
    case SessionNeedsPolicy():
      return location == Routes.reconsent ? null : Routes.reconsent;
    case SessionReady():
      const gateRoutes = {Routes.start, Routes.welcome, Routes.reconsent};
      return gateRoutes.contains(location) ? Routes.home : null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: Routes.start,
    refreshListenable: refresh,
    redirect: (context, state) =>
        sessionRedirect(ref.read(sessionProvider), state.matchedLocation),
    routes: [
      GoRoute(path: Routes.start, builder: (_, _) => const SessionGateScreen()),
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(
        path: Routes.reconsent,
        builder: (context, _) {
          final status = ref.read(sessionProvider);
          if (status is! SessionNeedsPolicy) return const SessionGateScreen();
          return ReconsentScreen(
            uid: status.uid,
            dataReset: status.dataReset,
            // EK-14 (sign-out confirmation) is not ux-ready yet: signing out from the
            // blocking EK-03 is direct for now. "Delete account" arrives with P3-08.
            onSignOut: () => ref.read(sessionProvider.notifier).signOut(),
          );
        },
      ),
      GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: Routes.aiConsent,
        builder: (context, state) {
          final status = ref.read(sessionProvider);
          if (status is! SessionReady) return const SessionGateScreen();
          return AiConsentScreen(uid: status.uid, updated: state.extra == true);
        },
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
