import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/presentation/bloc/language/language_cubit.dart';
import 'package:kfm_kiosk/presentation/bloc/language/language_state.dart';
import 'package:kfm_kiosk/presentation/widgets/common/language_selector.dart';
import 'package:kfm_kiosk/presentation/screens/desktop/catalog_screen_desktop.dart';

class HomeScreenDesktop extends StatelessWidget {
  const HomeScreenDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Material(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: screenWidth * 0.8,
              maxHeight: screenHeight * 0.85,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(AppColors.primaryBlue),
                  Color(AppColors.lightBlue),
                ],
              ),
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            child: Stack(
              children: [
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(64.0),
                      child: BlocBuilder<LanguageCubit, LanguageState>(
                        builder: (context, languageState) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo
                              Container(
                                width: 200,
                                height: 200,
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
                                      fontSize: 80,
                                      fontWeight: FontWeight.bold,
                                      color: Color(AppColors.primaryBlue),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 48),

                              // Welcome Text
                              Text(
                                languageState.translate('welcome'),
                                style: const TextStyle(
                                  fontSize: 48,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                languageState.translate('company_name'),
                                style: const TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                languageState.translate('self_service'),
                                style: const TextStyle(
                                  fontSize: 32,
                                  color: Colors.white70,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 64),

                              // Start Order Button
                              ElevatedButton(
                                onPressed: () {
                                  // Close the dialog first
                                  Navigator.pop(context);
                                  
                                  // Then navigate to catalog
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CatalogScreenDesktop(
                                        language: languageState.languageCode,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(AppColors.primaryBlue),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 80,
                                    vertical: 40,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 8,
                                ),
                                child: Text(
                                  languageState.translate('start_order'),
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 48),

                              // Language Selector
                              const LanguageSelector(isCompact: false),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Close Button
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.white,
                    iconSize: 40,
                    tooltip: 'Close',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}