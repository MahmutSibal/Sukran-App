import 'package:flutter/material.dart';

/// Centralised siyah-beyaz (monokrom) design tokens for AppSukran.
///
/// "Sade ama hissi son derece güçlü" — saf siyah zemin, beyaz vurgu; tüm renkler
/// gri tonlarına indirgenmiştir. Every screen pulls its colours, radii, paddings
/// and reusable surfaces from here so the system stays pixel-consistent.
class AppDark {
  AppDark._();

  // ---------------------------------------------------------------------------
  // Colour palette
  // ---------------------------------------------------------------------------

  /// Background gradient — saf siyah → koyu gri (vertical).
  static const Color bgTop = Color(0xFF000000);
  static const Color bgBottom = Color(0xFF141414);

  /// Card / container surface — koyu gri.
  static const Color surface = Color(0xFF1C1C1C);

  /// Slightly lifted surface for nested elements / dividers.
  static const Color surfaceHigh = Color(0xFF2A2A2A);

  /// Input field background.
  static const Color inputFill = Color(0xFF161616);

  /// Accent / primary — BEYAZ (üzerine siyah yazı).
  static const Color accent = Color(0xFFFAFAFA);

  /// Brighter accent used for highlights, glows and gradients.
  static const Color accentBright = Color(0xFFFFFFFF);

  /// Text colours.
  static const Color textPrimary = Color(0xFFFFFFFF); // beyaz
  static const Color textSecondary = Color(0xFFA3A3A3); // gri

  /// Status colours.
  static const Color success = Color(0xFFE5E5E5);
  static const Color danger = Color(0xFF9A9A9A);

  /// Hairline borders on dark surfaces — beyaz @ ~20%.
  static const Color hairline = Color(0x33FFFFFF);

  // ---------------------------------------------------------------------------
  // Geometry
  // ---------------------------------------------------------------------------

  /// Large modules, dialogs, bottom sheets.
  static const double radiusModule = 28;
  static const double radiusModuleLg = 32;

  /// Buttons and input fields.
  static const double radiusControl = 16;

  /// Default screen edge padding.
  static const EdgeInsets screenPadding = EdgeInsets.all(20);

  // ---------------------------------------------------------------------------
  // Reusable gradients
  // ---------------------------------------------------------------------------

  /// The signature vertical background gradient.
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgBottom],
  );

  /// Gold call-to-action gradient.
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentBright, accent],
  );

  // ---------------------------------------------------------------------------
  // Reusable decorations
  // ---------------------------------------------------------------------------

  /// Standard surface card decoration (fume + hairline + soft shadow).
  static BoxDecoration surfaceCard({double radius = radiusModule}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: hairline),
      boxShadow: const [
        BoxShadow(color: Color(0x66000000), blurRadius: 30, offset: Offset(0, 18)),
      ],
    );
  }

  /// A full-bleed background container for any screen body.
  static Widget scaffoldBackground({required Widget child}) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: backgroundGradient),
      child: child,
    );
  }
}
