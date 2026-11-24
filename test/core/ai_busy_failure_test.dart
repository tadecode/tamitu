// TAM-99: ai_busy mapping (posrednik-api.md v0.6, ADR-0016 pkt 10 and 14).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tamitu/core/errors/app_failure.dart';
import 'package:tamitu/core/errors/failure_messages.dart';
import 'package:tamitu/l10n/app_localizations.dart';

AppFailure _busy(Map<String, Object?> extra) => classifyCallableError(
  code: 'unavailable',
  details: {'code': 'ai_busy', ...extra},
);

void main() {
  test('ai_busy -> aiBusy with slotReleased and retryAfterSec', () {
    final f = _busy({'retryAfterSec': 60, 'slotReleased': true});
    expect(f.kind, FailureKind.aiBusy);
    expect(f.slotReleased, isTrue);
    expect(f.retryAfterSec, 60);
    expect(f.toString(), 'AppFailure(aiBusy)');
  });

  test('retryAfterSec accepted in 30-120 s, otherwise 60 s', () {
    int? sec(Object? v) => _busy({'retryAfterSec': v}).retryAfterSec;
    expect(sec(30), 30);
    expect(sec(120), 120);
    expect(sec(90), 90);
    for (final bad in [null, 29, 121, 0, -5, 60.5, '60', true]) {
      expect(sec(bad), 60, reason: '$bad');
    }
    expect(_busy({}).retryAfterSec, 60);
  });

  test('slotReleased only as a real bool; missing -> unknown (no automat in EK-07)', () {
    expect(_busy({'slotReleased': false}).slotReleased, isFalse);
    expect(_busy({}).slotReleased, isNull);
    expect(_busy({'slotReleased': 'true'}).slotReleased, isNull);
  });

  test(
    'other codes carry no retryAfterSec (server sends it only with ai_busy)',
    () {
      final f = classifyCallableError(
        code: 'unavailable',
        details: {'code': 'ai_unavailable', 'retryAfterSec': 60},
      );
      expect(f.kind, FailureKind.aiUnavailable);
      expect(f.retryAfterSec, isNull);
    },
  );

  for (final lang in ['pl', 'en']) {
    test(
      'generic-surface fallback is the manual variant + quota sentence ($lang)',
      () async {
        final l10n = await AppLocalizations.delegate.load(Locale(lang));
        for (final slot in [true, false, null]) {
          final m = failureMessage(
            l10n,
            AppFailure(
              FailureKind.aiBusy,
              slotReleased: slot,
              retryAfterSec: 60,
            ),
            formatTime: (_) => '',
          );
          expect(m.title, l10n.generationBusyTitle);
          expect(
            m.body,
            '${l10n.generationBusyBodyManual} ${busyQuotaSentence(l10n, slot)}',
          );
        }
        expect(busyQuotaSentence(l10n, true), l10n.generationBusyQuotaReleased);
        expect(busyQuotaSentence(l10n, false), l10n.generationBusyQuotaCounted);
        expect(busyQuotaSentence(l10n, null), l10n.generationBusyQuotaUnknown);
      },
    );
  }
}
