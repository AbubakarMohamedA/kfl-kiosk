import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/di/injection.dart';
import 'package:kfm_kiosk/presentation/bloc/product/product_bloc.dart';
import 'package:kfm_kiosk/presentation/bloc/product/product_event.dart';
import 'package:kfm_kiosk/presentation/bloc/cart/cart_bloc.dart';
import 'package:kfm_kiosk/presentation/bloc/cart/cart_event.dart';
import 'package:kfm_kiosk/presentation/bloc/order/order_bloc.dart';
import 'package:kfm_kiosk/presentation/bloc/order/order_event.dart';
import 'package:kfm_kiosk/presentation/bloc/payment/payment_bloc.dart';
import 'package:kfm_kiosk/presentation/bloc/language/language_cubit.dart';
import 'package:kfm_kiosk/presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup dependency injection
  await setupDependencies();
  
  runApp(const KFMKioskApp());
}

class KFMKioskApp extends StatelessWidget {
  const KFMKioskApp({super.key});

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
        home: const HomeScreen(),
      ),
    );
  }
}