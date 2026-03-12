import 'package:flutter/material.dart';
import 'package:sss/core/presentation/widgets/responsive_wrapper.dart';
import 'package:sss/features/orders/presentation/screens/staff_panel_desktop.dart';
import 'package:sss/features/orders/presentation/screens/staff_panel_mobile.dart';

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
