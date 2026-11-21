// TAM-94: the EK-16 message for ai_unavailable / ai_invalid_response follows
// details.slotReleased (posrednik-api.md v0.5 pkt 6). Expected texts are copied from the
// owner-approved table in .farm/log/2026-11-21/0948-architect-TAM-93.md (no changes allowed).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tamitu/core/errors/app_failure.dart';
import 'package:tamitu/core/errors/failure_messages.dart';
import 'package:tamitu/core/ui/app_icon.dart';
import 'package:tamitu/core/ui/components.dart';
import 'package:tamitu/l10n/app_localizations.dart';

import '../helpers.dart';

/// slotReleased value in details -> variant name; `absent` = field missing.
const _variants = <String, Map<String, Object?>>{
  'released': {'slotReleased': true},
  'counted': {'slotReleased': false},
  'absent': {},
};

const _expected = <String, Map<String, Map<String, String>>>{
  'pl': {
    'ai_unavailable': {
      'released': 'Usługa AI jest chwilowo niedostępna. Ta próba nie wlicza się do dzisiejszego limitu. Spróbuj ponownie za chwilę.',
      'counted': 'Usługa AI jest chwilowo niedostępna. Ta próba została wliczona do dzisiejszego limitu, bo nieudane próby zwracamy najwyżej 2 razy dziennie. Spróbuj ponownie później.',
      'absent': 'Usługa AI jest chwilowo niedostępna. Ta próba mogła zostać wliczona do dzisiejszego limitu. Spróbuj ponownie za chwilę.',
    },
    'ai_invalid_response': {
      'released': 'AI zwróciło niepełny plan, więc go nie zapisaliśmy. Ta próba nie wlicza się do dzisiejszego limitu. Spróbuj ponownie.',
      'counted': 'AI zwróciło niepełny plan, więc go nie zapisaliśmy. Ta próba została wliczona do dzisiejszego limitu, bo nieudane próby zwracamy najwyżej 2 razy dziennie.',
      'absent': 'AI zwróciło niepełny plan, więc go nie zapisaliśmy. Ta próba mogła zostać wliczona do dzisiejszego limitu. Spróbuj ponownie.',
    },
  },
  'en': {
    'ai_unavailable': {
      'released': "The AI service is temporarily unavailable. This attempt doesn't count towards today's limit. Please try again shortly.",
      'counted': "The AI service is temporarily unavailable. This attempt counted towards today's limit, because we give back failed attempts at most twice a day. Please try again later.",
      'absent': "The AI service is temporarily unavailable. This attempt may have counted towards today's limit. Please try again shortly.",
    },
    'ai_invalid_response': {
      'released': "The AI returned an incomplete plan, so we didn't save it. This attempt doesn't count towards today's limit. Please try again.",
      'counted': "The AI returned an incomplete plan, so we didn't save it. This attempt counted towards today's limit, because we give back failed attempts at most twice a day.",
      'absent': "The AI returned an incomplete plan, so we didn't save it. This attempt may have counted towards today's limit. Please try again.",
    },
  },
};

/// CMP-18 error state built from a callable error, as a generation screen will show it.
class _ErrorHost extends StatelessWidget {
  const _ErrorHost(this.failure);

  final AppFailure failure;

  @override
  Widget build(BuildContext context) {
    final m = failureMessage(
      AppLocalizations.of(context)!,
      failure,
      formatTime: (t) => '00:00',
    );
    return Scaffold(
      body: StateView(icon: AppIcons.error, title: m.title ?? '', body: m.body),
    );
  }
}

void main() {
  for (final lang in languages) {
    for (final code in ['ai_unavailable', 'ai_invalid_response']) {
      for (final v in _variants.entries) {
        testWidgets('$code, slotReleased ${v.key} -> approved text ($lang)', (
          tester,
        ) async {
          final failure = classifyCallableError(
            code: code == 'ai_unavailable' ? 'unavailable' : 'internal',
            details: {'code': code, ...v.value},
          );
          await tester.pumpWidget(
            hostScreen(TestEnv(), _ErrorHost(failure), locale: lang),
          );
          await tester.pumpAndSettle();
          final l10n = await AppLocalizations.delegate.load(Locale(lang));
          expect(find.text(l10n.errorGenerateTitle), findsOneWidget);
          expect(find.text(_expected[lang]![code]![v.key]!), findsOneWidget);
        });
      }
    }
  }

  testWidgets(
    'a promise of a give-back appears only with slotReleased = true',
    (tester) async {
      for (final details in [
        {'code': 'ai_unavailable', 'slotReleased': false},
        {'code': 'ai_unavailable'},
        {
          'code': 'ai_unavailable',
          'slotReleased': 'true',
        }, // not a bool -> unknown
      ]) {
        final failure = classifyCallableError(
          code: 'unavailable',
          details: details,
        );
        await tester.pumpWidget(hostScreen(TestEnv(), _ErrorHost(failure)));
        await tester.pumpAndSettle();
        expect(find.textContaining('nie wlicza się'), findsNothing);
      }
    },
  );
}
