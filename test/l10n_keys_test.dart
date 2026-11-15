import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _files = ['lib/l10n/app_pl.arb', 'lib/l10n/app_en.arb'];

Map<String, dynamic> _load(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Set<String> _keys(String path) =>
    _load(path).keys.where((k) => !k.startsWith('@')).toSet();

void main() {
  test('PL and EN ARB files have identical keys', () {
    final pl = _keys(_files[0]);
    final en = _keys(_files[1]);
    expect(pl, isNotEmpty);
    expect(en.difference(pl), isEmpty, reason: 'keys missing in PL');
    expect(pl.difference(en), isEmpty, reason: 'keys missing in EN');
  });

  test('no empty translations', () {
    for (final f in _files) {
      final map = _load(f);
      for (final e in map.entries.where((e) => !e.key.startsWith('@'))) {
        expect((e.value as String).trim(), isNotEmpty, reason: '$f ${e.key}');
      }
    }
  });
}
