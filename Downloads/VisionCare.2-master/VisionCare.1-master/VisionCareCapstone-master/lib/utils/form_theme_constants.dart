import 'package:flutter/material.dart';

/// Centralized form styling constants to ensure uniformity across the app
class FormThemeConstants {
  // Colors
  static const Color primaryBrandColor = Color(0xFF5ED3F2);
  static const Color backgroundColor = Color(0xFF011627);
  static const Color borderColor = Colors.white70;
  static const Color textColor = Colors.white;
  static const Color labelColor = Colors.white70;
  static const Color errorColor = Colors.red;

  // Border Radius
  static const double borderRadius = 8.0;

  // Spacing
  static const double fieldSpacing = 20.0;
  static const double smallSpacing = 12.0;
  static const double largeSpacing = 30.0;

  // Input Decoration for Text Fields
  static InputDecoration buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      prefixIcon: Icon(prefixIcon, color: borderColor),
      labelText: labelText,
      hintText: hintText,
      labelStyle: const TextStyle(color: labelColor),
      hintStyle: const TextStyle(color: labelColor),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: primaryBrandColor, width: 2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: errorColor, width: 1.5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: errorColor, width: 2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: smallSpacing,
        vertical: smallSpacing,
      ),
    );
  }

  // Input Decoration for Dropdowns (matches TextFields)
  static InputDecoration buildDropdownDecoration({
    required String labelText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(prefixIcon, color: borderColor),
      labelText: labelText,
      labelStyle: const TextStyle(color: labelColor),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: primaryBrandColor, width: 2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: smallSpacing,
        vertical: smallSpacing,
      ),
    );
  }

  // Text Style for input fields
  static const TextStyle inputTextStyle = TextStyle(
    color: textColor,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  // Text Style for labels
  static const TextStyle labelTextStyle = TextStyle(
    color: labelColor,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
}

/// Validation helper functions
class FormValidators {
  // Validate full name (not empty, min 2 characters)
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Full name must be at least 2 characters';
    }
    // Only reject numbers and very specific symbols (@#$%^&*(){}[]=+;:<>?/|)
    if (RegExp(r'[0-9@#$%^&*(){}\[\]=+;:<>?/|]').hasMatch(value)) {
      return 'Full name cannot contain numbers or special symbols';
    }
    return null;
  }

  // Validate address (not empty, min 5 characters)
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    if (value.length < 5) {
      return 'Address must be at least 5 characters';
    }
    return null;
  }

  // Validate age (between 0 and 150)
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Age must be a valid number';
    }
    if (age < 0 || age > 150) {
      return 'Age must be between 0 and 150';
    }
    return null;
  }

  // Validate birthday (not empty)
  static String? validateBirthday(String? value) {
    if (value == null || value.isEmpty) {
      return 'Birthday is required';
    }
    return null;
  }

  // Validate gender (not empty)
  static String? validateGender(String? value) {
    if (value == null || value.isEmpty) {
      return 'Gender is required';
    }
    return null;
  }

  // Validate contact number (phone)
  static String? validateContactNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Contact number is required';
    }
    if (value.length < 7) {
      return 'Contact number must be at least 7 digits';
    }
    if (value.length > 15) {
      return 'Contact number must not exceed 15 digits';
    }
    // Allow numbers, spaces, hyphens, and plus sign
    if (!RegExp(r'^[\d\s\-+()]+$').hasMatch(value)) {
      return 'Contact number contains invalid characters';
    }
    return null;
  }
}
