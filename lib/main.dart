import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:firebase_core/firebase_core.dart';
import 'package:sss/firebase_options.dart';
import 'package:sss/core/services/cloud_heartbeat_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:sss/core/config/api_config.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_manager/window_manager.dart';
import 'package:sss/core/constants/app_constants.dart';
import 'package:sss/features/auth/domain/repositories/auth_repository.dart';
import 'package:sss/di/injection.dart';
import 'package:sss/core/services/local_server_service.dart';
import 'package:sss/features/products/presentation/bloc/product/product_bloc.dart';
import 'package:sss/features/products/presentation/bloc/product/product_event.dart';
import 'package:sss/features/cart/presentation/bloc/cart/cart_bloc.dart';
import 'package:sss/features/cart/presentation/bloc/cart/cart_event.dart';
import 'package:sss/features/orders/presentation/bloc/order/order_bloc.dart';
import 'package:sss/features/orders/presentation/bloc/order/order_event.dart';
import 'package:sss/features/payment/presentation/bloc/payment/payment_bloc.dart';
import 'package:sss/features/settings/presentation/bloc/language/language_cubit.dart';
import 'package:sss/features/home/presentation/screens/home_screen.dart';
import 'package:sss/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sss/core/configuration/data/datasources/local_configuration_datasource.dart';
import 'package:sss/features/auth/presentation/screens/login_screen.dart';
import 'package:sss/core/platform/platform_info.dart';

import 'package:sss/core/config/app_role.dart';

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  await mainWithRole(AppRole.kiosk);
}

Future<void> mainWithRole(AppRole role) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup local image directory for direct access on host machines
  final docDir = await getApplicationDocumentsDirectory();
  ApiConfig.setLocalImagesDir(p.join(docDir.path, 'product_images'));

  // Lock orientation to portrait for mobile phones only
  if (Platform.isAndroid || Platform.isIOS) {
    final view = PlatformDispatcher.instance.views.first;
    final width = view.physicalSize.width / view.devicePixelRatio;
    final deviceType = PlatformInfo.getDeviceType(width);
    
    if (deviceType == DeviceType.mobile) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      // Allow all orientations for tablets
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  // Window size constraints for Desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      await windowManager.ensureInitialized();
      WindowOptions windowOptions = const WindowOptions(
        size: Size(1280, 800),
        minimumSize: Size(1024, 768),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.setMinimumSize(const Size(1024, 768));
        await windowManager.show();
        await windowManager.focus();
        
        // Final enforcement after a short delay for Linux window managers
        Future.delayed(const Duration(milliseconds: 600), () async {
          await windowManager.setMinimumSize(const Size(1024, 768));
        });
      });
      debugPrint('DEBUG: Window Manager initialized successfully');
    } catch (e) {
      debugPrint('DEBUG: Error initializing Window Manager: $e');
    }
  }
  
  // Initialize Firebase (Skip on Linux as it is not configured)
  if (!Platform.isLinux) {
    // For flavors, native platforms (Android/iOS) should rely on their
    // google-services.json / GoogleService-Info.plist which is parsed at build time
    // to map the correct app ID per flavor.
    if (TargetPlatform.android == defaultTargetPlatform || TargetPlatform.iOS == defaultTargetPlatform || TargetPlatform.macOS == defaultTargetPlatform) {
      await Firebase.initializeApp();
    } else {
      // Web and Windows use the generated options
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }


  final roleConfig = RoleConfig.forRole(role);
  // Register RoleConfig so any screen, like LoginScreen, can enforce the role
  if (!getIt.isRegistered<RoleConfig>()) {
    getIt.registerSingleton<RoleConfig>(roleConfig);
  }
  
  // 1. Setup DI & Load Config
  await setupDependencies();
  
  // 2. Check Configuration & Session
  final config = await getIt<LocalConfigurationDataSource>().getConfiguration();
  final isConfigured = config.isConfigured;
  final authRepo = getIt<AuthRepository>();
  final currentTenant = await authRepo.getCurrentTenant();
  final isAuthenticated = currentTenant != null;

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
  if (isAuthenticated || role == AppRole.kiosk) {
    // If authenticated OR in Kiosk mode, always start at Home (which handles internal routing)
    startScreen = const HomeScreen();
  } else if (role == AppRole.superAdmin) {
    // Unauthenticated Super Admin goes to Login
    startScreen = const LoginScreen();
  } else {
    // Other roles: Go to Home only if configured (to allow staff login), else Setup/Login
    startScreen = isConfigured ? const HomeScreen() : const LoginScreen();
  }
    // ════════════════════════════════════════════════════════════════════
  // 3. Cloud Status Check (Heartbeat) - NEW (Skip on Linux)
  // ════════════════════════════════════════════════════════════════════
  if (isConfigured && config.tenantId != null) {
    final heartbeat = getIt<CloudHeartbeatService>();
    heartbeat.start(); // Start periodic monitoring
  }

  if (config.isConfigured && config.tenantId != null) {
      final isEnterprise = config.tierId == 'enterprise';
      bool shouldStartServer = false;

      if (isEnterprise) {
        // Enterprise Tier: Manager role runs the server
        shouldStartServer = (role == AppRole.manager);
      } else {
        // Standard/Premium/Alone: Staff role runs the server
        shouldStartServer = (role == AppRole.staff);
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
          create: (context) => getIt<OrderBloc>()
            ..add(const LoadOrders())
            ..add(const WatchOrdersStarted()),
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