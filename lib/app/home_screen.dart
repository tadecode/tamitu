import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../core/ui/app_icon.dart';
import '../core/ui/components.dart';
import '../core/ui/tokens.dart';
import '../features/plan_generation/domain/trip_input.dart';
import '../features/plans/application/plans_providers.dart';
import '../features/plans/domain/saved_plan.dart';
import '../features/session/session_controller.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';

/// Delay before the EK-04 loading skeleton (no flash for a fast local read).
const planListSkeletonDelay = Duration(milliseconds: 300);

/// EK-04 Trip list, the start screen (US-008). Works offline: plans come from the
/// encrypted account database only.
///
/// Not here yet: the `settings-02` action to EK-12 (Settings is a later task and EK-12
/// is not `ux-ready`; see the TAM-19 log).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _skeletonTimer;
  bool _showSkeleton = false;

  @override
  void initState() {
    super.initState();
    _skeletonTimer = Timer(planListSkeletonDelay, () {
      if (mounted) setState(() => _showSkeleton = true);
    });
  }

  @override
  void dispose() {
    _skeletonTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = ref.watch(sessionProvider);
    final uid = status is SessionReady ? status.uid : null;
    final plans = uid == null
        ? const AsyncValue<List<SavedPlanSummary>>.loading()
        : ref.watch(savedPlansProvider(uid));
    final hasPlans = plans.value?.isNotEmpty ?? false;
    final Widget body;
    if (plans.hasError && !plans.isLoading) {
      body = StateView(
        key: const Key('planListError'),
        icon: AppIcons.error,
        title: l10n.planListLoadErrorTitle,
        body: l10n.planListLoadErrorBody,
        primary: AppButton.tonal(
          key: const Key('planListRetry'),
          label: l10n.commonRetry,
          onPressed: () => ref.invalidate(savedPlansProvider(uid!)),
        ),
      );
    } else if (plans.value case final list?) {
      body = list.isEmpty ? _Empty(l10n: l10n) : _PlanList(plans: list);
    } else {
      body = _showSkeleton
          ? Semantics(
              key: const Key('planListLoading'),
              label: l10n.commonLoadingLabel,
              child: const _Skeleton(),
            )
          : const SizedBox.shrink();
    }
    return Scaffold(
      appBar: AppBar(
        title: Semantics(header: true, child: Text(l10n.planListTitle)),
      ),
      body: SafeArea(child: body),
      floatingActionButton: hasPlans
          ? FloatingActionButton.extended(
              key: const Key('planListFab'),
              onPressed: () => context.push(Routes.tripForm),
              icon: const AppIcon(AppIcons.add),
              label: Text(l10n.planListNewTrip),
            )
          : null,
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.l10n});

  final AppLocalizations l10n;

  /// CMP-18 "empty" (scrolls by itself at 200 %) with the CMP-13 device-only notice
  /// (U9) below it.
  @override
  Widget build(BuildContext context) => Column(
    key: const Key('planListEmpty'),
    children: [
      Expanded(
        child: StateView(
          icon: AppIcons.trips,
          title: l10n.planListEmptyTitle,
          body: l10n.planListEmptyBody,
          primary: AppButton.filled(
            key: const Key('homeNewTrip'),
            label: l10n.planListNewTrip,
            onPressed: () => context.push(Routes.tripForm),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(Space.s4),
        child: ContentColumn(
          child: Notice(
            key: const Key('planListDeviceOnlyNotice'),
            variant: NoticeVariant.info,
            icon: AppIcons.deviceOnly,
            text: l10n.planListDeviceOnlyNotice,
          ),
        ),
      ),
    ],
  );
}

/// FAB height (56) + 16 dp below the last card (EK-04 "Układ").
const _fabClearance = 56.0 + Space.s4 + Space.s4;

class _PlanList extends StatelessWidget {
  const _PlanList({required this.plans});

  final List<SavedPlanSummary> plans;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: ListView.separated(
        key: const Key('planList'),
        padding: const EdgeInsets.fromLTRB(
          Space.s4,
          Space.s2,
          Space.s4,
          _fabClearance,
        ),
        itemCount: plans.length,
        separatorBuilder: (_, _) => const SizedBox(height: Space.s2),
        itemBuilder: (context, i) => PlanCard(plan: plans[i]),
      ),
    ),
  );
}

/// CMP-12 plan card (EK-04): destination (2 lines max), "{n} days · flight/car" with an
/// icon, "Created {date}". One TalkBack label for the whole card.
class PlanCard extends StatelessWidget {
  const PlanCard({super.key, required this.plan});

  final SavedPlanSummary plan;

  void _open(BuildContext context) =>
      unawaited(context.push(Routes.savedPlan(plan.id)));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final days = l10n.planListDays(plan.daysCount);
    final flight = plan.arrivalMode == ArrivalMode.flight;
    final mode = flight ? l10n.planListArrivalFlight : l10n.planListArrivalCar;
    final local = plan.createdAt.toLocal();
    final created = l10n.planListCreatedOn(
      DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag())
          .format(local),
    );
    return Semantics(
      button: true,
      label: '${plan.destination}, $days, $mode, $created',
      excludeSemantics: true,
      onTap: () => _open(context),
      child: Card.filled(
        key: Key('planCard-${plan.id}'),
        margin: EdgeInsets.zero,
        color: theme.colorScheme.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.all(Space.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.destination,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: Space.s1),
                  Row(
                    children: [
                      AppIcon(
                        flight ? AppIcons.flight : AppIcons.car,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: Space.s2),
                      Flexible(
                        child: Text(
                          '$days · $mode',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.s1),
                  Text(
                    created,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// CMP-17 skeleton: three card-shaped placeholders.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHigh;
    Widget line(double f) => FractionallySizedBox(
      widthFactor: f,
      child: Container(
        height: 12,
        margin: const EdgeInsets.symmetric(vertical: Space.s1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
    return ExcludeSemantics(
      child: ListView(
        padding: const EdgeInsets.all(Space.s4),
        children: [
          for (final w in const [0.4, 0.35, 0.45])
            Card.filled(
              margin: const EdgeInsets.only(bottom: Space.s2),
              child: Padding(
                padding: const EdgeInsets.all(Space.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [line(w), line(0.6), line(0.5)],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
