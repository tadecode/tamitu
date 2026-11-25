import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/maps_link.dart';

/// Stores the last travel mode chosen in EK-09 (UX11: one for the whole app, a local
/// setting, not personal data). The start is never stored.
abstract interface class TravelModeStore {
  Future<void> write(TravelMode mode);
}

class NoopTravelModeStore implements TravelModeStore {
  @override
  Future<void> write(TravelMode mode) async {}
}

final travelModeStoreProvider = Provider<TravelModeStore>(
  (ref) => NoopTravelModeStore(),
);

/// Mode saved at the previous run (read in bootstrap, before the first frame).
final initialTravelModeProvider = Provider<TravelMode?>((ref) => null);

/// Last used travel mode; [TravelMode.initial] until the user picks one.
class TravelModeController extends Notifier<TravelMode> {
  @override
  TravelMode build() =>
      ref.read(initialTravelModeProvider) ?? TravelMode.initial;

  void set(TravelMode mode) {
    if (mode == state) return;
    state = mode;
    ref.read(travelModeStoreProvider).write(mode).ignore();
  }
}

final travelModeProvider = NotifierProvider<TravelModeController, TravelMode>(
  TravelModeController.new,
);
