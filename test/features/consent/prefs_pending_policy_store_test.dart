import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tamitu/features/consent/data/prefs_pending_policy_store.dart';
import 'package:tamitu/features/consent/domain/consent_record.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('write / read / clear round trip (no UID stored)', () async {
    final prefs = SharedPreferencesAsync();
    final store = PrefsPendingPolicyStore(prefs);
    expect(await store.read(), isNull);
    await store.write(
      PendingPolicyAcceptance(
        consentId: '0d8f1c1e-33b8-4a3e-bf4a-0a3d8c1f9e22',
        version: 'privacy-v1',
        lang: 'en',
        acceptedAt: DateTime.utc(2026, 11, 17, 10, 0, 1),
      ),
    );
    final raw = await prefs.getString(PrefsPendingPolicyStore.key);
    expect(raw, isNotNull);
    expect(
      raw!.split('"').where((s) => s.isNotEmpty && s != ':' && s != ','),
      containsAll(['consentId', 'version', 'lang', 'acceptedAt']),
    );
    expect(raw, isNot(contains('uid')));
    final back = await store.read();
    expect(back?.consentId, '0d8f1c1e-33b8-4a3e-bf4a-0a3d8c1f9e22');
    expect(back?.version, 'privacy-v1');
    expect(back?.lang, 'en');
    expect(back?.acceptedAt, DateTime.utc(2026, 11, 17, 10, 0, 1));
    await store.clear();
    expect(await store.read(), isNull);
  });

  test('a corrupt entry is dropped, not treated as an acceptance', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString(PrefsPendingPolicyStore.key, '{broken');
    final store = PrefsPendingPolicyStore(prefs);
    expect(await store.read(), isNull);
    expect(await prefs.getString(PrefsPendingPolicyStore.key), isNull);
  });
}
