import 'package:flutter/material.dart';
import 'super_admin_desktop.dart';
import 'super_admin_mobile.dart';

class SuperAdminScreen extends StatelessWidget {
  const SuperAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return const SuperAdminMobile();
        } else {
          return const SuperAdminDesktop();
        }
      },
    );
  }
}
