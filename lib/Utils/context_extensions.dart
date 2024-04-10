import 'package:flutter/material.dart';

import '../Utils/l10n/app_localizations.dart';

extension ContextExtensions on BuildContext {
  String translate(String text) {
    return AppLocalizations.of(this).translate(text);
  }
}
