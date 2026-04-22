import 'package:intl/intl.dart';

class DateFormatUtils {
  static String formatDate(DateTime date, String locale, String pattern) {
    try {
      // Try to use the standard DateFormat
      return DateFormat(pattern, locale).format(date);
    } catch (e) {
      // If the locale is not supported by intl, use a fallback
      if (locale == 'ceb') {
        // For Cebuano, use English date formatting but with Cebuano month names if needed
        final englishFormat = DateFormat(pattern, 'en').format(date);
        
        // If you want to replace English month names with Cebuano ones:
        // This is optional - you can customize this based on your needs
        /*
        final cebuanoMonths = {
          'January': 'Enero',
          'February': 'Pebrero',
          'March': 'Marso',
          'April': 'Abril',
          'May': 'Mayo',
          'June': 'Hunyo',
          'July': 'Hulyo',
          'August': 'Agosto',
          'September': 'Septiyembre',
          'October': 'Oktubre',
          'November': 'Nobyembre',
          'December': 'Disyembre',
        };
        
        String result = englishFormat;
        cebuanoMonths.forEach((english, cebuano) {
          result = result.replaceAll(english, cebuano);
        });
        return result;
        */
        
        // For now, just return the English format
        return englishFormat;
      }
      
      // For other unsupported locales, fall back to English
      return DateFormat(pattern, 'en').format(date);
    }
  }
}