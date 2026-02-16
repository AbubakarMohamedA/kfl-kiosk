import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/features/settings/presentation/bloc/language/language_cubit.dart';
import 'package:kfm_kiosk/features/settings/presentation/bloc/language/language_state.dart';

class LanguageSelector extends StatelessWidget {
  final bool isCompact;
  final Color? backgroundColor;
  final Color? selectedColor;

  const LanguageSelector({
    super.key,
    this.isCompact = false,
    this.backgroundColor,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, state) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageButton(
              context,
              'English',
              AppConstants.languageEnglish,
              state.isEnglish,
            ),
            SizedBox(width: isCompact ? 8 : 12),
            _buildLanguageButton(
              context,
              'Kiswahili',
              AppConstants.languageSwahili,
              state.isSwahili,
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageButton(
    BuildContext context,
    String label,
    String code,
    bool isSelected,
  ) {
    return ElevatedButton(
      onPressed: () {
        context.read<LanguageCubit>().changeLanguage(code);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? (selectedColor ?? Colors.white)
            : (backgroundColor ?? Colors.white24),
        foregroundColor: isSelected
            ? const Color(AppColors.primaryBlue)
            : Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 16 : 24,
          vertical: isCompact ? 8 : 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: isSelected ? 4 : 0,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isCompact ? 14 : 18,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}