import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable loading spinner component with customizable size, stroke width, and color.
class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const AppLoadingIndicator({
    super.key,
    this.size = 20.0,
    this.strokeWidth = 2.5,
    this.color,
  });

  /// Factory helper for full-screen or centered container loading states.
  static Widget centered({double size = 32.0, Color? color}) {
    return Center(
      child: AppLoadingIndicator(
        size: size,
        strokeWidth: 3.0,
        color: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color ?? CareDropTheme.royalBlue,
      ),
    );
  }
}
