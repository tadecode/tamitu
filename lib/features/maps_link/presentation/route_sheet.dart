import 'package:flutter/semantics.dart' show OrdinalSortKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/ui/app_icon.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../plan_generation/domain/generated_plan.dart';
import '../application/travel_mode.dart';
import '../domain/maps_link.dart';

/// What EK-09 needs about the tapped plan item (all local plan data).
class RouteTarget {
  const RouteTarget({
    required this.item,
    required this.tripDestination,
    required this.planLocale,
    this.previous,
    this.lodging,
  });

  final PlanItem item;

  /// Previous item of the same day; null for the first item of the day.
  final PlanItem? previous;

  /// `trips.lodging`; null or blank = no "Your stay" start.
  final String? lodging;
  final String tripDestination;

  /// Language of the plan content (TalkBack pronunciation).
  final Locale planLocale;

  String get destinationQuery =>
      placeQuery(item.name, item.locality, tripDestination);

  /// Available starts in display order; hidden ones are not built (EK-09 v0.4).
  List<RouteStartKind> get starts => [
    RouteStartKind.myLocation,
    if (previous != null) RouteStartKind.previousPlace,
    if (_lodging != null) RouteStartKind.lodging,
  ];

  String? get _lodging {
    final l = lodging?.trim();
    return l == null || l.isEmpty ? null : l;
  }

  /// `origin` text for [start]; null for "My location" (no `origin` in the link).
  String? originFor(RouteStartKind start) => switch (start) {
    RouteStartKind.myLocation => null,
    RouteStartKind.previousPlace => placeQuery(
      previous!.name,
      previous!.locality,
      tripDestination,
    ),
    RouteStartKind.lodging => lodgingQuery(_lodging!, tripDestination),
  };

  Uri uriFor(RouteStartKind start, TravelMode mode) => directionsUri(
    destination: destinationQuery,
    mode: mode,
    origin: originFor(start),
  );
}

/// Opens EK-09 (CMP-16 bottom sheet) over EK-08.
Future<void> showRouteSheet(BuildContext context, RouteTarget target) {
  final size = MediaQuery.sizeOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    constraints: BoxConstraints(maxWidth: 640, maxHeight: size.height * 0.9),
    builder: (_) => RouteSheet(target: target),
  );
}

/// EK-09 Route to a plan item: start (CMP-10), mode (CMP-07), "Open in Google Maps".
/// The start is not remembered (always "My location"); the mode is (UX11).
class RouteSheet extends ConsumerStatefulWidget {
  const RouteSheet({super.key, required this.target});

  final RouteTarget target;

  @override
  ConsumerState<RouteSheet> createState() => _RouteSheetState();
}

class _RouteSheetState extends ConsumerState<RouteSheet> {
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  var _start = RouteStartKind.myLocation;
  var _opening = false;

  Future<void> _open() async {
    if (_opening) return;
    final l10n = AppLocalizations.of(context)!;
    final uri = widget.target.uriFor(_start, ref.read(travelModeProvider));
    setState(() => _opening = true);
    // No network check (ADR-0011 pkt 2); the link is neither stored nor logged.
    final ok = await ref.read(urlOpenerProvider)(uri);
    if (!mounted) return;
    setState(() => _opening = false);
    if (!ok) {
      _messenger.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.routeOpenError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final t = widget.target;
    final mode = ref.watch(travelModeProvider);
    final content = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.s4, 0, Space.s4, Space.s4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            sortKey: const OrdinalSortKey(1),
            child: _Handle(label: l10n.commonCloseSheet),
          ),
          const SizedBox(height: Space.s2),
          // Focus lands on the title first (EK-09 "Dostępność").
          Semantics(
            sortKey: const OrdinalSortKey(0),
            header: true,
            child: Text.rich(
              key: const Key('routeTitle'),
              TextSpan(
                text: l10n.routeTitle(t.item.name),
                locale: t.planLocale,
              ),
              style: theme.textTheme.titleLarge,
            ),
          ),
          Semantics(
            sortKey: const OrdinalSortKey(0.5),
            child: Text.rich(
              TextSpan(text: t.item.locality, locale: t.planLocale),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Semantics(
            sortKey: const OrdinalSortKey(2),
            explicitChildNodes: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Space.s4),
                _SectionLabel(l10n.routeFrom),
                _Starts(
                  target: t,
                  selected: _start,
                  onChanged: (s) => setState(() => _start = s),
                ),
                const SizedBox(height: Space.s4),
                _SectionLabel(l10n.routeMode),
                const SizedBox(height: Space.s2),
                _Modes(
                  selected: mode,
                  onChanged: ref.read(travelModeProvider.notifier).set,
                ),
                const SizedBox(height: Space.s6),
                Semantics(
                  button: true,
                  enabled: !_opening,
                  label: l10n.routeOpenMaps,
                  hint: l10n.routeOpensOtherApp,
                  // excludeSemantics drops the button's own tap action (QA PR #178).
                  onTap: _opening ? null : _open,
                  container: true,
                  excludeSemantics: true,
                  child: FilledButton.icon(
                    key: const Key('routeOpenMaps'),
                    style: const ButtonStyle(
                      minimumSize: WidgetStatePropertyAll(Size.fromHeight(48)),
                    ),
                    onPressed: _opening ? null : _open,
                    icon: const AppIcon(AppIcons.openExternal, size: 18),
                    label: Text(
                      l10n.routeOpenMaps,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    // CMP-14 snackbar inside the sheet: the page's snackbar would sit under the sheet.
    // The sheet stays open, so the user can try again.
    return Stack(
      children: [
        content,
        Positioned.fill(
          child: IgnorePointer(
            child: ScaffoldMessenger(
              key: _messenger,
              child: const Scaffold(
                backgroundColor: Colors.transparent,
                body: SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// CMP-16 drag handle 32×4 dp in a 48 dp target; tap or TalkBack action closes.
class _Handle extends StatelessWidget {
  const _Handle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      button: true,
      label: label,
      onTap: () => Navigator.of(context).maybePop(),
      container: true,
      excludeSemantics: true,
      child: GestureDetector(
        key: const Key('routeSheetHandle'),
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        child: SizedBox(
          height: 48,
          child: Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

/// CMP-10 with description; only the available starts are built (no gaps, and TalkBack
/// counts only visible ones).
class _Starts extends StatelessWidget {
  const _Starts({
    required this.target,
    required this.selected,
    required this.onChanged,
  });

  final RouteTarget target;
  final RouteStartKind selected;
  final ValueChanged<RouteStartKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hintStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    Widget tile(RouteStartKind kind, String title, InlineSpan subtitle) =>
        RadioListTile<RouteStartKind>(
          key: Key('routeStart-${kind.name}'),
          value: kind,
          contentPadding: EdgeInsets.zero,
          title: Text(title, style: theme.textTheme.bodyLarge),
          subtitle: Text.rich(subtitle, style: hintStyle),
        );
    return RadioGroup<RouteStartKind>(
      groupValue: selected,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final kind in target.starts)
            switch (kind) {
              RouteStartKind.myLocation => tile(
                kind,
                l10n.routeFromMyLocation,
                TextSpan(text: l10n.routeFromMyLocationHint),
              ),
              RouteStartKind.previousPlace => tile(
                kind,
                l10n.routeFromPrevious,
                // Plan content: plan language.
                TextSpan(
                  text: target.previous!.name,
                  locale: target.planLocale,
                ),
              ),
              RouteStartKind.lodging => tile(
                kind,
                l10n.routeFromLodging,
                TextSpan(
                  text: l10n.routeFromLodgingHint(target.lodging!.trim()),
                ),
              ),
            },
        ],
      ),
    );
  }
}

/// CMP-07 Car / Transit / Walk; from 150 % text scale a CMP-10 list (CMP-07 rule).
class _Modes extends StatelessWidget {
  const _Modes({required this.selected, required this.onChanged});

  final TravelMode selected;
  final ValueChanged<TravelMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String label(TravelMode m) => switch (m) {
      TravelMode.driving => l10n.routeModeDriving,
      TravelMode.transit => l10n.routeModeTransit,
      TravelMode.walking => l10n.routeModeWalking,
    };
    AppIcons icon(TravelMode m) => switch (m) {
      TravelMode.driving => AppIcons.car,
      TravelMode.transit => AppIcons.transit,
      TravelMode.walking => AppIcons.walk,
    };
    final narrow = MediaQuery.textScalerOf(context).scale(10) >= 15;
    if (narrow) {
      return RadioGroup<TravelMode>(
        groupValue: selected,
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
        child: Column(
          key: const Key('routeMode'),
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in TravelMode.values)
              RadioListTile<TravelMode>(
                key: Key('routeMode-${m.name}'),
                value: m,
                contentPadding: EdgeInsets.zero,
                secondary: AppIcon(icon(m)),
                title: Text(label(m)),
              ),
          ],
        ),
      );
    }
    return Semantics(
      label: l10n.routeMode,
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<TravelMode>(
          key: const Key('routeMode'),
          style: const ButtonStyle(tapTargetSize: MaterialTapTargetSize.padded),
          segments: [
            for (final m in TravelMode.values)
              ButtonSegment(
                value: m,
                icon: AppIcon(icon(m), size: 18),
                label: Text(
                  label(m),
                  key: Key('routeMode-${m.name}'),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
          selected: {selected},
          selectedIcon: const AppIcon(AppIcons.selected, size: 18),
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      ),
    );
  }
}
