import 'dart:io';
import 'package:flutter/material.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup dependency injection
  await setupDependencies();
  
  // 1. Check License
  final isLicensed = await getIt<LicenseService>().isLicensed();
  
  // 2. Check Configuration
  final config = await getIt<LocalConfigurationDataSource>().getConfiguration();
  final isConfigured = config.isConfigured;

  // 3. Determine Start Screen
  Widget startScreen;
  
  // Mobile Specific Logic
  bool isMobile = false;
  try {
    isMobile = Platform.isAndroid || Platform.isIOS;
  } catch (e) {
    // Web or other
  }

  if (isMobile) {
    final prefs = await SharedPreferences.getInstance();
    final isMobileConfigured = prefs.getBool('is_mobile_configured') ?? false;
    
    if (!isMobileConfigured) {
      startScreen = const ServerConnectionScreen();
    } else {
      final ip = prefs.getString('server_ip');
      if (ip != null) {
        ApiConfig.setBaseUrl('http://$ip:8080'); // ✅ Set Server URL
        ApiConfig.setFlavor(AppFlavor.prod);    // ✅ Force Remote Mode if configured
      }
      startScreen = const HomeScreen(); // ✅ NEW: Go to Home instead of Login
    }
  } else {
    // Desktop Logic
    startScreen = (isLicensed && isConfigured) 
        ? const HomeScreen() 
        : const LoginScreen();

    // Attempt to start local server if previously configured
    if (config.isConfigured && config.tenantId != null) {
      final serverService = getIt<LocalServerService>();
      serverService.setActiveTenantId(
        config.tenantId!, 
        branchId: config.branchId,
        warehouseId: config.warehouseId,
        tierId: config.tierId,
      );
      serverService.start();
    }
  }
  
  runApp(KFMKioskApp(home: startScreen));
}

class KFMKioskApp extends StatelessWidget {
  final Widget home;
  
  const KFMKioskApp({super.key, required this.home});

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
        title: AppConstants.appName,
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