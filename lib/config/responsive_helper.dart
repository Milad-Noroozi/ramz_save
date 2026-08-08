import 'package:flutter/material.dart';

/// کلاس کمکی برای مدیریت اندازه‌های ریسپانسیو در تمام صفحات
class ResponsiveHelper {
  final BuildContext context;
  late final Size _size;
  late final double width;
  late final double height;

  ResponsiveHelper(this.context) {
    _size = MediaQuery.of(context).size;
    width = _size.width;
    height = _size.height;
  }

  // 📐 Padding و Margin
  double get horizontalPadding => width * 0.05;
  double get verticalPadding => height * 0.02;
  
  double get smallPadding => width * 0.025;
  double get mediumPadding => width * 0.05;
  double get largePadding => width * 0.075;

  // 🎨 Icon Sizes
  double get iconSizeSmall => width * 0.05;
  double get iconSizeMedium => width * 0.075;
  double get iconSizeLarge => width * 0.115;
  
  // 📝 Font Sizes
  double get fontSizeSmall => width * 0.03;
  double get fontSizeMedium => width * 0.038;
  double get fontSizeLarge => width * 0.05;
  double get fontSizeXLarge => width * 0.06;
  
  // 📦 Card Sizes
  double get cardWidth => (width - (horizontalPadding * 2) - 20) / 3;
  double get cardHeight => height * 0.085;
  
  // 🔘 Border Radius
  double get borderRadiusSmall => width * 0.025;
  double get borderRadiusMedium => width * 0.05;
  double get borderRadiusLarge => width * 0.075;
  
  // 📏 Spacing
  double get spacingXSmall => height * 0.005;
  double get spacingSmall => height * 0.01;
  double get spacingMedium => height * 0.015;
  double get spacingLarge => height * 0.02;
  double get spacingXLarge => height * 0.03;

  // 🎯 Custom Responsive Values
  double responsive(double percentage) => width * percentage;
  double responsiveHeight(double percentage) => height * percentage;
  
  // 📱 Breakpoints
  bool get isSmallScreen => width < 360;
  bool get isMediumScreen => width >= 360 && width < 768;
  bool get isLargeScreen => width >= 768;
}

/// Extension برای دسترسی آسان‌تر
extension ResponsiveContext on BuildContext {
  ResponsiveHelper get responsive => ResponsiveHelper(this);
}