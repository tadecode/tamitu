import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

/// Icon meanings from design-system.md pkt 8. The ONLY place that imports `hugeicons`
/// (ADR-0010 pkt 2): replacing the icon set means changing this file only.
/// Add meanings here as screens need them.
enum AppIcons {
  back,
  openExternal,
  info,
  warning,
  error,
  offline,
  privacy,
  language,
  selected,
  appUpdate,
  aiInfo,
  calendar,
  clock,
  more,
  route,
  transit,
  walk,
  add,
  remove,
  trips,
  deviceOnly,
  flight,
  car,
  delete,
}

const _data = <AppIcons, List<List<dynamic>>>{
  AppIcons.back: HugeIcons.strokeRoundedArrowLeft01,
  AppIcons.openExternal: HugeIcons.strokeRoundedLinkSquare02,
  AppIcons.info: HugeIcons.strokeRoundedInformationCircle,
  AppIcons.warning: HugeIcons.strokeRoundedAlert02,
  AppIcons.error: HugeIcons.strokeRoundedAlertCircle,
  AppIcons.offline: HugeIcons.strokeRoundedWifiOff01,
  AppIcons.privacy: HugeIcons.strokeRoundedShield01,
  AppIcons.language: HugeIcons.strokeRoundedGlobe02,
  AppIcons.selected: HugeIcons.strokeRoundedTick02,
  AppIcons.appUpdate: HugeIcons.strokeRoundedReload,
  AppIcons.aiInfo: HugeIcons.strokeRoundedSparkles,
  AppIcons.calendar: HugeIcons.strokeRoundedCalendar03,
  AppIcons.clock: HugeIcons.strokeRoundedClock01,
  AppIcons.more: HugeIcons.strokeRoundedMoreVertical,
  AppIcons.route: HugeIcons.strokeRoundedRoute02,
  AppIcons.transit: HugeIcons.strokeRoundedBus01,
  AppIcons.walk: HugeIcons.strokeRoundedWalking,
  AppIcons.add: HugeIcons.strokeRoundedPlusSign,
  AppIcons.remove: HugeIcons.strokeRoundedMinusSign,
  AppIcons.trips: HugeIcons.strokeRoundedLuggage01,
  AppIcons.deviceOnly: HugeIcons.strokeRoundedSmartPhone01,
  AppIcons.flight: HugeIcons.strokeRoundedAirplaneLanding01,
  AppIcons.car: HugeIcons.strokeRoundedCar01,
  AppIcons.delete: HugeIcons.strokeRoundedDelete02,
};

/// Draws an icon from the app set. Colour is inherited from [IconTheme] (role colours),
/// sizes per design-system.md: 24 (standard), 18 (in buttons/chips), 48 (states).
/// Icons are decorative for TalkBack unless [semanticLabel] is given.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final AppIcons icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final glyph = HugeIcon(
      icon: _data[icon]!,
      size: size ?? theme.size ?? 24,
      color: color ?? theme.color,
      strokeWidth: 1.5,
    );
    if (semanticLabel == null) return ExcludeSemantics(child: glyph);
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(child: glyph),
    );
  }
}
