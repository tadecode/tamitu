import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../consent/application/consent_service.dart';
import '../../generation/application/ai_busy_controller.dart';
import '../../generation/presentation/ai_busy_view.dart';
import '../../session/session_controller.dart';
import '../application/generation_result.dart';
import '../domain/generated_plan.dart';
import '../domain/trip_input.dart';
import 'plan_screen.dart';

/// Seconds between the rotating helper texts (EK-07: "changes every ~10 s").
const generationStepEvery = Duration(seconds: 10);

/// EK-07 Plan generation (US-005, US-011): modal, no back arrow, "Cancel" with a dialog.
///
/// One `generatePlan` per form submission (new `requestId`); success -> EK-08 (the form
/// does not stay on the stack); `ai_busy` -> the "AI busy" state on this screen
/// ([AiBusyView], one automatic retry with a NEW `requestId`); any other result pops
/// back to EK-05 with a [GenerationResult]. Cancel = the answer is dropped (the callable
/// cannot be aborted, posrednik-api.md "Slot limitu"): nothing is saved.
class GenerationScreen extends ConsumerStatefulWidget {
  const GenerationScreen({super.key, required this.uid, required this.input});

  final String uid;
  final TripInput input;

  @override
  ConsumerState<GenerationScreen> createState() => _GenerationScreenState();
}

class _GenerationScreenState extends ConsumerState<GenerationScreen> {
  AiBusyController? _busy;
  GeneratedPlan? _retryPlan;
  bool _finished = false;
  int _step = 0;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _startSteps(first: 0);
    unawaited(_run());
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _busy?.dispose();
    super.dispose();
  }

  void _startSteps({required int first}) {
    _stepTimer?.cancel();
    _step = first;
    _stepTimer = Timer.periodic(generationStepEvery, (_) {
      if (!mounted || _step >= 3) return;
      setState(() => _step++);
    });
  }

  Future<GeneratedPlan> _call() async {
    final requestId = ref.read(requestIdProvider)();
    return ref
        .read(planApiProvider)
        .generatePlan(widget.input, requestId: requestId);
  }

  Future<void> _run() async {
    // Pending consent records go first (posrednik-api.md pkt 6, ADR-0012 pkt 5). A failed
    // sync does not stop generating: the server then answers consent_required.
    await ref.read(consentServiceProvider).syncPending(widget.uid);
    if (_finished || !mounted) return;
    try {
      final plan = await _call();
      if (_finished || !mounted) return;
      _openPlan(plan);
    } on AppFailure catch (f) {
      if (_finished || !mounted) return;
      if (f.kind == FailureKind.aiBusy) {
        _stepTimer?.cancel();
        setState(() {
          _busy = AiBusyController(
            failure: f,
            retry: _retry,
            onSuccess: () => _openPlan(_retryPlan!),
            onFailure: (failure) => unawaited(_handleFailure(failure)),
            clock: ref.read(aiBusyClockProvider),
          )..addListener(_onBusyChange);
        });
      } else {
        await _handleFailure(f);
      }
    }
  }

  /// `ai_busy` retry: same form data, NEW requestId (ADR-0016 pkt 12).
  Future<AppFailure?> _retry() async {
    try {
      _retryPlan = await _call();
      return null;
    } on AppFailure catch (f) {
      return f;
    }
  }

  AiBusyPhase? _lastBusyPhase;

  void _onBusyChange() {
    final phase = _busy?.phase;
    if (phase == AiBusyPhase.retrying && _lastBusyPhase != phase) {
      _startSteps(first: 0);
    }
    _lastBusyPhase = phase;
    if (mounted) setState(() {});
  }

  void _openPlan(GeneratedPlan plan) {
    if (_finished || !mounted) return;
    _finished = true;
    // EK-08 replaces the form (back from EK-08 -> start screen, EK-08 "Wejście i wyjście").
    context.go(
      Routes.plan,
      extra: PlanViewData(input: widget.input, plan: plan, fresh: true),
    );
  }

  void _pop(GenerationResult result) {
    if (_finished || !mounted) return;
    _finished = true;
    // Review PR #164 #1: a result may arrive while the cancel dialog (CMP-15) is open.
    // Close everything above this route first, so the result pops EK-07, not the dialog.
    final navigator = Navigator.of(context);
    final route = ModalRoute.of(context);
    if (route != null) navigator.popUntil((r) => r == route);
    navigator.pop(result);
  }

  Future<void> _handleFailure(AppFailure f) async {
    if (_finished || !mounted) return;
    switch (f.kind) {
      case FailureKind.unauthenticated:
        // EK-16: session expired -> EK-02 with a snackbar (the router redirects).
        _finished = true;
        await ref.read(sessionProvider.notifier).expireSession();
      case FailureKind.consentRequired:
        final type = f.consentType ?? ConsentType.privacyPolicy;
        final action = await ref
            .read(consentServiceProvider)
            .resolveConsentRequired(widget.uid, type);
        if (!mounted) return;
        if (action == ConsentRequiredAction.updateApp) {
          _pop(
            const GenerationFailed(AppFailure(FailureKind.unsupportedVersion)),
          );
        } else if (type == ConsentType.aiProcessing) {
          _pop(const GenerationNeedsAiConsent());
        } else {
          // Policy (ADR-0012, EK-16): straight to EK-03 without a message – the session
          // is re-evaluated and the router opens EK-03 (no local acceptance).
          _pop(const GenerationBack());
          await ref.read(sessionProvider.notifier).refresh();
        }
      default:
        _pop(GenerationFailed(f));
    }
  }

  Future<void> _confirmCancel() async {
    final l10n = AppLocalizations.of(context)!;
    final stop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Semantics(header: true, child: Text(l10n.generationCancelTitle)),
        content: Text(l10n.generationCancelBody),
        actions: [
          TextButton(
            key: const Key('generationCancelContinue'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.generationCancelContinue),
          ),
          TextButton(
            key: const Key('generationCancelConfirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.generationCancelConfirm),
          ),
        ],
      ),
    );
    if (stop == true) _pop(const GenerationCancelled());
  }

  bool get _loading {
    final busy = _busy;
    return busy == null || busy.phase == AiBusyPhase.retrying;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final busy = _busy;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Semantics(header: true, child: Text(l10n.tripFormTitle)),
      ),
      body: SafeArea(
        child: _loading
            ? PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop) unawaited(_confirmCancel());
                },
                child: _loadingView(context, l10n, retry: busy != null),
              )
            : AiBusyView(
                controller: busy!,
                onBack: () => _pop(const GenerationBack()),
              ),
      ),
    );
  }

  Widget _loadingView(
    BuildContext context,
    AppLocalizations l10n, {
    required bool retry,
  }) {
    final theme = Theme.of(context);
    final helper = switch (_step) {
      0 => retry ? l10n.generationRetrying : l10n.generationStep1,
      1 => l10n.generationStep2,
      _ => l10n.generationStep3,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Space.s4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: LayoutLimits.stateTextMaxWidth,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.generationFor(
                        widget.input.destination,
                        l10n.commonDaysCount(widget.input.days),
                      ),
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Space.s6),
                    const LinearProgressIndicator(),
                    const SizedBox(height: Space.s6),
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.generationTitle,
                        key: const Key('generationTitle'),
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: Space.s2),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        helper,
                        key: const Key('generationStep'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: Space.s2),
                    Text(
                      l10n.generationMayTakeTime,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
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
                child: OutlinedButton(
                  key: const Key('generationCancel'),
                  onPressed: _confirmCancel,
                  child: Text(l10n.generationCancel),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
