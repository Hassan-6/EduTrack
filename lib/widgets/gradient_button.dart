import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double? width;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;
  final bool enabled;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    this.height = 56,
    this.borderRadius = 16,
    this.textStyle,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: enabled ? themeProvider.gradient : null,
        color: enabled ? null : Theme.of(context).disabledColor.withOpacity(0.3),
        boxShadow: enabled ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            offset: const Offset(0, 10),
            blurRadius: 15,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            offset: const Offset(0, 4),
            blurRadius: 6,
          )
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: enabled ? onPressed : null,
          child: Center(
            child: Text(
              text,
              style: textStyle ?? GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GradientIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;
  final String? tooltip;

  const GradientIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 48,
    this.iconSize = 24,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    final button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: themeProvider.gradient,
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onPressed,
          child: Center(
            child: Icon(
              icon,
              size: iconSize,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
