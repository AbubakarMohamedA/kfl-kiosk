import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kfm_kiosk/presentation/bloc/language/language_cubit.dart';
import 'package:kfm_kiosk/presentation/bloc/language/language_state.dart';
import 'package:kfm_kiosk/presentation/screens/tablet/catalog_screen_tablet.dart';

class HomeScreenTablet extends StatelessWidget {
  const HomeScreenTablet({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1B7A43), // Base green color
        ),
        child: Stack(
          children: [
            // Pattern background
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/images/Pattern.svg',
                fit: BoxFit.cover,
              ),
            ),
            
            // Main content
            SafeArea(
              child: Center(
                child: BlocBuilder<LanguageCubit, LanguageState>(
                  builder: (context, languageState) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo at center above welcome text
                        SizedBox(
                          width: size.width * 0.15,
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: size.height * 0.04),

                        // WELCOME TEXT (without "TO")
                        Text(
                          'WELCOME',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size.width * 0.05,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: size.height * 0.05),

                        // START ORDER BUTTON
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CatalogScreenTablet(
                                  language: languageState.languageCode,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.08,
                              vertical: size.height * 0.025,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8562A),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              languageState.translate('start_order'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: size.width * 0.03,
                                fontStyle: FontStyle.italic,
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.03),

                        // LANGUAGE BUTTONS (Custom implementation to match design)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLanguageButton(
                              context,
                              'English',
                              languageState.languageCode == 'en',
                              () {
                                context.read<LanguageCubit>().changeLanguage('en');
                              },
                            ),
                            const SizedBox(width: 16),
                            _buildLanguageButton(
                              context,
                              'Swahili',
                              languageState.languageCode == 'sw',
                              () {
                                context.read<LanguageCubit>().changeLanguage('sw');
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final size = MediaQuery.sizeOf(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.045,
          vertical: size.height * 0.018,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFFE8562A) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.black87,
            fontSize: size.width * 0.018,
            fontWeight: FontWeight.w600,
            fontFamily: 'Lato',
          ),
        ),
      ),
    );
  }
}