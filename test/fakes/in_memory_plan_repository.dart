import 'dart:async';

import 'package:tamitu/features/plan_generation/domain/generated_plan.dart';
import 'package:tamitu/features/plan_generation/domain/trip_input.dart';
import 'package:tamitu/features/plans/domain/saved_plan.dart';

/// [PlanRepository] in memory for widget tests (the SQLCipher one is tested in
/// test/features/plans/sqlite_plan_repository_test.dart).
class InMemoryPlanRepository implements PlanRepository {
  InMemoryPlanRepository({DateTime Function()? now})
    : _now = now ?? (() => DateTime.utc(2027, 5, 12, 9));

  final DateTime Function() _now;
  final _plans = <String, Map<String, SavedPlan>>{};
  var _ids = 0;

  /// Next calls of the given kind throw [PlanStorageException] while > 0.
  int failSave = 0;
  int failList = 0;
  int failLoad = 0;
  int failDelete = 0;

  /// When set, every call waits for it (loading states).
  Completer<void>? gate;

  Future<void> _wait() async {
    final g = gate;
    if (g != null) await g.future;
  }

  List<SavedPlan> plansOf(String uid) => [...?_plans[uid]?.values];

  @override
  Future<String> save(String uid, TripInput input, GeneratedPlan plan) async {
    await _wait();
    if (failSave > 0) {
      failSave--;
      throw const PlanStorageException();
    }
    final id = 'trip-${++_ids}';
    (_plans[uid] ??= {})[id] = SavedPlan(
      id: id,
      createdAt: _now().add(Duration(minutes: _ids)),
      input: input,
      plan: plan,
    );
    return id;
  }

  @override
  Future<List<SavedPlanSummary>> list(String uid) async {
    await _wait();
    if (failList > 0) {
      failList--;
      throw const PlanStorageException();
    }
    final all = plansOf(uid)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return [
      for (final p in all)
        SavedPlanSummary(
          id: p.id,
          destination: p.input.destination,
          daysCount: p.input.days,
          arrivalMode: p.input.arrivalMode,
          createdAt: p.createdAt,
        ),
    ];
  }

  @override
  Future<SavedPlan?> load(String uid, String id) async {
    await _wait();
    if (failLoad > 0) {
      failLoad--;
      throw const PlanStorageException();
    }
    return _plans[uid]?[id];
  }

  @override
  Future<void> delete(String uid, String id) async {
    await _wait();
    if (failDelete > 0) {
      failDelete--;
      throw const PlanStorageException();
    }
    _plans[uid]?.remove(id);
  }
}
