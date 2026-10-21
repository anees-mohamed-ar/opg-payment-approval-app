import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Apple iOS SF Pro Dynamic Tracking Helper using Public Sans
TextStyle getAppleStyle({
  double fontSize = 14,
  FontWeight? fontWeight,
  Color? color,
  FontStyle? fontStyle,
  double? height,
  TextDecoration? decoration,
}) {
  // Apple's dynamic tracking formula:
  // Tightens large display headings, loosens small captions/subtext
  double tracking = 0.0;
  if (fontSize >= 28) {
    tracking = -0.55;
  } else if (fontSize >= 20) {
    tracking = -0.45;
  } else if (fontSize >= 16) {
    tracking = -0.25;
  } else if (fontSize >= 14) {
    tracking = -0.15;
  } else if (fontSize <= 12) {
    tracking = 0.20;
  } else if (fontSize <= 10) {
    tracking = 0.35;
  }

  return GoogleFonts.publicSans(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.normal,
    letterSpacing: tracking,
    color: color,
    fontStyle: fontStyle,
    height: height,
    decoration: decoration,
  );
}

/// Creates a complete Public Sans TextTheme tailored with Apple dynamic tracking
TextTheme createAppleTextTheme(TextTheme base) {
  final publicSansBase = GoogleFonts.publicSansTextTheme(base);

  return publicSansBase.copyWith(
    displayLarge: getAppleStyle(fontSize: 57, fontWeight: FontWeight.w400),
    displayMedium: getAppleStyle(fontSize: 45, fontWeight: FontWeight.w400),
    displaySmall: getAppleStyle(fontSize: 36, fontWeight: FontWeight.w400),
    headlineLarge: getAppleStyle(fontSize: 32, fontWeight: FontWeight.w700),
    headlineMedium: getAppleStyle(fontSize: 28, fontWeight: FontWeight.w700),
    headlineSmall: getAppleStyle(fontSize: 24, fontWeight: FontWeight.w600),
    titleLarge: getAppleStyle(fontSize: 20, fontWeight: FontWeight.w600),
    titleMedium: getAppleStyle(fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall: getAppleStyle(fontSize: 14, fontWeight: FontWeight.w500),
    bodyLarge: getAppleStyle(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: getAppleStyle(fontSize: 14, fontWeight: FontWeight.w400),
    bodySmall: getAppleStyle(fontSize: 12, fontWeight: FontWeight.w400),
    labelLarge: getAppleStyle(fontSize: 14, fontWeight: FontWeight.w500),
    labelMedium: getAppleStyle(fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall: getAppleStyle(fontSize: 10, fontWeight: FontWeight.w500),
  );
}
