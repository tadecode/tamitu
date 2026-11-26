import 'dart:io';

import 'package:drift/drift.dart'
    show CouldNotRollBackException, DriftWrappedException, Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamitu/core/db/account_database.dart';
import 'package:tamitu/core/db/account_databases.dart';
import 'package:tamitu/core/errors/app_failure.dart';
import 'package:tamitu/features/consent/data/sqlite_consent_local_store.dart';
import 'package:tamitu/features/consent/domain/consent_record.dart';
import 'package:tamitu/features/plan_generation/data/fake_plan_api.dart';
import 'package:tamitu/features/plan_generation/domain/generated_plan.dart';
import 'package:tamitu/features/plan_generation/domain/trip_input.dart';
import 'package:tamitu/features/plans/data/sqlite_plan_repository.dart';
import 'package:tamitu/features/plans/domain/saved_plan.dart';

/// Test-only key (not a secret), built at runtime (gitleaks).
final keyA = List.generate(
  32,
  (i) => (i + 1).toRadixString(16).padLeft(2, '0'),
).join();

ConsentRecord rec(String id) => ConsentRecord(
  id: id,
  type: ConsentType.privacyPolicy,
  granted: true,
  policyVersion: 'privacy-v1',
  lang: 'pl',
  clientAt: DateTime.utc(2026, 11, 17, 10),
  synced: false,
);

TripInput tripInput({
  String destination = 'Lizbona',
  int days = 3,
  ArrivalMode mode = ArrivalMode.flight,
  String? flightNumber = 'TP1234',
}) => TripInput(
  destination: destination,
  lodging: 'Alfama',
  days: days,
  arrivalMode: mode,
  arrivalDate: const LocalDate(2027, 5, 12),
  arrivalTime: const LocalTime(14, 5),
  airport: mode == ArrivalMode.flight ? 'LIS' : null,
  flightNumber: mode == ArrivalMode.flight ? flightNumber : null,
  interests: const [Interest.localFood, Interest.artMuseums],
  budget: Budget.high,
  pace: Pace.relaxed,
  partySize: 3,
  planLanguage: 'en',
);

GeneratedPlan planFor(TripInput input) {
  final sample = FakePlanApi.samplePlan(input, requestId: 'r1');
  return GeneratedPlan(
    requestId: sample.requestId,
    language: sample.language,
    days: sample.days,
    promptVersion: 'plan-v1',
  );
}

/// Opens [file] at schema v1 (as written by P3-04) to test the v1 -> v2 migration.
class _V1Database extends AccountDatabase {
  _V1Database(super.executor);

  @override
  int get schemaVersion => 1;
}

void main() {
  late Directory dir;
  late MemoryDbKeyStore keys;
  final opened = <AccountDatabases>[];
  var clock = DateTime.utc(2027, 5, 1, 10);
  var ids = 0;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('tamitu_plans_test');
    keys = MemoryDbKeyStore();
    clock = DateTime.utc(2027, 5, 1, 10);
    ids = 0;
  });
  tearDown(() async {
    for (final d in opened) {
      await d.closeAll();
    }
    opened.clear();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  AccountDatabases dbs() {
    final d = AccountDatabases(directory: () async => dir, keys: keys);
    opened.add(d);
    return d;
  }

  SqlitePlanRepository repo(AccountDatabases d) =>
      SqlitePlanRepository(d, newId: () => 'trip-${++ids}', now: () => clock);

  test(
    'save + load round trip keeps form data, days, items and order',
    () async {
      final r = repo(dbs());
      final input = tripInput();
      final id = await r.save('u1', input, planFor(input));

      final saved = (await r.load('u1', id))!;
      expect(saved.id, id);
      expect(saved.createdAt, clock);
      final i = saved.input;
      expect(i.destination, 'Lizbona');
      expect(i.lodging, 'Alfama');
      expect(i.days, 3);
      expect(i.arrivalMode, ArrivalMode.flight);
      expect(i.arrivalDate, const LocalDate(2027, 5, 12));
      expect(i.arrivalTime, const LocalTime(14, 5));
      expect(i.airport, 'LIS');
      expect(i.flightNumber, 'TP1234');
      expect(i.interests, [Interest.localFood, Interest.artMuseums]);
      expect(i.budget, Budget.high);
      expect(i.pace, Pace.relaxed);
      expect(i.partySize, 3);
      expect(i.planLanguage, 'en');
      final p = saved.plan;
      expect(p.language, 'en');
      expect(p.promptVersion, 'plan-v1');
      expect(p.days.map((d) => d.dayNumber), [1, 2, 3]);
      expect(p.days.first.items, isEmpty); // day 1 = arrival only
      expect(p.days[1].title, 'Day of exploring');
      expect(p.days[1].items.map((x) => x.startTime), [
        '09:30',
        '12:30',
        '16:00',
      ]);
      expect(p.days[1].items.map((x) => x.name), [
        'Place 1',
        'Place 2',
        'Place 3',
      ]);
      expect(p.days[2].items.first.locality, 'Lizbona');
    },
  );

  test('car trip stores no airport and no flight number', () async {
    final r = repo(dbs());
    final input = tripInput(mode: ArrivalMode.car);
    final id = await r.save('u1', input, planFor(input));
    final saved = (await r.load('u1', id))!;
    expect(saved.input.arrivalMode, ArrivalMode.car);
    expect(saved.input.airport, isNull);
    expect(saved.input.flightNumber, isNull);
  });

  test('list: newest first, summary fields (EK-04)', () async {
    final r = repo(dbs());
    final a = tripInput(destination: 'Lizbona', days: 4);
    await r.save('u1', a, planFor(a));
    clock = clock.add(const Duration(days: 1));
    final b = tripInput(destination: 'Porto', days: 2, mode: ArrivalMode.car);
    await r.save('u1', b, planFor(b));

    final list = await r.list('u1');
    expect(list.map((s) => s.destination), ['Porto', 'Lizbona']);
    expect(list.first.daysCount, 2);
    expect(list.first.arrivalMode, ArrivalMode.car);
    expect(list.first.createdAt, DateTime.utc(2027, 5, 2, 10));
    expect(list.last.daysCount, 4);
  });

  test('plans of one account are not visible to another (US-008)', () async {
    final r = repo(dbs());
    final input = tripInput();
    final id = await r.save('alice', input, planFor(input));
    expect(await r.list('bob'), isEmpty);
    expect(await r.load('bob', id), isNull);
    expect(await r.list('alice'), hasLength(1));
  });

  test(
    'delete removes the trip, its days and items (cascade, US-009)',
    () async {
      final d = dbs();
      final r = repo(d);
      final input = tripInput();
      final keep = await r.save('u1', input, planFor(input));
      final gone = await r.save('u1', input, planFor(input));

      await r.delete('u1', gone);

      expect(await r.load('u1', gone), isNull);
      expect((await r.list('u1')).map((s) => s.id), [keep]);
      final db = (await d.open('u1')).db;
      Future<int> count(String table) async =>
          (await db
                  .customSelect(
                    'SELECT count(*) AS n FROM $table WHERE trip_id = ?',
                    variables: [Variable.withString(gone)],
                  )
                  .getSingle())
              .read<int>('n');
      expect(await count('plan_days'), 0);
      expect(await count('plan_items'), 0);
      // The other plan is untouched.
      expect((await r.load('u1', keep))!.plan.days, hasLength(3));
      // Deleting a missing plan is a no-op.
      await r.delete('u1', gone);
    },
  );

  test('a failed save leaves no partial plan (one transaction, US-005)', () async {
    final r = repo(dbs());
    final input = tripInput();
    // Two days with the same number violate the plan_days primary key mid-save.
    final broken = GeneratedPlan(
      requestId: 'r',
      language: 'pl',
      days: const [
        PlanDay(dayNumber: 1, title: 'A', items: []),
        PlanDay(dayNumber: 1, title: 'B', items: []),
      ],
    );
    await expectLater(
      r.save('u1', input, broken),
      throwsA(isA<PlanStorageException>()),
    );
    expect(await r.list('u1'), isEmpty);
  });

  test(
    'a constraint error is "other", not out of storage (EK-08 v0.2)',
    () async {
      final r = repo(dbs());
      final broken = GeneratedPlan(
        requestId: 'r',
        language: 'pl',
        days: const [
          PlanDay(dayNumber: 1, title: 'A', items: []),
          PlanDay(dayNumber: 1, title: 'B', items: []),
        ],
      );
      await expectLater(
        r.save('u1', tripInput(), broken),
        throwsA(
          isA<PlanStorageException>().having(
            (e) => e.failure,
            'failure',
            PlanStorageFailure.other,
          ),
        ),
      );
    },
  );

  test(
    'full database: SQLITE_FULL is out of storage; retry after freeing space '
    '(EK-08 v0.2, TAM-113)',
    () async {
      final d = dbs();
      final r = repo(d);
      final db = (await d.open('u1')).db;
      // Simulate a full disk: the database may not grow past its current size.
      final pages = await db.customSelect('PRAGMA page_count').getSingle();
      final count = pages.data.values.first as int;
      await db.customStatement('PRAGMA max_page_count = $count');
      final input = tripInput(days: 7);
      final sample = FakePlanApi.samplePlan(input, requestId: 'r1');
      final big = GeneratedPlan(
        requestId: 'r1',
        language: 'pl',
        days: [
          for (final day in sample.days)
            PlanDay(
              dayNumber: day.dayNumber,
              title: day.title,
              items: [
                for (var i = 0; i < 8; i++)
                  PlanItem(
                    startTime: '10:00',
                    name: 'Miejsce $i',
                    locality: 'Lizbona',
                    description: 'x' * 300,
                  ),
              ],
            ),
        ],
      );
      await expectLater(
        r.save('u1', input, big),
        throwsA(
          isA<PlanStorageException>().having(
            (e) => e.failure,
            'failure',
            PlanStorageFailure.noSpace,
          ),
        ),
      );
      expect(await r.list('u1'), isEmpty); // no partial plan
      // "Free up some space and try again": the same save now succeeds.
      await db.customStatement('PRAGMA max_page_count = 1073741823');
      final id = await r.save('u1', input, big);
      expect((await r.load('u1', id))!.plan.days, hasLength(7));
    },
  );

  group('isOutOfStorage', () {
    SqliteException sqlite(int code) =>
        SqliteException(extendedResultCode: code, message: 'm');

    test('SQLITE_FULL and its extended codes', () {
      expect(isOutOfStorage(sqlite(13)), isTrue);
      expect(isOutOfStorage(sqlite(13 | (1 << 8))), isTrue);
    });

    test('ENOSPC from the file system', () {
      expect(
        isOutOfStorage(const FileSystemException('f', 'p', OSError('', 28))),
        isTrue,
      );
      expect(
        isOutOfStorage(const FileSystemException('f', 'p', OSError('', 13))),
        isFalse,
      );
      expect(isOutOfStorage(const FileSystemException('f')), isFalse);
    });

    test('unwraps drift wrappers', () {
      expect(
        isOutOfStorage(
          CouldNotRollBackException(sqlite(13), StackTrace.empty, sqlite(1)),
        ),
        isTrue,
      );
      expect(
        isOutOfStorage(DriftWrappedException(message: 'm', cause: sqlite(13))),
        isTrue,
      );
    });

    test('other errors are not out of storage', () {
      expect(isOutOfStorage(sqlite(10)), isFalse); // SQLITE_IOERR
      expect(isOutOfStorage(sqlite(19)), isFalse); // SQLITE_CONSTRAINT
      expect(isOutOfStorage(sqlite(26)), isFalse); // SQLITE_NOTADB
      expect(isOutOfStorage(StateError('x')), isFalse);
      expect(isOutOfStorage(null), isFalse);
    });
  });

  test('plans survive a restart (new process, same key)', () async {
    final input = tripInput();
    final first = dbs();
    final id = await repo(first).save('u1', input, planFor(input));
    await first.closeAll();

    final saved = await repo(dbs()).load('u1', id);
    expect(saved?.input.destination, 'Lizbona');
  });

  test('lost key: plans are gone, an empty database opens (ADR-0005 Aneks A pkt 2)', () async {
    final input = tripInput();
    final first = dbs();
    await repo(first).save('u1', input, planFor(input));
    await first.closeAll();
    keys.value = null; // Keystore lost the key

    final d = dbs();
    expect(await repo(d).list('u1'), isEmpty);
    expect(await SqliteConsentLocalStore(d).takeDataReset('u1'), isTrue);
  });

  test('plan content is not stored in plain text (SQLCipher)', () async {
    final d = dbs();
    final input = tripInput(destination: 'Plainmarkerville');
    await repo(d).save('u1', input, planFor(input));
    await d.closeAll();
    final bytes = await File('${dir.path}/${accountDbFileName('u1')}')
        .readAsBytes();
    expect(String.fromCharCodes(bytes), isNot(contains('Plainmarkerville')));
  });

  test('migration v1 -> v2 keeps consents and adds the plan tables', () async {
    final file = File('${dir.path}/${accountDbFileName('u1')}');
    keys.value = keyA;
    final v1 = _V1Database(
      NativeDatabase(
        file,
        setup: (raw) => raw.execute("PRAGMA key = \"x'$keyA'\""),
      ),
    );
    await v1.customSelect('SELECT 1').get(); // runs onCreate at v1
    await SqliteConsentLocalStore(_Single(v1)).upsert('u1', rec('c-1'));
    expect(
      (await v1.customSelect('PRAGMA user_version').getSingle())
          .data
          .values
          .first,
      1,
    );
    await v1.close();

    final d = dbs();
    final h = await d.open('u1');
    expect(h.wasReset, isFalse);
    expect((await SqliteConsentLocalStore(d).all('u1')).map((r) => r.id), [
      'c-1',
    ]);
    final meta = await h.db
        .customSelect('SELECT version FROM schema_meta')
        .getSingle();
    expect(meta.read<int>('version'), 2);
    final input = tripInput();
    final id = await repo(d).save('u1', input, planFor(input));
    expect(await repo(d).load('u1', id), isNotNull);
  });
}

/// Serves one already-open database (migration test helper).
class _Single implements AccountDatabases {
  _Single(this.db);

  final AccountDatabase db;

  @override
  Future<AccountDbHandle> open(String uid) async =>
      AccountDbHandle(db, wasReset: false);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
