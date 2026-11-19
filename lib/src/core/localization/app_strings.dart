import 'package:flutter/material.dart';
import 'app_translations.dart';

class AppStrings {
  AppStrings(this.language);
  final String language;
  static AppStrings of(BuildContext context) =>
      AppStrings(Localizations.localeOf(context).languageCode);
  String call(String key) => AppTranslations.text(key, language);
}
