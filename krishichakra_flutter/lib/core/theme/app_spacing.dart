import 'package:flutter/material.dart';

/// Spacing tokens from Stitch Tailwind spacing config.
class AppSpacing {
  AppSpacing._();

  static const double xs = 8;   // space-xs: 0.5rem
  static const double sm = 12;  // space-sm: 0.75rem
  static const double md = 16;  // space-md / margin: 1rem
  static const double lg = 24;  // space-lg: 1.5rem
  static const double xl = 40;  // space-xl: 2.5rem

  // Page horizontal margin
  static const double pageMargin = 16; // margin: 1rem
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: pageMargin);

  // Touch target minimum (56px mandated throughout Stitch)
  static const double minTouchTarget = 56;

  // Header / bottom nav
  static const double headerHeight = 80;
  static const double bottomNavHeight = 80;
}

/// Border radius tokens matching Stitch Tailwind config.
class AppRadius {
  AppRadius._();

  static const double sm = 4;    // DEFAULT: 0.25rem
  static const double md = 8;    // lg: 0.5rem
  static const double lg = 12;   // xl: 0.75rem
  static const double full = 999; // full: 9999px

  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius fullRadius = BorderRadius.all(Radius.circular(full));
}
