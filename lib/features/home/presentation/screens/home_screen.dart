import 'package:flutter/material.dart';
import 'package:kfm_kiosk/core/configuration/domain/entities/app_configuration.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/di/injection.dart';
import 'package:kfm_kiosk/core/configuration/domain/repositories/configuration_repository.dart';
import 'package:kfm_kiosk/features/orders/presentation/screens/staff_panel_desktop.dart';

import 'package:kfm_kiosk/core/presentation/widgets/responsive_wrapper.dart';
import 'package:kfm_kiosk/features/home/presentation/screens/home_screen_mobile.dart';
import 'package:kfm_kiosk/features/home/presentation/screens/home_screen_tablet.dart';
import 'package:kfm_kiosk/features/home/presentation/screens/home_screen_desktop.dart';

import 'package:kfm_kiosk/features/auth/presentation/screens/login_screen.dart';
import 'package:kfm_kiosk/features/settings/presentation/screens/maintenance_screen.dart';
import 'package:kfm_kiosk/features/dashboard/presentation/screens/enterprise_dashboard.dart';
import 'package:kfm_kiosk/features/auth/domain/services/tenant_service.dart';
import 'package:kfm_kiosk/features/warehouse/domain/services/warehouse_service.dart';
import 'package:kfm_kiosk/core/database/app_database.dart';
import 'package:kfm_kiosk/features/warehouse/presentation/screens/staff_panel_warehouse.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppConfiguration>(
      future: getIt<ConfigurationRepository>().getConfiguration(),
      builder: (context, snapshot) {
        // Show loading screen while checking configuration
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        // Get configuration (or default if error)
        final config = snapshot.data ?? AppConfiguration();

        // If not configured, show tenant setup screen
        // If not configured, show login/setup based on platform
        if (!config.isConfigured) {
           return ResponsiveWrapper(
             mobile: const HomeScreenMobile(),
             tablet: const HomeScreenTablet(),
             desktop: const LoginScreen(),
             web: const LoginScreen(),
           );
        }

        // If configured, check for maintenance mode (Global or Tenant-specific)
        final tenantId = config.tenantId ?? '';
        final tenantService = TenantService();
        final isSuperAdmin = tenantService.isSuperAdmin(tenantId);
        
        // Check if system access is allowed
        if (!tenantService.canAccessSystem(
          tenantId, 
          isSuperAdmin: isSuperAdmin,
          fallbackTierId: config.tierId,
        )) {
          return const MaintenanceScreen();
        }
        
        // If the configuration explicitly indicates we are in a Warehouse Session, restore it!
        if (config.warehouseId != null && config.branchId != null) {
          final warehouseService = WarehouseService(getIt<AppDatabase>());
          return FutureBuilder<List<dynamic>>(
            future: warehouseService.getWarehousesForBranch(config.branchId!),
            builder: (context, whSnapshot) {
              if (whSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
              }
              
              final warehouses = whSnapshot.data ?? [];
              final activeWarehouse = warehouses.cast().cast().firstWhere(
                (w) => w.id == config.warehouseId,
                orElse: () => null,
              );
              
              if (activeWarehouse != null) {
                return ResponsiveWrapper(
                  mobile: const HomeScreenMobile(),
                  tablet: const HomeScreenTablet(),
                  desktop: StaffPanelWarehouse(warehouse: activeWarehouse),
                  web: StaffPanelWarehouse(warehouse: activeWarehouse),
                );
              }
              
              // Fallback to desktop if the specific warehouse couldn't be loaded
              return ResponsiveWrapper(
                mobile: const HomeScreenMobile(),
                tablet: const HomeScreenTablet(),
                desktop: const StaffPanelDesktop(),
                web: const HomeScreenDesktop(),
              );
            },
          );
        }

        // Determine the approriate desktop and web screen based on setup
        Widget desktopScreen;
        if (config.tierId == 'enterprise' && config.branchId == null) {
          desktopScreen = const EnterpriseDashboard();
        } else {
          desktopScreen = const StaffPanelDesktop();
        }

        // If configured and allowed, show the main app
        return ResponsiveWrapper(
          mobile: const HomeScreenMobile(),
          tablet: const HomeScreenTablet(),
          desktop: desktopScreen,
          // Web can use desktop version or have its own
          web: const HomeScreenDesktop(),
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(AppColors.primaryBlue),
              const Color(AppColors.primaryBlue).withValues(alpha: 0.8),
              const Color(0xFF0A6F38),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.store_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'SSS Kiosk',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}