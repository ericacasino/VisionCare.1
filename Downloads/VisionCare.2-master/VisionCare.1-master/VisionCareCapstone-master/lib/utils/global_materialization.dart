import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class GlobalMaterialLocalizations extends DefaultMaterialLocalizations {
  const GlobalMaterialLocalizations(this.locale) : super();

  @override
  final Locale locale;

  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _GlobalMaterialLocalizationsDelegate();

  @override
  String get closeButtonLabel => 'Isara';

  @override
  String get searchFieldLabel => 'Paghanap';

  @override
  String get cancelButtonLabel => 'Kanselahin';

  @override
  String get modalBarrierDismissLabel => 'I-dismiss';

  @override
  String get okButtonLabel => 'OK';

  @override
  String get saveButtonLabel => 'I-save';

  @override
  String get selectAllButtonLabel => 'Piliin Lahat';

  @override
  String get copyButtonLabel => 'Kopyahin';

  @override
  String get cutButtonLabel => 'I-cut';

  @override
  String get pasteButtonLabel => 'I-paste';

  @override
  String get deleteButtonLabel => 'Tanggalin';

  @override
  String formatCompactDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  String formatFullDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  String formatMediumDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  String formatShortDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  String formatShortMonthDay(DateTime date) {
    return '${date.month}/${date.day}';
  }
}

class _GlobalMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _GlobalMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'tl', 'ceb'].contains(locale.languageCode);
  }

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return SynchronousFuture<MaterialLocalizations>(
        GlobalMaterialLocalizations(locale));
  }

  @override
  bool shouldReload(_GlobalMaterialLocalizationsDelegate old) => false;
}