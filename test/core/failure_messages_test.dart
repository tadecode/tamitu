import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tamitu/core/errors/app_failure.dart';
import 'package:tamitu/core/errors/failure_messages.dart';
import 'package:tamitu/l10n/app_localizations.dart';

void main() {
  for (final lang in ['pl', 'en']) {
    test('EK-16 catalogue: every failure kind has a message ($lang)', () async {
      final l10n = await AppLocalizations.delegate.load(Locale(lang));
      for (final kind in FailureKind.values) {
        final m = failureMessage(
          l10n,
          AppFailure(kind, limit: 5, resetAt: DateTime.utc(2026, 11, 17, 23)),
          formatTime: (t) => '00:00',
        );
        expect(m.body.trim(), isNotEmpty, reason: kind.name);
        expect(m.body, isNot(contains(kind.name)), reason: 'no codes shown');
      }
    });
  }

  test('limit message uses the plural form and the local time', () async {
    final pl = await AppLocalizations.delegate.load(const Locale('pl'));
    final m = failureMessage(
      pl,
      AppFailure(
        FailureKind.limitExceeded,
        limit: 5,
        resetAt: DateTime.utc(2026, 11, 17, 23),
      ),
      formatTime: (t) => '00:00',
    );
    expect(m.title, pl.errorLimitTitle);
    expect(m.body, contains('5 planów dziennie'));
    expect(m.body, contains('od 00:00'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(
      en.errorLimitBody(1, '00:00'),
      startsWith('You can create 1 plan a day'),
    );
  });

  test(
    'offline (generic surface) = errorOffline*, session expiry = body only',
    () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final off = failureMessage(
        en,
        const AppFailure(FailureKind.offline),
        formatTime: (t) => '',
      );
      expect(off.title, "You're offline");
      final exp = failureMessage(
        en,
        const AppFailure(FailureKind.unauthenticated),
        formatTime: (t) => '',
      );
      expect(exp.title, isNull);
      expect(exp.body, en.errorSessionExpired);
    },
  );
}
