import 'package:flutter/material.dart';
import '../utils/form_theme_constants.dart';

/// Reusable custom text form field with standardized styling
class StandardizedTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLines;
  final int? minLines;
  final String? hintText;

  const StandardizedTextFormField({
    Key? key,
    this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.minLines,
    this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: FormThemeConstants.inputTextStyle,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      minLines: minLines,
      validator: validator,
      decoration: FormThemeConstants.buildInputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon,
        hintText: hintText,
      ),
    );
  }
}

/// Reusable custom dropdown form field with standardized styling
class StandardizedDropdownFormField extends StatefulWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String labelText;
  final IconData prefixIcon;
  final String? Function(String?)? validator;

  const StandardizedDropdownFormField({
    Key? key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.labelText,
    required this.prefixIcon,
    this.validator,
  }) : super(key: key);

  @override
  State<StandardizedDropdownFormField> createState() =>
      _StandardizedDropdownFormFieldState();
}

class _StandardizedDropdownFormFieldState
    extends State<StandardizedDropdownFormField> {
  late String _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _selectedValue,
      items: widget.items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() {
            _selectedValue = newValue;
          });
          widget.onChanged(newValue);
        }
      },
      validator: widget.validator,
      decoration: FormThemeConstants.buildDropdownDecoration(
        labelText: widget.labelText,
        prefixIcon: widget.prefixIcon,
      ),
      dropdownColor: FormThemeConstants.backgroundColor,
      style: FormThemeConstants.inputTextStyle,
      icon: const Icon(
        Icons.arrow_drop_down,
        color: FormThemeConstants.borderColor,
      ),
    );
  }
}

/// Standardized submit button
class StandardizedFormButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double height;
  final double borderRadius;

  const StandardizedFormButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.height = 55,
    this.borderRadius = 30,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: FormThemeConstants.primaryBrandColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 4,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Display unique ID header with standardized styling
class UniqueIdHeader extends StatelessWidget {
  final String uniqueId;

  const UniqueIdHeader({
    Key? key,
    required this.uniqueId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(FormThemeConstants.smallSpacing),
      decoration: BoxDecoration(
        border: Border.all(
          color: FormThemeConstants.primaryBrandColor,
          width: 2,
        ),
        borderRadius:
            BorderRadius.circular(FormThemeConstants.borderRadius),
      ),
      child: Text(
        'Unique ID: $uniqueId',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: FormThemeConstants.primaryBrandColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
