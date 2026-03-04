import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kfm_kiosk/firebase_options.dart';
import 'package:kfm_kiosk/core/services/cloud_heartbeat_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:kfm_kiosk/core/config/api_config.dart';
import 'package:kfm_kiosk/features/auth/presentation/screens/server_connection_screen.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/di/injection.dart';
import 'package:kfm_kiosk/core/services/local_server_service.dart';
import 'package:kfm_kiosk/features/products/presentation/bloc/product/product_bloc.dart';
import 'package:kfm_kiosk/features/products/presentation/bloc/product/product_event.dart';
import 'package:kfm_kiosk/features/cart/presentation/bloc/cart/cart_bloc.dart';
import 'package:kfm_kiosk/features/cart/presentation/bloc/cart/cart_event.dart';
import 'package:kfm_kiosk/features/orders/presentation/bloc/order/order_bloc.dart';
import 'package:kfm_kiosk/features/orders/presentation/bloc/order/order_event.dart';
import 'package:kfm_kiosk/features/payment/presentation/bloc/payment/payment_bloc.dart';
import 'package:kfm_kiosk/features/settings/presentation/bloc/language/language_cubit.dart';
import 'package:kfm_kiosk/features/home/presentation/screens/home_screen.dart';
import 'package:kfm_kiosk/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kfm_kiosk/core/services/license_service.dart';
import 'package:kfm_kiosk/core/configuration/data/datasources/local_configuration_datasource.dart';
import 'package:kfm_kiosk/features/settings/presentation/screens/configuration_screen.dart';
import 'package:kfm_kiosk/features/auth/presentation/screens/login_screen.dart';

import 'package:kfm_kiosk/core/config/app_role.dart';

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  await mainWithRole(AppRole.kiosk);
}

Future<void> mainWithRole(AppRole role) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (Skip on Linux as it is not configured)
  if (!Platform.isLinux) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Setup dependency injection
  await setupDependencies();

  final roleConfig = RoleConfig.forRole(role);
  // Register RoleConfig so any screen, like LoginScreen, can enforce the role
  if (!getIt.isRegistered<RoleConfig>()) {
    getIt.registerSingleton<RoleConfig>(roleConfig);
  }
  
  // 1. Check License
  final isLicensed = await getIt<LicenseService>().isLicensed();
  
  // 2. Check Configuration
  final config = await getIt<LocalConfigurationDataSource>().getConfiguration();
  final isConfigured = config.isConfigured;

  // 3. Determine Start Screen
  Widget startScreen;
  // Attempt to load previously configured IP for Remote Terminal mode
  final prefs = await SharedPreferences.getInstance();
  final ip = prefs.getString('server_ip');
  if (ip != null && ip.isNotEmpty) {
    ApiConfig.setBaseUrl('http://$ip:8080');
    ApiConfig.setFlavor(AppFlavor.prod);
  }

  // Unified Start Screen Logic (Regardless of platform)
  if (role == AppRole.superAdmin) {
    // Super Admin ALWAYS starts at Login Screen for security
    startScreen = const LoginScreen();
  } else if (role == AppRole.kiosk) {
    // Kiosk ALWAYS starts at HomeScreen
    startScreen = const HomeScreen();
  } else {
    // Other roles start at Home if licensed & configured, else Login
    startScreen = (isLicensed && isConfigured) 
        ? const HomeScreen() 
        : const LoginScreen();
  }
    // ════════════════════════════════════════════════════════════════════
  // 5. Cloud Status Check (Heartbeat) - NEW (Skip on Linux)
  // ════════════════════════════════════════════════════════════════════
  if (!Platform.isLinux) {
    final heartbeat = getIt<CloudHeartbeatService>();
    // ignore: unawaited_futures
    heartbeat.checkTenantStatus(); // Fire and forget on startup, will update state/UI later
  }

  if (config.isConfigured && config.tenantId != null) {
      final isEnterprise = config.tierId == 'enterprise';
      bool shouldStartServer = false;

      if (isEnterprise) {
        // Enterprise Tier: Staff role runs the server (formerly Branch/Manager)
        shouldStartServer = (role == AppRole.staff);
      } else {
        // Standard/Premium/Alone: Kiosk or Staff can run the server
        shouldStartServer = (role == AppRole.kiosk || role == AppRole.staff);
      }

      final serverService = getIt<LocalServerService>();
      serverService.setActiveTenantId(
        config.tenantId!, 
        branchId: config.branchId,
        warehouseId: config.warehouseId,
        tierId: config.tierId,
      );

      if (shouldStartServer) {
        serverService.start();
        debugPrint('Local Server Started for Role: $role in Tier: ${config.tierId}');
      } else {
        debugPrint('Local Server Bypassed. Role ($role) acting as Client in Tier: ${config.tierId}');
      }
    }
  
  runApp(KFMKioskApp(home: startScreen, roleConfig: roleConfig));
}

class KFMKioskApp extends StatelessWidget {
  final Widget home;
  final RoleConfig roleConfig;
  
  const KFMKioskApp({super.key, required this.home, required this.roleConfig});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<ProductBloc>()..add(const LoadProducts()),
        ),
        BlocProvider(
          create: (context) => getIt<CartBloc>()..add(const LoadCart()),
        ),
        BlocProvider(
          create: (context) => getIt<OrderBloc>()..add(const LoadOrders()),
        ),
        BlocProvider(
          create: (context) => getIt<PaymentBloc>(),
        ),
        BlocProvider(
          create: (context) => getIt<LanguageCubit>(),
        ),
        BlocProvider(
          create: (context) => getIt<AuthBloc>()..add(AuthCheckRequested()),
        ),
      ],
      child: MaterialApp(
        navigatorKey: globalNavigatorKey,
        title: roleConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(AppColors.primaryBlue),
            primary: const Color(AppColors.primaryBlue),
            secondary: const Color(AppColors.secondaryGold),
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: home,
      ),
    );
  }
}