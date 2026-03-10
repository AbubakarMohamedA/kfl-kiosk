import 'package:flutter/material.dart';
import 'enterprise_dashboard_desktop.dart';
import 'enterprise_dashboard_mobile.dart';

class EnterpriseDashboard extends StatelessWidget {
  const EnterpriseDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return const EnterpriseDashboardMobile();
        } else {
          return const EnterpriseDashboardDesktop();
        }
      },
    );
  }
}
