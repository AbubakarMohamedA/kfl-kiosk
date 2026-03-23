enum AppRole {
  kiosk,
  warehouse,
  superAdmin,
  dashboard,
  staff,
  manager,
}

class RoleConfig {
  final AppRole role;
  final String appName;
  final bool showKioskUI;
  final bool showWarehouseUI;
  final bool showAdminUI;
  final bool showDashboardUI;
  final bool showStaffUI;
  final bool showManagerUI;

  const RoleConfig({
    required this.role,
    required this.appName,
    this.showKioskUI = false,
    this.showWarehouseUI = false,
    this.showAdminUI = false,
    this.showDashboardUI = false,
    this.showStaffUI = false,
    this.showManagerUI = false,
  });

  factory RoleConfig.forRole(AppRole role) {
    switch (role) {
      case AppRole.warehouse:
        return const RoleConfig(
          role: AppRole.warehouse,
          appName: 'SSS Warehouse Admin',
          showWarehouseUI: true,
        );
      case AppRole.superAdmin:
        return const RoleConfig(
          role: AppRole.superAdmin,
          appName: 'SSS Super Admin',
          showAdminUI: true,
        );
      case AppRole.dashboard:
        return const RoleConfig(
          role: AppRole.dashboard,
          appName: 'SSS Enterprise Dashboard',
          showDashboardUI: true,
        );
      case AppRole.staff:
        return const RoleConfig(
          role: AppRole.staff,
          appName: 'SSS Staff & Admin Panel',
          showStaffUI: true,
        );
      case AppRole.manager:
        return const RoleConfig(
          role: AppRole.manager,
          appName: 'SSS Manager Admin',
          showManagerUI: true,
        );
      case AppRole.kiosk:
      return const RoleConfig(
          role: AppRole.kiosk,
          appName: 'SSS Kiosk Terminal',
          showKioskUI: true,
        );
    }
  }
}
