import 'package:flutter/material.dart';

/// Centralised premium dark design tokens for AppSukran.
///
/// "Sade ama hissi son derece güçlü" — a restrained, premium dark visual
/// language. Every screen pulls its colours, radii, paddings and reusable
/// surfaces from here so the system stays pixel-consistent.
class AppDark {
  AppDark._();

  // ---------------------------------------------------------------------------
  // Colour palette
  // ---------------------------------------------------------------------------

  /// Background gradient — deep emerald to forest green (vertical).
  /// Pulled directly from the Şükran App logo's green field.
  static const Color bgTop = Color(0xFF08210F);
  static const Color bgBottom = Color(0xFF103D24);

  /// Card / container surface — deep green fume.
  static const Color surface = Color(0xFF143A26);

  /// Slightly lifted surface for nested elements / dividers.
  static const Color surfaceHigh = Color(0xFF1C4A31);

  /// Input field background.
  static const Color inputFill = Color(0xFF173E29);

  /// Accent / primary — warm, saturated soft gold (matte, never neon).
  /// Matches the logo's gold heart & lettering.
  static const Color accent = Color(0xFFDDA15E);

  /// Brighter gold used for highlights, glows and gradients.
  static const Color accentBright = Color(0xFFE9C46A);

  /// Text colours.
  static const Color textPrimary = Color(0xFFF5EFE0); // warm ivory
  static const Color textSecondary = Color(0xFFA9BCAD); // muted sage

  /// Status colours.
  static const Color success = Color(0xFF6FCF97);
  static const Color danger = Color(0xFFFF8A80);

  /// Hairline borders on dark surfaces — faint gold.
  static const Color hairline = Color(0x33DDA15E); // gold @ ~20%

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
