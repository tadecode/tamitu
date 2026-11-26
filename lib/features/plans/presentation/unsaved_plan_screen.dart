import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/ui/app_icon.dart';
import '../../../core/ui/components.dart';
import '../../../l10n/app_localizations.dart';
import '../../plan_generation/presentation/plan_screen.dart';
import '../application/plans_providers.dart';
import '../domain/saved_plan.dart';
import 'saved_plan_screen.dart';

/// A plan from EK-07 that could not be saved on the phone (route `extra`).
class UnsavedPlan {
  const UnsavedPlan({required this.data, required this.failure});

  /// The plan from the `generatePlan` answer, kept in memory only.
  final PlanViewData data;

  /// Why the save failed (EK-08 v0.2: the notice text depends on it).
  final PlanStorageFailure failure;
}

/// EK-08 v0.2 "Plan nie jest zapisany" (TAM-104, TAM-113): the plan works as usual (day
/// tabs, "Directions"), with a CMP-13 error notice above it and "Try saving again"; no
/// delete menu and no "saved" snackbar. Back asks first (CMP-15, the plan is lost).
/// After a successful retry the screen is a regular EK-08 of a saved plan.
class UnsavedPlanScreen extends ConsumerStatefulWidget {
  const UnsavedPlanScreen({super.key, required this.uid, required this.plan});

  final String uid;
  final UnsavedPlan plan;

  @override
  ConsumerState<UnsavedPlanScreen> createState() => _UnsavedPlanScreenState();
}

class _UnsavedPlanScreenState extends ConsumerState<UnsavedPlanScreen> {
  late PlanStorageFailure _failure = widget.plan.failure;

  /// Trip id once a retry saved the plan; from then on this is a regular EK-08.
  String? _savedId;

  /// The retry in progress (back waits for it: the save takes a fraction of a second).
  Future<void>? _saving;
  bool _leaving = false;

  PlanViewData get _data => widget.plan.data;

  Future<void> _retry() {
    if (_saving != null || _savedId != null) return _saving ?? Future.value();
    final saving = _save();
    setState(() {
      _saving = saving;
    });
    return saving;
  }

  Future<void> _save() async {
    String? id;
    var failure = _failure;
    try {
      id = await ref
          .read(planRepositoryProvider)
          .save(widget.uid, _data.input, _data.plan);
      ref.invalidate(savedPlansProvider(widget.uid));
    } on PlanStorageException catch (e) {
      failure = e.failure;
    } catch (_) {
      failure = PlanStorageFailure.other;
    }
    if (!mounted) return;
    setState(() {
      _saving = null;
      _savedId = id;
      _failure = failure;
    });
    if (id != null) {
      showPlanSavedSnack(context, _data.plan);
    } else {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            key: const Key('planSaveFailedAgainSnack'),
            content: Text(l10n.planSaveFailedAgainSnack),
          ),
        );
    }
  }

  /// Back arrow, system back or predictive back while the plan is not saved.
  Future<void> _onBack() async {
    if (_leaving) return;
    _leaving = true;
    try {
      final saving = _saving;
      if (saving != null) await saving;
      if (!mounted) return;
      if (_savedId != null) {
        context.go(Routes.home);
        return;
      }
      final leave = await showLeaveUnsavedPlanDialog(context);
      if (leave && mounted) context.go(Routes.home);
    } finally {
      _leaving = false;
    }
  }

  Future<void> _delete() async {
    final id = _savedId;
    if (id == null) return;
    await deleteSavedPlan(
      context,
      ref,
      uid: widget.uid,
      planId: id,
      destination: _data.input.destination,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final saved = _savedId != null;
    return PopScope(
      canPop: saved,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_onBack());
      },
      child: PlanScreen(
        data: _data,
        onDelete: saved ? _delete : null,
        notSavedNotice: saved
            ? null
            : Notice(
                key: const Key('planNotSavedNotice'),
                variant: NoticeVariant.error,
                icon: AppIcons.error,
                title: l10n.planNotSavedTitle,
                text: _failure == PlanStorageFailure.noSpace
                    ? l10n.planNotSavedStorageBody
                    : l10n.planNotSavedBody,
                // Announced once on entry and again only when the text changes.
                liveRegion: true,
                action: _SaveRetryButton(
                  saving: _saving != null,
                  onPressed: () => unawaited(_retry()),
                ),
              ),
      ),
    );
  }
}

/// "Try saving again" in the CMP-13 error notice: a text button in the notice colour
/// (onErrorContainer, contrast ≥ 7.2:1), 48 dp. While saving: CMP-02 loading (indicator
/// + "Saving…"), disabled, without a tap action for TalkBack (TAM-111 pattern).
class _SaveRetryButton extends StatelessWidget {
  const _SaveRetryButton({required this.saving, required this.onPressed});

  final bool saving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fg = Theme.of(context).colorScheme.onErrorContainer;
    final label = saving ? l10n.planSaving : l10n.planSaveRetry;
    return Semantics(
      button: true,
      enabled: !saving,
      label: label,
      // excludeSemantics drops the button's own tap action (QA PR #178, TAM-111).
      onTap: saving ? null : onPressed,
      container: true,
      excludeSemantics: true,
      child: TextButton(
        key: const Key('planSaveRetry'),
        style: TextButton.styleFrom(
          foregroundColor: fg,
          disabledForegroundColor: fg,
          minimumSize: const Size(48, 48),
        ),
        onPressed: saving ? null : onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (saving) ...[
              SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(child: Text(label)),
          ],
        ),
      ),
    );
  }
}

/// CMP-15 destructive "Leave without saving?" (EK-08 v0.2). `alert-02`, not `delete-02`:
/// nothing is deleted from the phone. Cancel, tapping outside and back keep the plan.
/// Resolves true only for "Leave without saving".
Future<bool> showLeaveUnsavedPlanDialog(BuildContext context) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      final scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        key: const Key('planLeaveUnsavedDialog'),
        icon: AppIcon(AppIcons.warning, color: scheme.error),
        title: Semantics(header: true, child: Text(l10n.planLeaveUnsavedTitle)),
        content: SingleChildScrollView(child: Text(l10n.planLeaveUnsavedBody)),
        actions: [
          TextButton(
            key: const Key('planLeaveUnsavedCancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            key: const Key('planLeaveUnsavedConfirm'),
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.planLeaveUnsavedConfirm),
          ),
        ],
      );
    },
  );
  return leave == true;
}
