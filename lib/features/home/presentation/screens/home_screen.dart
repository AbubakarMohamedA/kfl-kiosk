import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sss/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sss/core/config/app_role.dart';
import 'package:sss/core/configuration/domain/entities/app_configuration.dart';
import 'package:sss/core/constants/app_constants.dart';
import 'package:sss/di/injection.dart';
import 'package:sss/core/configuration/domain/repositories/configuration_repository.dart';
import 'package:sss/features/orders/presentation/screens/staff_panel.dart';

import 'package:sss/core/presentation/widgets/responsive_wrapper.dart';
import 'package:sss/features/home/presentation/screens/home_screen_mobile.dart';
import 'package:sss/features/home/presentation/screens/home_screen_tablet.dart';
import 'package:sss/features/home/presentation/screens/home_screen_desktop.dart';

import 'package:sss/features/auth/presentation/screens/login_screen.dart';
import 'package:sss/features/settings/presentation/screens/maintenance_screen.dart';
import 'package:sss/features/dashboard/presentation/screens/enterprise_dashboard.dart';
import 'package:sss/features/auth/domain/services/tenant_service.dart';
import 'package:sss/core/services/license_service.dart';
import 'package:sss/features/warehouse/domain/services/warehouse_service.dart';
import 'package:sss/core/database/app_database.dart';
import 'package:sss/features/warehouse/presentation/screens/staff_panel_warehouse.dart';
import 'package:sss/features/admin/presentation/screens/super_admin_screen.dart';

import 'package:sss/core/services/update_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkUpdates();
  }

  void _checkUpdates() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getIt<UpdateService>().checkAndPrompt(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppConfiguration>(
      future: getIt<ConfigurationRepository>().getConfiguration(),
      builder: (context, snapshot) {
        // Show loading screen while checking configuration
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        // 1. Get Role Configuration immediately
        final roleConfig = getIt<RoleConfig>();

        // 2. Specialized Build Bypass (Super Admin always has access)
        if (roleConfig.role == AppRole.superAdmin) {
          return const SuperAdminScreen();
        }

        // 3. Check Configuration (Standard Kiosk Flow)
        final config = snapshot.data ?? AppConfiguration();
        if (!config.isConfigured) {
          if (roleConfig.role == AppRole.kiosk) {
            return ResponsiveWrapper(
              mobile: const HomeScreenMobile(),
              tablet: const HomeScreenTablet(),
              desktop: const HomeScreenDesktop(),
              web: const HomeScreenDesktop(),
            );
          } else {
            // Specialized builds (Staff, Warehouse, etc.) always go to Login if unconfigured
            return const LoginScreen();
          }
        }

        // If configured, check for maintenance mode (Global or Tenant-specific)
        final tenantId = config.tenantId ?? '';
        final tenantService = TenantService();
        final licenseService = getIt<LicenseService>();
        final isSuperAdmin = tenantService.isSuperAdmin(tenantId);

        // 4. Check for License Expiration (Skip for 'alone' tier or Super Admin)
        if (config.tierId != 'alone' && !isSuperAdmin) {
           return FutureBuilder<bool>(
             future: licenseService.isExpired(),
             builder: (context, expirySnapshot) {
               if (expirySnapshot.data == true) {
                  return const MaintenanceScreen(
                    title: 'Kindly renew your license',
                    message: 'Your system access has been suspended due to an expired license.\nPlease contact the administrator to renew your key.',
                    icon: Icons.vpn_key_off,
                    iconColor: Colors.orange,
                  );
               }
               
               // Proceed with other checks if not expired
               return BlocBuilder<AuthBloc, AuthState>(
                 builder: (context, authState) {
                   // Ensure Staff/Manager are logged in
                   if ((roleConfig.role == AppRole.staff || roleConfig.role == AppRole.manager) && 
                       authState is AuthUnauthenticated) {
                     return const LoginScreen();
                   }
                   
                   if (authState is AuthLoading || authState is AuthInitial) {
                     return _buildLoadingScreen();
                   }
                   
                   return _buildResponsiveOrMaintenance(context, config, tenantId, tenantService, isSuperAdmin);
                 },
               );
             }
           );
        }

        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            // Ensure Staff/Manager are logged in
            if ((roleConfig.role == AppRole.staff || roleConfig.role == AppRole.manager) && 
                authState is AuthUnauthenticated) {
              return const LoginScreen();
            }
            
            if (authState is AuthLoading || authState is AuthInitial) {
              return _buildLoadingScreen();
            }

            return _buildResponsiveOrMaintenance(context, config, tenantId, tenantService, isSuperAdmin);
          },
        );
      },
    );
  }

  Widget _buildResponsiveOrMaintenance(
    BuildContext context, 
    AppConfiguration config, 
    String tenantId, 
    TenantService tenantService, 
    bool isSuperAdmin
  ) {
        // Check if system access is allowed
        if (!tenantService.canAccessSystem(
          tenantId, 
          isSuperAdmin: isSuperAdmin,
          fallbackTierId: config.tierId,
        )) {
          // Detect if it's a maintenance block or a subscription expiry block
          final tenants = tenantService.getTenants();
          final currentTenant = tenants.cast().cast().firstWhere(
            (t) => t.id == tenantId,
            orElse: () => null,
          );

          if (currentTenant?.status == 'Inactive') {
            return const MaintenanceScreen(
              title: 'Subscription Expired',
              message: 'Your SSS Kiosk subscription has expired.\nPlease contact support to renew your license.',
              icon: Icons.lock_clock,
              iconColor: Colors.red,
            );
          }

          return const MaintenanceScreen();
        }
        
        // ════════════════════════════════════════════════════════════════════
        // Role-Based UI Routing
        // ════════════════════════════════════════════════════════════════════
        final roleConfig = getIt<RoleConfig>();

        if (roleConfig.role == AppRole.superAdmin) {
          return const SuperAdminScreen();
        }

        if (roleConfig.role == AppRole.dashboard) {
          return const EnterpriseDashboard();
        }

        if (roleConfig.role == AppRole.warehouse) {
           // If we have a cached warehouse, show the staff panel directly
           if (config.warehouseId != null && config.branchId != null) {
              final warehouseService = WarehouseService(getIt<AppDatabase>());
              return FutureBuilder<List<dynamic>>(
                future: warehouseService.getWarehousesForBranch(config.branchId!),
                builder: (context, whSnapshot) {
                  if (whSnapshot.connectionState == ConnectionState.waiting) return _buildLoadingScreen();
                  final warehouses = whSnapshot.data ?? [];
                  final activeWarehouse = warehouses.cast().cast().firstWhere(
                    (w) => w.id == config.warehouseId,
                    orElse: () => null,
                  );
                  if (activeWarehouse != null) {
                    return StaffPanelWarehouse(warehouse: activeWarehouse);
                  }
                  return const LoginScreen();
                },
              );
           }
           return const LoginScreen();
        }

        if (roleConfig.role == AppRole.staff || roleConfig.role == AppRole.manager) {
          return const StaffPanel();
        }

        // Default Kiosk Routing
        return ResponsiveWrapper(
          mobile: const HomeScreenMobile(),
          tablet: const HomeScreenTablet(),
          desktop: const HomeScreenDesktop(),
          web: const HomeScreenDesktop(),
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