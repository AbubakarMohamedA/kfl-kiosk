import 'package:flutter/material.dart';
import 'package:kfm_kiosk/core/configuration/domain/entities/app_configuration.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/di/injection.dart';
import 'package:kfm_kiosk/core/configuration/domain/repositories/configuration_repository.dart';
import 'package:kfm_kiosk/features/orders/presentation/screens/staff_panel_desktop.dart';
import 'package:kfm_kiosk/features/admin/presentation/screens/tenant_setup_screen.dart';
import 'package:kfm_kiosk/core/presentation/widgets/responsive_wrapper.dart';
import 'package:kfm_kiosk/features/home/presentation/screens/home_screen_mobile.dart';
import 'package:kfm_kiosk/features/home/presentation/screens/home_screen_tablet.dart';
import 'package:kfm_kiosk/features/home/presentation/screens/home_screen_desktop.dart';
import 'package:kfm_kiosk/features/home/presentation/screens/home_screen_desktop.dart';
import 'package:kfm_kiosk/features/auth/presentation/screens/login_screen_desktop.dart';
import 'package:kfm_kiosk/features/settings/presentation/screens/maintenance_screen.dart';
import 'package:kfm_kiosk/features/auth/domain/services/tenant_service.dart';

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
             mobile: const TenantSetupScreen(),
             tablet: const TenantSetupScreen(),
             desktop: const LoginScreenDesktop(),
             web: const LoginScreenDesktop(),
           );
        }

        // If configured, check for maintenance mode (Global or Tenant-specific)
        final tenantId = config.tenantId ?? '';
        final tenantService = TenantService();
        final isSuperAdmin = tenantService.isSuperAdmin(tenantId);
        
        // Check if system access is allowed
        if (!tenantService.canAccessSystem(tenantId, isSuperAdmin: isSuperAdmin)) {
          return const MaintenanceScreen();
        }

        // If configured and allowed, show the main app
        return ResponsiveWrapper(
          mobile: const HomeScreenMobile(),
          tablet: const HomeScreenTablet(),
          desktop: const StaffPanelDesktop(),
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
              const Color(AppColors.primaryBlue).withOpacity(0.8),
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
                  color: Colors.white.withOpacity(0.2),
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
                'KFL Kiosk',
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
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}