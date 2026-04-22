import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import '../main.dart' as app_main;  // Import with a namespace
import '../Pages/Dashboard.dart';
import '../Pages/History.dart';
import '../Pages/Scan.dart';
import '../Pages/AboutPage.dart';
import '../Pages/Results.dart';
import 'package:shimmer/shimmer.dart';

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  // Remove the shimmer gradient as it's not needed with the package

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.language),
      onSelected: (String value) async {
        try {
          // First, safely capture the current route
          String route = '/';
          
          // Try to get route from Navigator's current route
          final currentRoute = ModalRoute.of(context);
          if (currentRoute != null && currentRoute.settings.name != null) {
            route = currentRoute.settings.name!;
          } else {
            // Fallback detection based on widget hierarchy
            if (context.findAncestorWidgetOfExactType<Dashboard>() != null) {
              route = '/dashboard';
            } else if (context.findAncestorWidgetOfExactType<History>() != null) {
              route = '/history';
            } else if (context.findAncestorWidgetOfExactType<Scan>() != null) {
              route = '/scan';
            } else if (context.findAncestorWidgetOfExactType<AboutPage>() != null) {
              route = '/about';
            } else if (context.findAncestorWidgetOfExactType<Results>() != null) {
              route = '/results';
            }
          }
          
          if (kDebugMode) {
            print("Captured current route before locale change: $route");
          }
          
          // Store the route globally
          app_main.currentRoute = route;
          
          // Capture Results page parameters if we're on that page
          String? resultDisease;
          String? resultDate;
          String? resultImagePath;
          double? resultConfidence;
          
          if (route == '/results') {
            final resultsWidget = context.findAncestorWidgetOfExactType<Results>();
            if (resultsWidget != null) {
              resultDisease = resultsWidget.disease;
              resultDate = resultsWidget.date;
              resultImagePath = resultsWidget.imagePath;
              resultConfidence = resultsWidget.confidence;
              
              if (kDebugMode) {
                print("Captured Results parameters: $resultDisease, $resultDate");
              }
            }
          }
          
          // Show loading overlay
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: const Color.fromARGB(255, 144, 144, 144),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Shimmer.fromColors(
                      baseColor: const Color(0xFF80ED99),  // Light green
                      highlightColor: const Color(0xFF0AD1C8),  // Teal
                      period: const Duration(milliseconds: 1200),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF80ED99).withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.language,
                              size: 40,
                              color: Color(0xFF80ED99),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF80ED99).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              'changing_language'.tr(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF213A57),  // Dark blue
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
          
          // Change the locale
          await context.setLocale(Locale(value));
          
          if (kDebugMode) {
            print("New locale after change: ${context.locale.languageCode}");
          }
          
          // Add a small delay to show the loading animation
          await Future.delayed(const Duration(milliseconds: 800));
          
          // Close the loading dialog
          if (context.mounted) {
            Navigator.of(context).pop();
          }
          
          // Special handling for Results page
          if (route == '/results' && resultDisease != null && resultDate != null && context.mounted) {
            // Navigate back to the Results page with the same parameters
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Results(
                  disease: resultDisease!,
                  date: resultDate!,
                  imagePath: resultImagePath ?? '',
                  confidence: resultConfidence,
                ),
              ),
            );
          }
          // Handle other routes
          else if (route != '/' && context.mounted) {
            Navigator.pushReplacementNamed(context, route);
          } else if (route == '/' && context.mounted) {
            // For the welcome page, navigate to dashboard as that's where it redirects anyway
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        } catch (e) {
          if (kDebugMode) {
            print("Error during language change: $e");
          }
          // Close the loading dialog if it's open
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
          // Fallback to just changing the locale
          await context.setLocale(Locale(value));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'en',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              context.locale.languageCode == 'en' 
                  ? const Icon(Icons.check, size: 16) 
                  : const SizedBox(width: 16),
              const SizedBox(width: 8),
              const Text('English'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'tl',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              context.locale.languageCode == 'tl' 
                  ? const Icon(Icons.check, size: 16) 
                  : const SizedBox(width: 16),
              const SizedBox(width: 8),
              const Text('Tagalog'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'ceb',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              context.locale.languageCode == 'ceb' 
                  ? const Icon(Icons.check, size: 16) 
                  : const SizedBox(width: 16),
              const SizedBox(width: 8),
              const Text('Bisaya'),
            ],
          ),
        ),
      ],
    );
  }
}






















