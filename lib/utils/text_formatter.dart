import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Parses text with formatting markers and returns a RichText widget
/// Markers:
/// - **text** for bold
/// - *text* for italic  
/// - __text__ for underline
/// - • for bullet points
class FormattedTextWidget extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final Color? color;
  final double? fontSize;

  const FormattedTextWidget({
    Key? key,
    required this.text,
    this.baseStyle,
    this.color,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultStyle = baseStyle ?? GoogleFonts.inter(
      color: color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
      fontSize: fontSize ?? 14,
      height: 1.4,
    );

    return Text.rich(
      TextSpan(
        children: _parseText(text, defaultStyle),
      ),
    );
  }

  List<TextSpan> _parseText(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    int currentIndex = 0;

    while (currentIndex < text.length) {
      // Check for bold (**text**)
      if (currentIndex + 2 < text.length && 
          text.substring(currentIndex, currentIndex + 2) == '**') {
        final endIndex = text.indexOf('**', currentIndex + 2);
        if (endIndex != -1) {
          final boldText = text.substring(currentIndex + 2, endIndex);
          spans.add(TextSpan(
            text: boldText,
            style: baseStyle.copyWith(fontWeight: FontWeight.bold),
          ));
          currentIndex = endIndex + 2;
          continue;
        }
      }

      // Check for underline (__text__)
      if (currentIndex + 2 < text.length && 
          text.substring(currentIndex, currentIndex + 2) == '__') {
        final endIndex = text.indexOf('__', currentIndex + 2);
        if (endIndex != -1) {
          final underlineText = text.substring(currentIndex + 2, endIndex);
          spans.add(TextSpan(
            text: underlineText,
            style: baseStyle.copyWith(decoration: TextDecoration.underline),
          ));
          currentIndex = endIndex + 2;
          continue;
        }
      }

      // Check for italic (*text*) - must come after bold check
      if (currentIndex + 1 < text.length && 
          text[currentIndex] == '*' &&
          (currentIndex == 0 || text[currentIndex - 1] != '*')) {
        final endIndex = text.indexOf('*', currentIndex + 1);
        if (endIndex != -1 && 
            (endIndex + 1 >= text.length || text[endIndex + 1] != '*')) {
          final italicText = text.substring(currentIndex + 1, endIndex);
          spans.add(TextSpan(
            text: italicText,
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ));
          currentIndex = endIndex + 1;
          continue;
        }
      }

      // No formatting found, add regular text until next marker
      final nextBold = text.indexOf('**', currentIndex);
      final nextUnderline = text.indexOf('__', currentIndex);
      final nextItalic = _findNextItalic(text, currentIndex);
      
      final markers = [nextBold, nextUnderline, nextItalic]
          .where((i) => i != -1)
          .toList();
      
      final nextMarker = markers.isEmpty ? text.length : markers.reduce((a, b) => a < b ? a : b);
      
      if (nextMarker > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, nextMarker),
          style: baseStyle,
        ));
      }
      
      currentIndex = nextMarker;
      
      // Safety check to prevent infinite loop
      if (currentIndex >= text.length && spans.isEmpty) {
        spans.add(TextSpan(text: text, style: baseStyle));
        break;
      }
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: baseStyle));
    }

    return spans;
  }

  int _findNextItalic(String text, int start) {
    int index = text.indexOf('*', start);
    while (index != -1) {
      // Check if it's a single * (not **)
      final isSingle = (index == 0 || text[index - 1] != '*') &&
                      (index + 1 >= text.length || text[index + 1] != '*');
      if (isSingle) return index;
      index = text.indexOf('*', index + 1);
    }
    return -1;
  }
}

/// Helper function to strip formatting markers from text
String stripFormatting(String text) {
  return text
      .replaceAll('**', '')
      .replaceAll('__', '')
      .replaceAll(RegExp(r'(?<!\*)\*(?!\*)'), ''); // Remove single * but not **
}
