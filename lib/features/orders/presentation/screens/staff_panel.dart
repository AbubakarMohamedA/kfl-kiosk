import 'package:flutter/material.dart';
import 'package:kfm_kiosk/core/presentation/widgets/responsive_wrapper.dart';
import 'package:kfm_kiosk/features/orders/presentation/screens/staff_panel_desktop.dart';
import 'package:kfm_kiosk/features/orders/presentation/screens/staff_panel_mobile.dart';

class StaffPanel extends StatelessWidget {
  const StaffPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveWrapper(
      mobile: StaffPanelMobile(),
      tablet: StaffPanelDesktop(),
      desktop: StaffPanelDesktop(),
      web: StaffPanelDesktop(),
    );
  }
}
