import 'package:flutter/material.dart';
import 'package:kfm_kiosk/presentation/screens/desktop/staff_panel_desktop.dart';
import 'package:kfm_kiosk/presentation/screens/responsive_wrapper.dart';
import 'package:kfm_kiosk/presentation/screens/mobile/home_screen_mobile.dart';
import 'package:kfm_kiosk/presentation/screens/tablet/home_screen_tablet.dart';
import 'package:kfm_kiosk/presentation/screens/desktop/home_screen_desktop.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      mobile: const HomeScreenMobile(),
      tablet: const HomeScreenTablet(),
      desktop: const StaffPanelDesktop(),
      // Web can use desktop version or have its own
      web: const HomeScreenDesktop(),
    );
  }
}