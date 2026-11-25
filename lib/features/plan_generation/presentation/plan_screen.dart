import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/ui/app_icon.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../trip_form/presentation/trip_form_screen.dart'
    show formatLocalDate, formatLocalTime;
import '../domain/generated_plan.dart';
import '../domain/trip_input.dart';

/// What EK-08 shows: the form data and the plan. Saved plans are loaded from the phone
/// (`SavedPlanScreen`, TAM-19); a plan that could not be saved is shown from memory.
class PlanViewData {
  const PlanViewData({
    required this.input,
    required this.plan,
    this.fresh = false,
  });

  final TripInput input;
  final GeneratedPlan plan;

  /// Opened right after EK-07 ("plan saved" snackbar with the quota).
  final bool fresh;
}

/// EK-08 Plan view (US-005, US-006, US-008, US-009).
///
/// Placeholder for a later task: TAM-20 (P3-07) "Directions" on every item (EK-09 /
/// Google Maps link).
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key, required this.data, this.onDelete});

  /// Null when the plan cannot be shown (missing, unreadable, or the route was restored
  /// without it): CMP-18 error with "Back to list".
  final PlanViewData? data;

  /// "Delete trip" in the `more-vertical` menu (EK-11). Null for a plan that is not
  /// saved on the phone: there is nothing to delete, so there is no menu.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = data;
    if (d == null) {
      return Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: StateView(
            icon: AppIcons.error,
            title: l10n.planLoadErrorTitle,
            body: l10n.planLoadErrorBody,
            primary: AppButton.filled(
              key: const Key('planBackToList'),
              label: l10n.planBackToList,
              onPressed: () => context.go(Routes.home),
            ),
          ),
        ),
      );
    }
    final days = d.plan.days;
    final header = <Widget>[
      Notice(
        key: const Key('planAiNotice'),
        variant: NoticeVariant.info,
        icon: AppIcons.aiInfo,
        text: l10n.planAiNotice,
      ),
      const SizedBox(height: Space.s4),
      _Summary(input: d.input),
    ];
    final scaffoldBody = days.length == 1
        ? ListView(
            padding: const EdgeInsets.all(Space.s4),
            children: [
              ...header,
              const SizedBox(height: Space.s4),
              ..._dayContent(context, d, days.single),
            ],
          )
        : NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Space.s4,
                  Space.s4,
                  Space.s4,
                  0,
                ),
                sliver: SliverList.list(children: header),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabsHeader(
                  TabBar(
                    key: const Key('planDayTabs'),
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      for (final day in days)
                        Tab(text: l10n.planDayTab(day.dayNumber)),
                    ],
                  ),
                  Theme.of(context).colorScheme.surface,
                ),
              ),
            ],
            body: TabBarView(
              children: [
                for (final day in days)
                  ListView(
                    padding: const EdgeInsets.all(Space.s4),
                    children: _dayContent(context, d, day),
                  ),
              ],
            ),
          );
    return DefaultTabController(
      length: days.length,
      child: Scaffold(
        appBar: AppBar(
          title: Semantics(header: true, child: Text(d.input.destination)),
          actions: [
            if (onDelete != null)
              PopupMenuButton<void>(
                key: const Key('planMenu'),
                icon: const AppIcon(AppIcons.more),
                tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                itemBuilder: (_) => [
                  PopupMenuItem<void>(
                    key: const Key('planMenuDelete'),
                    onTap: onDelete,
                    child: Text(l10n.planDelete),
                  ),
                ],
              ),
          ],
        ),
        body: SafeArea(child: ContentColumn(child: scaffoldBody)),
      ),
    );
  }

  List<Widget> _dayContent(BuildContext context, PlanViewData d, PlanDay day) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final planLocale = Locale(d.plan.language);
    return [
      Semantics(
        header: true,
        child: PlanText(
          day.title,
          locale: planLocale,
          style: theme.textTheme.titleMedium,
        ),
      ),
      const SizedBox(height: Space.s2),
      if (day.items.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.s2),
          child: Text(
            l10n.planDayOnlyArrival,
            key: const Key('planDayOnlyArrival'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      for (final item in day.items)
        _PlanItemTile(item: item, locale: planLocale),
    ];
  }
}

class _TabsHeader extends SliverPersistentHeaderDelegate {
  _TabsHeader(this.tabBar, this.background);

  final TabBar tabBar;
  final Color background;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      ColoredBox(color: background, child: tabBar);

  @override
  bool shouldRebuild(_TabsHeader old) =>
      old.tabBar != tabBar || old.background != background;
}

/// CMP-12 summary card: lodging and arrival (D4, D5); flight number only if given.
class _Summary extends StatelessWidget {
  const _Summary({required this.input});

  final TripInput input;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final date = formatLocalDate(context, input.arrivalDate);
    final time = formatLocalTime(
      context,
      input.arrivalTime.hour,
      input.arrivalTime.minute,
    );
    final arrival = input.arrivalMode == ArrivalMode.flight
        ? l10n.planArrivalFlight(date, time, input.airport ?? '')
        : l10n.planArrivalCar(date, time);
    return Card(
      key: const Key('planSummary'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Space.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.planLodging(input.lodging),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: Space.s1),
            Text(arrival, style: theme.textTheme.bodyMedium),
            if (input.flightNumber != null) ...[
              const SizedBox(height: Space.s1),
              Text(
                l10n.planFlightNumber(input.flightNumber!),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// CMP-20 plan item: approx. time (`tertiary`), name, locality, description – content in
/// the plan language (TalkBack pronunciation, EK-08 "Dostępność").
class _PlanItemTile extends StatelessWidget {
  const _PlanItemTile({required this.item, required this.locale});

  final PlanItem item;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.planItemTime(item.startTime),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.tertiary,
            ),
          ),
          const SizedBox(height: Space.s1),
          PlanText(
            item.name,
            key: const Key('planItemName'),
            locale: locale,
            style: theme.textTheme.titleMedium,
          ),
          PlanText(
            item.locality,
            locale: locale,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Space.s1),
          PlanText(
            item.description,
            locale: locale,
            style: theme.textTheme.bodyMedium,
          ),
          // TAM-20 (P3-07): "Directions" (CMP-02, 48 dp) -> EK-09 / Maps link.
        ],
      ),
    );
  }
}

/// Plan content in the plan language. `TextSpan.locale` (not only `Text.locale`) adds a
/// locale attribute to the semantics label, so TalkBack reads it with the right voice
/// when the UI language differs (EK-08 "Dostępność", review PR #164 #2).
class PlanText extends StatelessWidget {
  const PlanText(this.text, {super.key, required this.locale, this.style});

  final String text;
  final Locale locale;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(text: text, locale: locale),
    locale: locale,
    style: style,
  );
}
