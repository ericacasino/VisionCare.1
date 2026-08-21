import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import './Scan.dart';
import './Dashboard.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/standardized_form_fields.dart';
import '../utils/form_theme_constants.dart';

class PatientDetails extends StatefulWidget {
  const PatientDetails({super.key});

  @override
  State<PatientDetails> createState() => _PatientDetailsState();
}

class _PatientDetailsState extends State<PatientDetails> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  String _selectedGender = 'Male';

  void _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    setState(() {
      _ageController.text = age.toString();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _ageController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FormThemeConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: FormThemeConstants.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Dashboard()),
            );
          },
        ),
        title: const Text(
          'Patient Details',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(FormThemeConstants.fieldSpacing),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Full Name
              StandardizedTextFormField(
                controller: _nameController,
                labelText: 'Full Name',
                prefixIcon: Icons.person,
                validator: FormValidators.validateFullName,
                hintText: 'Enter patient\'s full name',
              ),
              const SizedBox(height: FormThemeConstants.fieldSpacing),

              // Address
              StandardizedTextFormField(
                controller: _addressController,
                labelText: 'Address',
                prefixIcon: Icons.home,
                validator: FormValidators.validateAddress,
                hintText: 'Enter complete address',
                maxLines: 2,
              ),
              const SizedBox(height: FormThemeConstants.fieldSpacing),

              // Contact Number
              StandardizedTextFormField(
                controller: _contactController,
                labelText: 'Contact Number',
                prefixIcon: Icons.phone,
                validator: FormValidators.validateContactNumber,
                keyboardType: TextInputType.phone,
                hintText: 'e.g., +63 912 345 6789 or 09123456789',
              ),
              const SizedBox(height: FormThemeConstants.fieldSpacing),
              // Birthday
              StandardizedTextFormField(
                controller: _birthdayController,
                labelText: 'Birthday',
                prefixIcon: Icons.cake,
                validator: FormValidators.validateBirthday,
                hintText: 'MM/DD/YYYY',
                readOnly: true,
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: FormThemeConstants.primaryBrandColor,
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: FormThemeConstants.primaryBrandColor,
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (pickedDate != null) {
                    _birthdayController.text =
                        DateFormat('MM/dd/yyyy').format(pickedDate);
                    _calculateAge(pickedDate);
                  }
                },
              ),
              const SizedBox(height: FormThemeConstants.fieldSpacing),
              Row(
                children: [
                  // Age
                  Expanded(
                    child: StandardizedTextFormField(
                      controller: _ageController,
                      labelText: 'Age',
                      prefixIcon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      validator: FormValidators.validateAge,
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: FormThemeConstants.fieldSpacing),

                  // Gender Dropdown
                  Expanded(
                    child: StandardizedDropdownFormField(
                      value: _selectedGender,
                      items: const ['Male', 'Female', 'Other'],
                      labelText: 'Gender',
                      prefixIcon: Icons.wc,
                      validator: FormValidators.validateGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value ?? 'Male';
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FormThemeConstants.largeSpacing),

              // Proceed Button
              StandardizedFormButton(
                label: 'PROCEED TO SCAN',
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scan(
                          patientName: _nameController.text,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }
}
