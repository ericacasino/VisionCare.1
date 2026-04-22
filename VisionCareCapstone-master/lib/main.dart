import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'utils/custom_material_localizations.dart';
import 'Pages/Dashboard.dart';
import 'Pages/Scan.dart';
import 'Pages/History.dart';
import 'Pages/AboutPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await EasyLocalization.ensureInitialized();
  } catch (e) {
    if (kDebugMode) {
      print("EasyLocalization initialization error: $e");
    }
  }
  
  try {
    await initializeDateFormatting('en', null);
  } catch (e) {
    if (kDebugMode) {
      print("Date formatting initialization error: $e");
    }
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
      ],
      path: 'Assets/translations',
      fallbackLocale: const Locale('en'),
      useOnlyLangCode: true,
      saveLocale: true,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        const CustomMaterialLocalizations(),
        const CustomCupertinoLocalizations(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        ...context.localizationDelegates,
      ],
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: 'VisionCare',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const Dashboard(),
      routes: {
        '/dashboard': (context) => const Dashboard(),
        '/history': (context) => const History(),
        '/scan': (context) => const Scan(),
        '/about': (context) => const AboutPage(),
      },
    );
  }
}
