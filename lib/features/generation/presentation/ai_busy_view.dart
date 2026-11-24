import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/failure_messages.dart';
import '../../../core/ui/app_icon.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/ai_busy_controller.dart';

/// `m:ss` without a leading zero for minutes: 1:00, 0:42, 0:05, 2:00 (ek-07-ai-busy.md).
String formatCountdown(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// `{minutes}` of `generationBusyBodyAuto`: retryAfterSec / 60 rounded up.
int countdownMinutes(int retryAfterSec) => (retryAfterSec + 59) ~/ 60;

/// Polite TalkBack announcement of the remaining time (every 15 s, ek-07-ai-busy.md).
void announceAiBusy(BuildContext context, String message) {
  final view = View.maybeOf(context);
  if (view == null) return;
  SemanticsService.sendAnnouncement(view, message, Directionality.of(context));
}

/// Body of EK-07 in the "AI busy" state (A, B, D, E) and its retry (C). The host (EK-07)
/// provides the Scaffold with the "New trip" app bar, creates the [AiBusyController] and
/// navigates on success / other errors. CMP-18 "AI busy" + CMP-17 countdown bar + CMP-02.
///
/// "Back to the form" and system back in A/B/D/E call [onBack] without a dialog; during
/// the retry (C) back is left to the EK-07 cancel dialog of the host.
class AiBusyView extends StatefulWidget {
  const AiBusyView({super.key, required this.controller, required this.onBack});

  final AiBusyController controller;
  final VoidCallback onBack;

  @override
  State<AiBusyView> createState() => _AiBusyViewState();
}

class _AiBusyViewState extends State<AiBusyView> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onStateChange: (s) =>
          widget.controller.setForeground(s == AppLifecycleState.resumed),
    );
    widget.controller.addListener(_onChange);
  }

  AiBusyPhase? _lastPhase;
  int _announced = 0;

  void _onChange() {
    final c = widget.controller;
    final l10n = AppLocalizations.of(context)!;
    if (c.phase == AiBusyPhase.retrying && _lastPhase != AiBusyPhase.retrying) {
      announceAiBusy(context, l10n.generationRetrying);
    } else if (c.phase == AiBusyPhase.countdown &&
        c.announcements != _announced &&
        c.announcedSec != null) {
      announceAiBusy(
        context,
        l10n.generationBusyCountdownA11y(c.announcedSec!),
      );
    }
    _announced = c.announcements;
    _lastPhase = c.phase;
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    _lifecycle.dispose();
    super.dispose();
  }

  void _back() {
    widget.controller.cancel();
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = widget.controller;
    final phase = c.phase;
    final busy = phase != AiBusyPhase.retrying && phase != AiBusyPhase.done;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && busy) _back();
      },
      child: busy ? _busy(context, l10n, c) : _retrying(context, l10n),
    );
  }

  Widget _retrying(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: Space.s4),
            Text(
              l10n.generationRetrying,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _busy(
    BuildContext context,
    AppLocalizations l10n,
    AiBusyController c,
  ) {
    final phase = c.phase;
    final title = phase == AiBusyPhase.manual
        ? l10n.generationBusyStillTitle
        : l10n.generationBusyTitle;
    final lead = switch (phase) {
      AiBusyPhase.countdown => l10n.generationBusyBodyAuto(
        countdownMinutes(c.retryAfterSec),
      ),
      AiBusyPhase.paused => l10n.generationBusyBodyPaused,
      _ => l10n.generationBusyBodyManual,
    };
    // Two keys, never glued in translation (ek-07-ai-busy.md "Teksty").
    final body = '$lead ${busyQuotaSentence(l10n, c.slotReleased)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: StateView(
            icon: AppIcons.aiInfo,
            title: title,
            body: body,
            detail: phase == AiBusyPhase.countdown
                ? _Countdown(controller: c)
                : null,
            primary: AppButton.tonal(
              key: const Key('aiBusyTryNow'),
              label: l10n.generationBusyTryNow,
              onPressed: c.tryNow,
            ),
          ),
        ),
        Align(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: LayoutLimits.bottomButtonMaxWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.s4,
                Space.s2,
                Space.s4,
                Space.s4,
              ),
              child: SizedBox(
                height: 48,
                child: AppButton.outlined(
                  key: const Key('aiBusyBack'),
                  label: l10n.generationBusyBack,
                  onPressed: _back,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Countdown text (tabular figures, own TalkBack label, not a live region) and the
/// emptying bar (CMP-17 "determinate - countdown", hidden from TalkBack).
class _Countdown extends StatelessWidget {
  const _Countdown({required this.controller});

  final AiBusyController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final seconds = controller.remainingSec;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          key: const Key('aiBusyCountdown'),
          label: l10n.generationBusyCountdownA11y(seconds),
          excludeSemantics: true,
          child: Text(
            l10n.generationBusyCountdown(formatCountdown(seconds)),
            style: theme.textTheme.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: Space.s2),
        ExcludeSemantics(
          child: LinearProgressIndicator(
            key: const Key('aiBusyBar'),
            value: controller.remainingFraction,
            minHeight: 4,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}
