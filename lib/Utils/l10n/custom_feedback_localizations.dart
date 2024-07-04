import 'dart:async';
import 'dart:convert';

import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'app_localizations.dart';

class CustomFeedbackLocalizations implements FeedbackLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;

  CustomFeedbackLocalizations(this.locale);

  static CustomFeedbackLocalizations? of(BuildContext context) {
    return Localizations.of<CustomFeedbackLocalizations>(
        context, CustomFeedbackLocalizations);
  }

  Future<bool> load() async {
    String jsonString = await rootBundle
        .loadString('Assets/languages/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return true;
  }

  @override
  String get draw => _localizedStrings['feedbackDraw'] ?? '';

  @override
  String get navigate => _localizedStrings['feedbackNavigate'] ?? '';

  @override
  String get submitButtonText =>
      _localizedStrings['feedbackSubmitButton'] ?? '';

  @override
  String get feedbackDescriptionText =>
      _localizedStrings['feedbackDescription'] ?? '';
}

class CustomFeedbackLocalizationsDelegate
    extends LocalizationsDelegate<FeedbackLocalizations> {
  const CustomFeedbackLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLanguage.keys
        .contains(locale.languageCode);
  }

  @override
  Future<FeedbackLocalizations> load(Locale locale) async {
    CustomFeedbackLocalizations localizations =
        CustomFeedbackLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(LocalizationsDelegate<FeedbackLocalizations> old) => false;
}
