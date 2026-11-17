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
  static const stateTextMaxWidth = 320.0;
  static const minTouchTarget = 48.0;
}
