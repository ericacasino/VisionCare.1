import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Custom delegate that extends the default one but adds support for 'ceb' locale
class CustomMaterialLocalizations extends LocalizationsDelegate<MaterialLocalizations> {
  const CustomMaterialLocalizations();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'tl', 'ceb'].contains(locale.languageCode);
  }

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    if (locale.languageCode == 'ceb') {
      return SynchronousFuture<MaterialLocalizations>(
        const CebMaterialLocalizations()
      );
    }
    return GlobalMaterialLocalizations.delegate.load(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<MaterialLocalizations> old) => false;
}

// Custom implementation for Cebuano Material localizations
class CebMaterialLocalizations extends DefaultMaterialLocalizations {
  const CebMaterialLocalizations();

  @override
  String get okButtonLabel => 'OK';
  
  @override
  String get cancelButtonLabel => 'Kanselahon';
  
  @override
  String get closeButtonLabel => 'Sirado';
  
  @override
  String get searchFieldLabel => 'Pangita';
  
  @override
  String get selectAllButtonLabel => 'Pilion Tanan';
  
  @override
  String get nextMonthTooltip => 'Sunod nga bulan';
  
  @override
  String get previousMonthTooltip => 'Miaging bulan';
  
  @override
  String get nextPageTooltip => 'Sunod nga pahina';
  
  @override
  String get previousPageTooltip => 'Miaging pahina';
  
  @override
  String get showMenuTooltip => 'Ipakita ang menu';
  
  @override
  String aboutListTileTitleRaw(String applicationName) => 'Mahitungod sa $applicationName';
  
  @override
  String get licensesPageTitle => 'Mga Lisensya';
  
  @override
  String pageRowsInfoTitle(int firstRow, int lastRow, int rowCount, bool rowCountIsApproximate) {
    return 'Mga linya $firstRow–$lastRow sa $rowCount';
  }
  
  @override
  String get modalBarrierDismissLabel => 'Isalikway';
}

// Custom delegate for Cupertino that adds support for 'ceb' locale
class CustomCupertinoLocalizations extends LocalizationsDelegate<CupertinoLocalizations> {
  const CustomCupertinoLocalizations();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'tl', 'ceb'].contains(locale.languageCode);
  }

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    if (locale.languageCode == 'ceb') {
      return SynchronousFuture<CupertinoLocalizations>(
        const CebCupertinoLocalizations()
      );
    }
    return GlobalCupertinoLocalizations.delegate.load(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<CupertinoLocalizations> old) => false;
}

// Custom implementation for Cebuano Cupertino localizations
class CebCupertinoLocalizations extends DefaultCupertinoLocalizations {
  const CebCupertinoLocalizations();

  @override
  String get alertDialogLabel => 'Pahibalo';
  
  @override
  String get copyButtonLabel => 'Kopyaha';
  
  @override
  String get cutButtonLabel => 'Putla';
  
  @override
  String get pasteButtonLabel => 'I-paste';
  
  @override
  String get selectAllButtonLabel => 'Pilion Tanan';
}






