// lib/extensions/color_extensions.dart
import 'package:flutter/material.dart';

extension DynamicColor on Color {
  Color dynamicVariant(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      // Return a darker variant for dark mode
      return withOpacity(0.8);
    }
    return this;
  }
}