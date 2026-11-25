/// Google Maps directions link (ADR-0017 pkt 1, format from ADR-0007).
///
/// Variant C: Tamitu never reads the phone position. "My location" = no `origin`
/// parameter (Google Maps sets its own start); "Previous place" and "Your stay" pass
/// plan text as `origin`. Destination and origin are always text ("name, locality,
/// trip destination"), never coordinates. The link is neither stored nor logged.
library;

/// `travelmode` of the link (EK-09 "Czym").
enum TravelMode {
  driving('driving'),
  transit('transit'),
  walking('walking');

  const TravelMode(this.param);

  /// Value of the `travelmode` parameter (also the stored preference value).
  final String param;

  /// Mode used before the user picks one (EK-09: Transit at first use, UX11).
  static const initial = TravelMode.transit;

  static TravelMode? fromParam(String? value) {
    for (final m in values) {
      if (m.param == value) return m;
    }
    return null;
  }
}

/// Start of the route (EK-09 "Skąd"), in display order.
enum RouteStartKind { myLocation, previousPlace, lodging }

/// A place from the plan as text for the link: "{name}, {locality}, {trip destination}"
/// (ADR-0017). Blank parts and a locality equal to the trip destination are skipped so
/// the text does not repeat itself; whitespace is collapsed.
String placeQuery(String name, String locality, String tripDestination) =>
    _join([name, locality, tripDestination]);

/// Lodging as `origin`: "{lodging}, {trip destination}" (ADR-0017).
String lodgingQuery(String lodging, String tripDestination) =>
    _join([lodging, tripDestination]);

String _join(List<String> parts) {
  final out = <String>[];
  for (final p in parts) {
    final t = p.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.isEmpty) continue;
    if (out.any((o) => o.toLowerCase() == t.toLowerCase())) continue;
    out.add(t);
  }
  return out.join(', ');
}

/// `https://www.google.com/maps/dir/?api=1&destination=…&travelmode=…[&origin=…]`.
///
/// [origin] null or blank → no `origin` parameter at all ("My location"). Encoding is
/// done by [Uri] (percent-encoding of `&`, `#`, `%`, Polish letters…), never by string
/// concatenation.
Uri directionsUri({
  required String destination,
  required TravelMode mode,
  String? origin,
}) {
  final o = origin?.trim();
  return Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': destination.trim(),
    'travelmode': mode.param,
    if (o != null && o.isNotEmpty) 'origin': o,
  });
}
