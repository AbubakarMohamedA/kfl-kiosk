import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/presentation/bloc/language/language_cubit.dart';
import 'package:kfm_kiosk/presentation/bloc/language/language_state.dart';
import 'package:kfm_kiosk/presentation/widgets/common/language_selector.dart';
import 'package:kfm_kiosk/presentation/screens/tablet/catalog_screen_tablet.dart';

class HomeScreenTablet extends StatelessWidget {
  const HomeScreenTablet({super.key});

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
              padding: const EdgeInsets.all(48.0),
              child: BlocBuilder<LanguageCubit, LanguageState>(
                builder: (context, languageState) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'KFM',
                            style: TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: Color(AppColors.primaryBlue),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Welcome Text
                      Text(
                        languageState.translate('welcome'),
                        style: const TextStyle(
                          fontSize: 38,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        languageState.translate('company_name'),
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        languageState.translate('self_service'),
                        style: const TextStyle(
                          fontSize: 26,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 56),

                      // Start Order Button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CatalogScreenTablet(
                                language: languageState.languageCode,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(AppColors.primaryBlue),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 64,
                            vertical: 28,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                        ),
                        child: Text(
                          languageState.translate('start_order'),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Language Selector
                      const LanguageSelector(isCompact: false),
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