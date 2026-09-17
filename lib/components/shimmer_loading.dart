import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Reusable generic shimmer loading placeholder
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.margin,
  });

  /// Factory for a standard rectangular card shimmer
  factory ShimmerLoading.card({
    double width = double.infinity,
    double height = 120.0,
    double borderRadius = 12.0,
    EdgeInsetsGeometry? margin,
  }) {
    return ShimmerLoading(
      width: width,
      height: height,
      borderRadius: borderRadius,
      margin: margin,
    );
  }

  /// Factory for a list tile (row) shimmer
  factory ShimmerLoading.listTile({
    EdgeInsetsGeometry? margin,
  }) {
    return ShimmerLoading(
      width: double.infinity,
      height: 72.0,
      borderRadius: 12.0,
      margin: margin ?? const EdgeInsets.only(bottom: 12),
    );
  }

  /// Factory for a circular avatar shimmer
  factory ShimmerLoading.avatar({
    double size = 48.0,
    EdgeInsetsGeometry? margin,
  }) {
    return ShimmerLoading(
      width: size,
      height: size,
      borderRadius: size / 2,
      margin: margin,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}
