import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/account_databases.dart';
import '../../plan_generation/domain/generated_plan.dart';
import '../../plan_generation/domain/trip_input.dart';
import '../domain/saved_plan.dart';

/// `trips`, `plan_days`, `plan_items` in the encrypted account database (schema v2,
/// docs/data/model-danych.md pkt 2.2). Errors are mapped to [PlanStorageException]
/// without their message (it could quote plan content).
class SqlitePlanRepository implements PlanRepository {
  SqlitePlanRepository(
    this._dbs, {
    required String Function() newId,
    DateTime Function()? now,
  }) : _newId = newId, // ignore: prefer_initializing_formals
       _now = now ?? DateTime.now;

  final AccountDatabases _dbs;
  final String Function() _newId;
  final DateTime Function() _now;

  @override
  Future<String> save(
    String uid,
    TripInput input,
    GeneratedPlan plan,
  ) => _guard(() async {
    final db = (await _dbs.open(uid)).db;
    final id = _newId();
    await db.transaction(() async {
      await db.customStatement(
        'INSERT INTO trips (id, created_at, destination, lodging, days_count, '
        'arrival_mode, arrival_date, arrival_time, airport, flight_number, '
        'interests, budget, pace, party_size, plan_language, prompt_version) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          id,
          _now().toUtc().millisecondsSinceEpoch,
          input.destination,
          input.lodging,
          input.days,
          input.arrivalMode.wire,
          input.arrivalDate.iso,
          input.arrivalTime.hhmm,
          input.arrivalMode == ArrivalMode.flight ? input.airport : null,
          input.flightNumber,
          jsonEncode([for (final i in input.interests) i.wire]),
          input.budget.wire,
          input.pace.wire,
          input.partySize,
          plan.language,
          plan.promptVersion ?? '',
        ],
      );
      for (final day in plan.days) {
        await db.customStatement(
          'INSERT INTO plan_days (trip_id, day_number, title) VALUES (?, ?, ?)',
          [id, day.dayNumber, day.title],
        );
        for (final (position, item) in day.items.indexed) {
          await db.customStatement(
            'INSERT INTO plan_items (trip_id, day_number, position, name, '
            'locality, description, start_time) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [
              id,
              day.dayNumber,
              position,
              item.name,
              item.locality,
              item.description,
              item.startTime,
            ],
          );
        }
      }
    });
    return id;
  });

  @override
  Future<List<SavedPlanSummary>> list(String uid) => _guard(() async {
    final db = (await _dbs.open(uid)).db;
    final rows = await db
        .customSelect(
          'SELECT id, destination, days_count, arrival_mode, created_at '
          'FROM trips ORDER BY created_at DESC, rowid DESC',
        )
        .get();
    return [
      for (final r in rows)
        SavedPlanSummary(
          id: r.read<String>('id'),
          destination: r.read<String>('destination'),
          daysCount: r.read<int>('days_count'),
          arrivalMode: _byWire(
            ArrivalMode.values,
            r.read<String>('arrival_mode'),
            (m) => m.wire,
          ),
          createdAt: _utc(r.read<int>('created_at')),
        ),
    ];
  });

  @override
  Future<SavedPlan?> load(String uid, String id) => _guard(() async {
    final db = (await _dbs.open(uid)).db;
    final trip = await db
        .customSelect(
          'SELECT * FROM trips WHERE id = ?',
          variables: [Variable.withString(id)],
        )
        .getSingleOrNull();
    if (trip == null) return null;
    final dayRows = await db
        .customSelect(
          'SELECT day_number, title FROM plan_days WHERE trip_id = ? '
          'ORDER BY day_number',
          variables: [Variable.withString(id)],
        )
        .get();
    final itemRows = await db
        .customSelect(
          'SELECT day_number, name, locality, description, start_time '
          'FROM plan_items WHERE trip_id = ? ORDER BY day_number, position',
          variables: [Variable.withString(id)],
        )
        .get();
    final items = <int, List<PlanItem>>{};
    for (final r in itemRows) {
      items
          .putIfAbsent(r.read<int>('day_number'), () => [])
          .add(
            PlanItem(
              startTime: r.read<String>('start_time'),
              name: r.read<String>('name'),
              locality: r.read<String>('locality'),
              description: r.read<String>('description'),
            ),
          );
    }
    final mode = _byWire(
      ArrivalMode.values,
      trip.read<String>('arrival_mode'),
      (m) => m.wire,
    );
    final interestWires = (jsonDecode(trip.read<String>('interests')) as List)
        .cast<String>();
    final input = TripInput(
      destination: trip.read<String>('destination'),
      lodging: trip.read<String>('lodging'),
      days: trip.read<int>('days_count'),
      arrivalMode: mode,
      arrivalDate: _date(trip.read<String>('arrival_date')),
      arrivalTime: _time(trip.read<String>('arrival_time')),
      airport: trip.readNullable<String>('airport'),
      flightNumber: trip.readNullable<String>('flight_number'),
      // Unknown ids (a later app version) are skipped, not an error.
      interests: [
        for (final w in interestWires)
          ?Interest.values.where((i) => i.wire == w).firstOrNull,
      ],
      budget: _byWire(
        Budget.values,
        trip.read<String>('budget'),
        (b) => b.wire,
      ),
      pace: _byWire(Pace.values, trip.read<String>('pace'), (p) => p.wire),
      partySize: trip.read<int>('party_size'),
      planLanguage: trip.read<String>('plan_language'),
    );
    final promptVersion = trip.read<String>('prompt_version');
    return SavedPlan(
      id: id,
      createdAt: _utc(trip.read<int>('created_at')),
      input: input,
      plan: GeneratedPlan(
        // The request id is not stored (one attempt only); the trip id stands in.
        requestId: id,
        language: input.planLanguage,
        promptVersion: promptVersion.isEmpty ? null : promptVersion,
        days: [
          for (final d in dayRows)
            PlanDay(
              dayNumber: d.read<int>('day_number'),
              title: d.read<String>('title'),
              items: List.unmodifiable(
                items[d.read<int>('day_number')] ?? const <PlanItem>[],
              ),
            ),
        ],
      ),
    );
  });

  @override
  Future<void> delete(String uid, String id) => _guard(() async {
    final db = (await _dbs.open(uid)).db;
    // Cascades to plan_days and plan_items (PRAGMA foreign_keys = ON at open).
    await db.customStatement('DELETE FROM trips WHERE id = ?', [id]);
  });

  static Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (_) {
      throw const PlanStorageException();
    }
  }

  static DateTime _utc(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

  static T _byWire<T>(List<T> values, String wire, String Function(T) of) =>
      values.firstWhere((v) => of(v) == wire);

  static LocalDate _date(String iso) {
    final p = iso.split('-').map(int.parse).toList();
    return LocalDate(p[0], p[1], p[2]);
  }

  static LocalTime _time(String hhmm) {
    final p = hhmm.split(':').map(int.parse).toList();
    return LocalTime(p[0], p[1]);
  }
}
