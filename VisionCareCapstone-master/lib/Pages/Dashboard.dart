import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:auto_size_text/auto_size_text.dart';
import './Results.dart';
import './History.dart';
import './AboutPage.dart';
import './PatientDetails.dart';
import '../database/database_helper.dart';
import '../widgets/custom_bottom_nav.dart';
import 'dart:io';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Future<List<Map<String, dynamic>>> _getRecentDiagnoses() async {
    final dbHelper = DatabaseHelper();
    final diagnoses = await dbHelper.getDiagnoses();
    return diagnoses.take(3).toList(); // Only show last 3 diagnoses
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final height = screenSize.height - padding.top - padding.bottom;
    final width = screenSize.width;

    // Calculate responsive dimensions
    final containerWidth = width * 0.9; // 90% of screen width
    final imageHeight = height * 0.25; // 25% of available height
    final scanContainerHeight = height * 0.17; // Increased from 0.15 to 0.17 (17% of available height)
    final diagnosesHeight = height * 0.40; // Increased to 40% to fit exactly 3 items

    return Scaffold(
      backgroundColor: const Color(0xFF04101A), // Dark background color to match the new design
      body: SingleChildScrollView(
        // Wrap the body in a SingleChildScrollView
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.04, // 4% padding
            vertical: height * 0.02, // 2% padding
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: height * 0.04), // 4% spacing

              // User Profile and Welcome Text
              Row(
                children: [
                  PopupMenuButton(
                    child: Container(
                      height: width * 0.08, // Shrunk from 0.12
                      width: width * 0.08,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Image.asset(
                          'Assets/images/Usericon.png',
                          height: width * 0.05,
                          width: width * 0.05,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem(
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline),
                            SizedBox(width: width * 0.02),
                            Text(
                              'About Vision Care',
                              style: TextStyle(
                                fontSize: width * 0.035,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Future.delayed(Duration.zero, () {
                            Navigator.pushNamed(context, '/about');
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(width: width * 0.04),
                  Container(
                    constraints: BoxConstraints(maxWidth: width * 0.7),
                    child: Text(
                      'Welcome', 
                      style: TextStyle(
                        fontSize: width * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              SizedBox(height: height * 0.02),

              // Info Container with overlay
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutPage()),
                  );
                },
                child: Container(
                  height: imageHeight,
                  width: containerWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(width * 0.04),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5.0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(width * 0.04),
                    child: Stack(
                      fit: StackFit.expand, // Ensures stack fills the container
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: Image.asset(
                            'Assets/images/DashboardBanner.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: height * 0.04),

              // New Scan Button Design to match Screenshot
              Center(
                child: SizedBox(
                  width: containerWidth,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const PatientDetails()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: const Color(0xFF5ED3F2), // Light blue
                      padding: EdgeInsets.symmetric(vertical: height * 0.025),
                      elevation: 0, // Minimal, no light outside
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(width * 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: width * 0.06),
                        SizedBox(width: width * 0.02),
                        Text(
                          'START NEW SCAN',
                          style: TextStyle(
                            fontSize: width * 0.045,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: height * 0.06), // Increased spacing to move it down slightly

              // Recent Diagnoses Section
              Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Colors.white,
                    size: width * 0.06,
                  ),
                  SizedBox(width: width * 0.02),
                  Expanded(
                    child: AutoSizeText(
                      'Recent Scans',
                      style: TextStyle(
                        fontSize: width * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      minFontSize: 12,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.02),
              Container(
                height: diagnosesHeight,
                width: containerWidth,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2231), // Dark card background
                  borderRadius: BorderRadius.circular(width * 0.06),
                  border: Border.all(color: Colors.white12, width: 1),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.04),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _getRecentDiagnoses(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return Container();
                        return Column(
                          children: snapshot.data!.map((diagnosis) {
                            // Extract confidence value
                            final double confidence = diagnosis['confidence'] != null 
                                ? (diagnosis['confidence'] as num).toDouble() 
                                : 0.0;
                            
                            // Determine display label based on thresholds
                            String displayLabel;
                            int confidencePercent = (confidence * 100).toInt();
                            if (confidencePercent < 35) {
                              displayLabel = 'No Diabetic Retinopathy';
                            } else if (confidencePercent >= 35 && confidencePercent <= 69) {
                              displayLabel = 'Mild Diabetic Retinopathy';
                            } else {
                              displayLabel = 'Severe Diabetic Retinopathy';
                            }

                            return Column(
                              children: [
                                _buildDiagnosisItem(
                                  displayLabel, 
                                  diagnosis['date'],
                                  width,
                                  rawDisease: diagnosis['disease'], 
                                  confidence: confidence, 
                                ),
                                if (diagnosis != snapshot.data!.last)
                                  Divider(color: Colors.white12, height: width * 0.04),
                              ],
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  Widget _buildDiagnosisItem(String displayLabel, String date, double width, {String? rawDisease, double? confidence}) {
    Color severityColor;
    if (displayLabel.contains('Severe')) {
      severityColor = Colors.redAccent;
    } else if (displayLabel.contains('Mild')) {
      severityColor = Colors.orangeAccent;
    } else {
      severityColor = Colors.green;
    }

    return InkWell(
      onTap: () {
        // Get the diagnosis details from the database
        DatabaseHelper().getDiagnoses().then((diagnoses) {
          final diagnosis = diagnoses.firstWhere(
            (d) => d['disease'] == (rawDisease ?? displayLabel) && d['date'] == date,
            orElse: () => {'imagePath': '', 'confidence': confidence}, // Use passed confidence as fallback
          );
          
          final double? finalConfidence = diagnosis['confidence'] != null 
              ? (diagnosis['confidence'] as num).toDouble() 
              : confidence;
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Results(
                disease: rawDisease ?? displayLabel,
                date: date,
                imagePath: diagnosis['imagePath'] ?? '',
                confidence: finalConfidence,
              ),
            ),
          );
        });
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: width * 0.02),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(width * 0.03),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: DatabaseHelper().getDiagnoses(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return SizedBox(width: width * 0.15, height: width * 0.15);
                  final diagnosis = snapshot.data!.firstWhere(
                    (d) => d['disease'] == (rawDisease ?? displayLabel) && d['date'] == date,
                    orElse: () => {'imagePath': ''},
                  );
                  
                  return diagnosis['imagePath']?.isNotEmpty == true
                      ? Image.file(
                          File(diagnosis['imagePath']),
                          height: width * 0.15,
                          width: width * 0.15,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: width * 0.15,
                          width: width * 0.15,
                          color: Colors.grey.shade800,
                          child: Icon(Icons.image_not_supported, color: Colors.white54),
                        );
                },
              ),
            ),
            SizedBox(width: width * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    displayLabel,
                    style: TextStyle(
                      fontSize: width * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    minFontSize: 10,
                    maxLines: 1,
                  ),
                  SizedBox(height: width * 0.015),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: width * 0.02, vertical: width * 0.005),
                        decoration: BoxDecoration(
                          color: severityColor.withOpacity(0.15),
                          border: Border.all(color: severityColor.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(width * 0.02),
                        ),
                        child: Text(
                          'Severity: ${displayLabel.contains("Severe") ? "Severe DR" : displayLabel.contains("Mild") ? "Mild DR" : "No DR"}',
                          style: TextStyle(
                            color: severityColor,
                            fontSize: width * 0.025,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: width * 0.02),
                      Icon(Icons.info_outline, color: Colors.grey, size: width * 0.035),
                    ],
                  ),
                  SizedBox(height: width * 0.015),
                  AutoSizeText(
                    date,
                    style: TextStyle(
                      fontSize: width * 0.03,
                      color: Colors.grey.shade500,
                    ),
                    minFontSize: 8,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


}
