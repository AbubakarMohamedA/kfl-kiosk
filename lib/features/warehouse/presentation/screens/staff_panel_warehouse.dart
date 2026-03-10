import 'package:flutter/material.dart';
import '../../domain/entities/warehouse.dart';
import 'staff_panel_warehouse_desktop.dart';
import 'staff_panel_warehouse_mobile.dart';

class StaffPanelWarehouse extends StatelessWidget {
  final Warehouse warehouse;

  const StaffPanelWarehouse({
    super.key,
    required this.warehouse,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return StaffPanelWarehouseMobile(warehouse: warehouse);
        } else {
          return StaffPanelWarehouseDesktop(warehouse: warehouse);
        }
      },
    );
  }
}