import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';

enum DeviceType {
  mobile,
  tablet,
  desktop,
  web,
}

class PlatformInfo {
  static bool get isWeb => kIsWeb;
  
  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }
  
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
  
  static bool get isAndroid {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }
  
  static bool get isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }
  
  static bool get isWindows {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }
  
  static bool get isMacOS {
    if (kIsWeb) return false;
    return Platform.isMacOS;
  }
  
  static bool get isLinux {
    if (kIsWeb) return false;
    return Platform.isLinux;
  }
  
  static DeviceType getDeviceType(double width) {
    if (isWeb) return DeviceType.web;
    
    if (isMobile) {
      return width >= 600 ? DeviceType.tablet : DeviceType.mobile;
    }
    
    if (isDesktop) {
      return DeviceType.desktop;
    }
    
    // Fallback based on width
    if (width < 600) {
      return DeviceType.mobile;
    } else if (width < 1200) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }
}

class ResponsiveUtils {
  static bool isMobile(double width) => width < 600;
  static bool isTablet(double width) => width >= 600 && width < 1200;
  static bool isDesktop(double width) => width >= 1200;
  static bool isLargeDesktop(double width) => width >= 1800;
  
  static double getResponsiveFontSize(double width, {
    double mobile = 14,
    double tablet = 16,
    double desktop = 18,
  }) {
    if (isMobile(width)) return mobile;
    if (isTablet(width)) return tablet;
    return desktop;
  }
  
  static double getResponsivePadding(double width, {
    double mobile = 16,
    double tablet = 24,
    double desktop = 32,
  }) {
    if (isMobile(width)) return mobile;
    if (isTablet(width)) return tablet;
    return desktop;
  }
  
  static int getGridCrossAxisCount(double width) {
    if (isMobile(width)) return 2;
    if (isTablet(width)) return 3;
    if (isLargeDesktop(width)) return 5;
    return 4;
  }
}