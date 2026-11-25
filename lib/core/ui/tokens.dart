/// Spacing tokens (design-system.md pkt 4) and shapes (pkt 5), in dp.
abstract final class Space {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
  static const s12 = 48.0;
}

abstract final class Radii {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 28.0;
}

/// Layout limits (layout.md): max content column on medium/expanded windows.
abstract final class LayoutLimits {
  static const contentMaxWidth = 560.0;

  /// Window width where compact ends and medium starts (layout.md, M3 window classes).
  static const mediumWindowMinWidth = 600.0;

  /// Compact window (< 600 dp). The width is rounded like Android's `screenWidthDp`:
  /// the density is a float (288 dpi -> 1.8000000715), so a 600 dp window reaches
  /// Flutter as 599.99998 dp (QA PR #171 B1).
  static bool isCompactWidth(double width) =>
      width.round() < mediumWindowMinWidth;
  static const stateTextMaxWidth = 320.0;
  static const minTouchTarget = 48.0;

  /// Bottom action button on medium/expanded windows (EK-07, ek-07-ai-busy.md).
  static const bottomButtonMaxWidth = 360.0;
}
