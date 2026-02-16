import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'language_state.dart';

class LanguageCubit extends Cubit<LanguageState> {
  LanguageCubit() : super(const LanguageState(AppConstants.languageEnglish));

  void changeLanguage(String languageCode) {
    if (languageCode == AppConstants.languageEnglish ||
        languageCode == AppConstants.languageSwahili) {
      emit(LanguageState(languageCode));
    }
  }

  void toggleLanguage() {
    if (state.isEnglish) {
      emit(const LanguageState(AppConstants.languageSwahili));
    } else {
      emit(const LanguageState(AppConstants.languageEnglish));
    }
  }

  void setEnglish() {
    emit(const LanguageState(AppConstants.languageEnglish));
  }

  void setSwahili() {
    emit(const LanguageState(AppConstants.languageSwahili));
  }
}