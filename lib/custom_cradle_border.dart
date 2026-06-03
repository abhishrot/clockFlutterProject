import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A custom [InputBorder] that draws only the bottom, bottom-left, and bottom-right corners,
/// and extends up the sides by a specified height ratio.
class CradleInputBorder extends InputBorder {
  const CradleInputBorder({
    super.borderSide = const BorderSide(),
    this.borderRadius = const BorderRadius.all(Radius.circular(12.0)),
    this.sideHeightRatio = 0.25,
  });

  final BorderRadius borderRadius;
  final double sideHeightRatio;

  @override
  bool get isOutline => true;

  @override
  CradleInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? sideHeightRatio,
  }) {
    return CradleInputBorder(
      borderSide: borderSide ?? this.borderSide,
      borderRadius: borderRadius ?? this.borderRadius,
      sideHeightRatio: sideHeightRatio ?? this.sideHeightRatio,
    );
  }

  @override
  EdgeInsetsGeometry get dimensions {
    return EdgeInsets.only(
      bottom: borderSide.width,
      left: borderSide.width,
      right: borderSide.width,
      top: borderSide.width,
    );
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(borderRadius.resolve(textDirection).toRRect(rect).deflate(borderSide.width));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(borderRadius.resolve(textDirection).toRRect(rect));
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    final Paint paint = borderSide.toPaint();
    final RRect outer = borderRadius.resolve(textDirection).toRRect(rect);
    
    final double sideHeight = rect.height * sideHeightRatio;
    final Path path = Path();
    
    final double leftTopY = rect.bottom - sideHeight;
    final double rightTopY = rect.bottom - sideHeight;
    
    final double blRadiusX = outer.blRadiusX;
    final double blRadiusY = outer.blRadiusY;
    final double brRadiusX = outer.brRadiusX;
    final double brRadiusY = outer.brRadiusY;

    // Start on the left vertical side
    path.moveTo(rect.left, math.min(leftTopY, rect.bottom - blRadiusY));
    
    // Line down to start of bottom-left arc
    path.lineTo(rect.left, rect.bottom - blRadiusY);
    
    // Bottom-left arc
    path.arcToPoint(
      Offset(rect.left + blRadiusX, rect.bottom),
      radius: Radius.elliptical(blRadiusX, blRadiusY),
      clockwise: false,
    );
    
    // Bottom line
    path.lineTo(rect.right - brRadiusX, rect.bottom);
    
    // Bottom-right arc
    path.arcToPoint(
      Offset(rect.right, rect.bottom - brRadiusY),
      radius: Radius.elliptical(brRadiusX, brRadiusY),
      clockwise: false,
    );
    
    // Line up the right vertical side
    path.lineTo(rect.right, math.min(rightTopY, rect.bottom - brRadiusY));

    canvas.drawPath(path, paint);
  }

  @override
  ShapeBorder scale(double t) {
    return CradleInputBorder(
      borderSide: borderSide.scale(t),
      borderRadius: borderRadius * t,
      sideHeightRatio: sideHeightRatio,
    );
  }
}
