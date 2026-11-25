import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../plan_generation/presentation/plan_screen.dart';
import '../application/plans_providers.dart';
import 'delete_plan_dialog.dart';

/// Delay before the EK-08 loading skeleton (no flash for a fast local read).
const savedPlanSkeletonDelay = Duration(milliseconds: 300);

/// EK-08 for a plan saved on the phone (US-008, US-009): loads it from the encrypted
/// database (works offline), offers "Delete trip" (EK-11) and, right after EK-07, the
/// "plan saved" snackbar with the remaining daily quota (U4).
class SavedPlanScreen extends ConsumerStatefulWidget {
  const SavedPlanScreen({
    super.key,
    required this.uid,
    required this.planId,
    this.initial,
  });

  final String uid;
  final String planId;

  /// The plan just saved by EK-07 (no second read); null = load [planId].
  final PlanViewData? initial;

  @override
  ConsumerState<SavedPlanScreen> createState() => _SavedPlanScreenState();
}

class _SavedPlanScreenState extends ConsumerState<SavedPlanScreen> {
  PlanViewData? _data;
  bool _failed = false;
  bool _showSkeleton = false;
  Timer? _skeletonTimer;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _data = initial;
      if (initial.fresh) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showSaved());
      }
    } else {
      _skeletonTimer = Timer(savedPlanSkeletonDelay, () {
        if (mounted) setState(() => _showSkeleton = true);
      });
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _skeletonTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    PlanViewData? data;
    try {
      final saved = await ref
          .read(planRepositoryProvider)
          .load(widget.uid, widget.planId);
      if (saved != null) {
        data = PlanViewData(input: saved.input, plan: saved.plan);
      }
    } catch (_) {
      data = null;
    }
    _skeletonTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _data = data;
      _failed = data == null;
    });
  }

  void _showSaved() {
    final quota = _data?.plan.quota;
    if (!mounted || quota == null) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('planSavedSnack'),
          content: Text(l10n.planSavedSnack(quota.remainingToday, quota.limit)),
        ),
      );
  }

  Future<void> _delete() async {
    final data = _data;
    if (data == null) return;
    final destination = data.input.destination;
    final repo = ref.read(planRepositoryProvider);
    final deleted = await showDeletePlanDialog(
      context,
      destination: destination,
      delete: () => repo.delete(widget.uid, widget.planId),
    );
    if (!deleted || !mounted) return;
    ref.invalidate(savedPlansProvider(widget.uid));
    final l10n = AppLocalizations.of(context)!;
    // The messenger outlives this route: the snackbar shows on EK-04, above the FAB.
    final messenger = ScaffoldMessenger.of(context);
    context.go(Routes.home);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('planDeletedSnack'),
          content: Text(l10n.planDeletedSnack(destination)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data != null) return PlanScreen(data: data, onDelete: _delete);
    if (_failed) return const PlanScreen(data: null);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: _showSkeleton
            ? Semantics(
                key: const Key('planLoading'),
                label: l10n.commonLoadingLabel,
                child: const _PlanSkeleton(),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

/// CMP-17 skeleton of EK-08: summary card + three items.
class _PlanSkeleton extends StatelessWidget {
  const _PlanSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHigh;
    Widget box(double widthFactor, double height) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.s1),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widthFactor,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
    return ExcludeSemantics(
      child: ContentColumn(
        child: ListView(
          padding: const EdgeInsets.all(Space.s4),
          children: [
            box(1, 72),
            const SizedBox(height: Space.s4),
            for (var i = 0; i < 3; i++) ...[
              box(0.2, 12),
              box(0.6, 16),
              box(0.9, 12),
              const SizedBox(height: Space.s3),
            ],
          ],
        ),
      ),
    );
  }
}
