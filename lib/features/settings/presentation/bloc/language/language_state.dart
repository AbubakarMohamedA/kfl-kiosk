import 'package:equatable/equatable.dart';
import 'package:sss/core/constants/app_constants.dart';

class LanguageState extends Equatable {
  final String languageCode;

  const LanguageState(this.languageCode);

  bool get isEnglish => languageCode == AppConstants.languageEnglish;
  bool get isSwahili => languageCode == AppConstants.languageSwahili;

  String translate(String key) {
    return AppStrings.get(key, languageCode);
  }

  @override
  List<Object?> get props => [languageCode];
}