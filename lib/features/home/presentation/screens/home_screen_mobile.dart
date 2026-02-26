import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/features/settings/presentation/bloc/language/language_cubit.dart';
import 'package:kfm_kiosk/features/settings/presentation/bloc/language/language_state.dart';
import 'package:kfm_kiosk/core/widgets/common/language_selector.dart';
import 'package:kfm_kiosk/features/warehouse/presentation/screens/catalog_screen_mobile.dart';
import 'package:kfm_kiosk/features/products/presentation/bloc/product/product_bloc.dart';
import 'package:kfm_kiosk/features/products/presentation/bloc/product/product_event.dart';

class HomeScreenMobile extends StatelessWidget {
  const HomeScreenMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(AppColors.primaryBlue),
              Color(AppColors.lightBlue),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: BlocBuilder<LanguageCubit, LanguageState>(
                builder: (context, languageState) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha:0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'KFM',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Color(AppColors.primaryBlue),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Welcome Text
                      Text(
                        languageState.translate('welcome'),
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        languageState.translate('company_name'),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        languageState.translate('self_service'),
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // Start Order Button
                      ElevatedButton(
                        onPressed: () {
                          // Refresh products for the connected server
                          context.read<ProductBloc>().add(const LoadProducts());
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CatalogScreenMobile(
                                language: languageState.languageCode,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(AppColors.primaryBlue),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                        ),
                        child: Text(
                          languageState.translate('start_order'),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Language Selector
                      const LanguageSelector(),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}