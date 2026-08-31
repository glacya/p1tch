import 'package:flutter/widgets.dart';

/// Normalizes [locale] into the lowercase "language-country" key format
/// used by Category.nameFor (see assets/levels/category.json's "locale"
/// fields, e.g. "ko-kr"/"en-us"). Locale.countryCode can be null (a device
/// may report just a language), so it's handled explicitly rather than
/// interpolated directly, which could produce "en-null".
String localeKey(Locale locale) {
  final country = locale.countryCode;
  if (country == null) return locale.languageCode.toLowerCase();
  return '${locale.languageCode}-$country'.toLowerCase();
}

/// [localeKey] for the current platform locale.
String currentLocaleKey() =>
    localeKey(WidgetsBinding.instance.platformDispatcher.locale);
