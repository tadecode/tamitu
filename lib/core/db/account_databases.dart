import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'account_database.dart';

/// Database key store (ADR-0005 pkt 1: one random 256-bit key per installation in
/// `flutter_secure_storage`, wrapped by Android Keystore).
abstract interface class DbKeyStore {
  /// Existing key, or null when none was created yet (or the Keystore lost it).
  Future<String?> read();
  Future<void> write(String hexKey);
}

class SecureStorageDbKeyStore implements DbKeyStore {
  SecureStorageDbKeyStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'accountDbKey';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } catch (_) {
      // Keystore entry invalidated: treated like a lost key (ADR-0005 Aneks A pkt 2).
      return null;
    }
  }

  @override
  Future<void> write(String hexKey) => _storage.write(key: _key, value: hexKey);
}

class MemoryDbKeyStore implements DbKeyStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String hexKey) async => value = hexKey;
}

/// An opened account database and whether it had to be recreated empty.
class AccountDbHandle {
  AccountDbHandle(this.db, {required this.wasReset});

  final AccountDatabase db;

  /// True when an unreadable file was deleted and an empty database created; reported
  /// once to the session gate (EK-03 "data reset" variant, ADR-0011 pkt 9).
  bool wasReset;
}

/// Opens (once per process) the encrypted database of each account.
class AccountDatabases {
  AccountDatabases({
    required Future<Directory> Function() directory,
    required DbKeyStore keys,
    this.requireCipher = true,
    Random? random,
  }) : _directory = directory, // ignore: prefer_initializing_formals
       _keys = keys, // ignore: prefer_initializing_formals
       _random = random ?? Random.secure();

  final Future<Directory> Function() _directory;
  final DbKeyStore _keys;
  final Random _random;
  final bool requireCipher;
  final _open = <String, Future<AccountDbHandle>>{};

  Future<AccountDbHandle> open(String uid) =>
      _open[uid] ??= _openFresh(uid).catchError((Object e) {
        _open.remove(uid);
        throw e;
      });

  Future<AccountDbHandle> _openFresh(String uid) async {
    final file = File('${(await _directory()).path}/${accountDbFileName(uid)}');
    var key = await _keys.read();
    if (key == null) {
      key = _newKey();
      await _keys.write(key);
    }
    final existed = await file.exists();
    try {
      final db = await openAccountDatabase(
        file,
        hexKey: key,
        requireCipher: requireCipher,
      );
      return AccountDbHandle(db, wasReset: false);
    } on UnreadableDatabase {
      // ADR-0005 Aneks A pkt 2: delete the unreadable file, start an empty database.
      await deleteDatabaseFiles(file);
      final db = await openAccountDatabase(
        file,
        hexKey: key,
        requireCipher: requireCipher,
      );
      return AccountDbHandle(db, wasReset: existed);
    }
  }

  String _newKey() => List.generate(
    32,
    (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  /// Closes every open database (sign-out, ADR-0004). Files stay on the device (N3).
  Future<void> closeAll() async {
    final handles = _open.values.toList();
    _open.clear();
    for (final h in handles) {
      try {
        await (await h).db.close();
      } catch (_) {
        // Already failed to open: nothing to close.
      }
    }
  }
}
