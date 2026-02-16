import 'package:flutter/material.dart';
import 'package:kfm_kiosk/core/platform/platform_info.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? web;

  const ResponsiveWrapper({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.web,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = PlatformInfo.getDeviceType(constraints.maxWidth);

        // If web is specified and we're on web, use web version
        if (PlatformInfo.isWeb && web != null) {
          return web!;
        }

        // Route to appropriate platform
        switch (deviceType) {
          case DeviceType.mobile:
            return mobile;

          case DeviceType.tablet:
            return tablet ?? mobile;

          case DeviceType.desktop:
            return desktop ?? tablet ?? mobile;

          case DeviceType.web:
            return web ?? desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints, DeviceType deviceType) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = PlatformInfo.getDeviceType(constraints.maxWidth);
        return builder(context, constraints, deviceType);
      },
    );
  }
}

// Helper extension for responsive values
extension ResponsiveExtension on BuildContext {
  bool get isMobile {
    final width = MediaQuery.of(this).size.width;
    return ResponsiveUtils.isMobile(width);
  }

  bool get isTablet {
    final width = MediaQuery.of(this).size.width;
    return ResponsiveUtils.isTablet(width);
  }

  bool get isDesktop {
    final width = MediaQuery.of(this).size.width;
    return ResponsiveUtils.isDesktop(width);
  }

  double responsiveFontSize({
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    final width = MediaQuery.of(this).size.width;
    return ResponsiveUtils.getResponsiveFontSize(
      width,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  double responsivePadding({
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    final width = MediaQuery.of(this).size.width;
    return ResponsiveUtils.getResponsivePadding(
      width,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}