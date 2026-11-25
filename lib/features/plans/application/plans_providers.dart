import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/saved_plan.dart';

/// EK-04 list of the signed-in account, newest first. Invalidated after a save or a
/// delete; `ref.invalidate` is also the "Try again" of the error state. No automatic
/// retry: a read error shows CMP-18 and the user retries (EK-04 "Stany").
final savedPlansProvider = FutureProvider.autoDispose
    .family<List<SavedPlanSummary>, String>(
      (ref, uid) => ref.read(planRepositoryProvider).list(uid),
      retry: (_, _) => null,
    );
