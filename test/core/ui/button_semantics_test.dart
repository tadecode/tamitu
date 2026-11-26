// TAM-111: shared buttons must expose a TalkBack tap action. `excludeSemantics` on a
// wrapping `Semantics` drops the child's own tap action, so the wrapper needs `onTap`.
import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tamitu/core/ui/app_theme.dart';
import 'package:tamitu/core/ui/components.dart';

Future<void> _host(WidgetTester t, Widget child) => t.pumpWidget(
  MaterialApp(
    theme: AppTheme.lightTheme(),
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

SemanticsData _data(WidgetTester t, Finder f) =>
    t.getSemantics(f).getSemanticsData();

void _semanticsTap(WidgetTester t, Finder f) =>
    t.binding.performSemanticsAction(
      SemanticsActionEvent(
        type: SemanticsAction.tap,
        viewId: t.view.viewId,
        nodeId: t.getSemantics(f).id,
      ),
    );

typedef _Make = Widget Function({
  required VoidCallback? onPressed,
  bool loading,
  String? disabledHint,
});

final Map<String, _Make> _variants = {
  'filled': ({required onPressed, loading = false, disabledHint}) =>
      AppButton.filled(
        key: const Key('b'),
        label: 'Go',
        loadingLabel: 'Going…',
        disabledHint: disabledHint,
        loading: loading,
        onPressed: onPressed,
      ),
  'tonal': ({required onPressed, loading = false, disabledHint}) =>
      AppButton.tonal(
        key: const Key('b'),
        label: 'Go',
        loadingLabel: 'Going…',
        disabledHint: disabledHint,
        loading: loading,
        onPressed: onPressed,
      ),
  'outlined': ({required onPressed, loading = false, disabledHint}) =>
      AppButton.outlined(
        key: const Key('b'),
        label: 'Go',
        loadingLabel: 'Going…',
        disabledHint: disabledHint,
        loading: loading,
        onPressed: onPressed,
      ),
};

void main() {
  const b = Key('b');

  for (final MapEntry(key: name, value: make) in _variants.entries) {
    group('AppButton.$name', () {
      testWidgets(
        'enabled: labelled button with a tap action that presses it',
        (t) async {
          final handle = t.ensureSemantics();
          var pressed = 0;
          await _host(t, make(onPressed: () => pressed++));
          final data = _data(t, find.byKey(b));
          expect(data.label, 'Go');
          expect(data.flagsCollection.isButton, isTrue);
          expect(data.flagsCollection.isEnabled, Tristate.isTrue);
          expect(data.hasAction(SemanticsAction.tap), isTrue);
          _semanticsTap(t, find.byKey(b));
          await t.pump();
          expect(pressed, 1);
          // The guideline checks this node because it now has a tap action (before
          // TAM-111 it had none, so the guideline skipped it and passed vacuously).
          await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
          handle.dispose();
        },
      );

      testWidgets('disabled: no tap action, reason in the label', (t) async {
        final handle = t.ensureSemantics();
        await _host(t, make(onPressed: null, disabledHint: 'Accept first'));
        final data = _data(t, find.byKey(b));
        expect(data.label, 'Go. Accept first');
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.flagsCollection.isEnabled, Tristate.isFalse);
        expect(data.hasAction(SemanticsAction.tap), isFalse);
        handle.dispose();
      });

      testWidgets('loading: no tap action, loading label', (t) async {
        final handle = t.ensureSemantics();
        var pressed = 0;
        await _host(t, make(onPressed: () => pressed++, loading: true));
        final data = _data(t, find.byKey(b));
        expect(data.label, 'Going…');
        expect(data.flagsCollection.isEnabled, Tristate.isFalse);
        expect(data.hasAction(SemanticsAction.tap), isFalse);
        expect(pressed, 0);
        handle.dispose();
      });
    });
  }

  testWidgets('ConsentCheckbox: separate link button has a tap action', (
    t,
  ) async {
    final handle = t.ensureSemantics();
    var opened = 0;
    await _host(
      t,
      ConsentCheckbox(
        value: false,
        onChanged: (_) {},
        before: 'I accept the ',
        linkText: 'Privacy Policy',
        after: '.',
        onOpenLink: () => opened++,
        linkHint: 'opens in browser',
        linkButtonText: 'Read the Privacy Policy',
      ),
    );
    final link = find.bySemanticsLabel(
      'Read the Privacy Policy, opens in browser',
    );
    expect(link, findsOneWidget);
    final data = t.getSemantics(link).getSemanticsData();
    expect(data.flagsCollection.isLink, isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    _semanticsTap(t, link);
    await t.pump();
    expect(opened, 1);
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets(
    'control: labeledTapTargetGuideline fails on an unlabelled tap node',
    (t) async {
      // Proves the guideline inspects tap-action nodes, so a pass above is meaningful.
      final handle = t.ensureSemantics();
      await _host(
        t,
        Semantics(
          button: true,
          onTap: () {},
          container: true,
          excludeSemantics: true,
          child: const SizedBox(width: 48, height: 48),
        ),
      );
      final result = await labeledTapTargetGuideline.evaluate(t);
      expect(result.passed, isFalse);
      handle.dispose();
    },
  );
}
