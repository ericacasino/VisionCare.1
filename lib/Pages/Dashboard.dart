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
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _getRecentDiagnoses(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF5ED3F2))),
                    );
                  }

                  final diagnoses = snapshot.data!;
                  if (diagnoses.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.all(width * 0.05),
                      child: Text(
                        'No recent scans yet',
                        style: TextStyle(color: Colors.white70, fontSize: width * 0.04),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      padding: EdgeInsets.all(width * 0.015),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2231),
                        borderRadius: BorderRadius.circular(width * 0.02),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: width * 0.02, vertical: width * 0.012),
                            child: Row(
                              children: [
                                SizedBox(width: width * 0.24, child: Text('Date', style: TextStyle(color: const Color(0xFF5ED3F2), fontWeight: FontWeight.bold, fontSize: width * 0.034))),
                                SizedBox(width: width * 0.14, child: Text('Photo', style: TextStyle(color: const Color(0xFF5ED3F2), fontWeight: FontWeight.bold, fontSize: width * 0.034))),
                                SizedBox(width: width * 0.2, child: Text('Patient', style: TextStyle(color: const Color(0xFF5ED3F2), fontWeight: FontWeight.bold, fontSize: width * 0.034))),
                                SizedBox(width: width * 0.22, child: Text('Result', style: TextStyle(color: const Color(0xFF5ED3F2), fontWeight: FontWeight.bold, fontSize: width * 0.034))),
                              ],
                            ),
                          ),
                          ...diagnoses.map((diagnosis) {
                            final double confidence = diagnosis['confidence'] != null
                                ? (diagnosis['confidence'] as num).toDouble()
                                : 0.0;
                            final String patientName = (diagnosis['patientName'] ?? 'Unknown Patient').toString();
                            final String imagePath = diagnosis['imagePath'] ?? '';
                            final String displayLabel = _getDisplayLabel(confidence);
                            final Color resultColor = _getSeverityColor(displayLabel);
                            final String dateTime = diagnosis['date'] ?? 'N/A';

                            return InkWell(
                              onTap: () => _openDiagnosisDetails(diagnosis, displayLabel),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: width * 0.02, vertical: width * 0.014),
                                decoration: BoxDecoration(
                                  border: Border(top: BorderSide(color: Colors.white12, width: 0.8)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: width * 0.24,
                                      child: Text(
                                        dateTime,
                                        style: const TextStyle(color: Colors.white, fontSize: 12.5),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                    SizedBox(
                                      width: width * 0.14,
                                      child: imagePath.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(5),
                                              child: Image.file(
                                                File(imagePath),
                                                width: 46,
                                                height: 46,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Container(
                                              width: 46,
                                              height: 46,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade800,
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                              child: const Icon(Icons.image_not_supported, size: 16, color: Colors.white54),
                                            ),
                                    ),
                                    SizedBox(width: width * 0.04),
                                    SizedBox(
                                      width: width * 0.2,
                                      child: Text(
                                        patientName,
                                        style: const TextStyle(color: Colors.white, fontSize: 12.5),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    SizedBox(
                                      width: width * 0.22,
                                      child: Text(
                                        displayLabel,
                                        style: TextStyle(color: resultColor, fontWeight: FontWeight.w600, fontSize: 12.5),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  String _getDisplayLabel(double confidence) {
    final int confidencePercent = (confidence * 100).toInt();
    if (confidencePercent < 35) {
      return 'No DR';
    } else if (confidencePercent >= 35 && confidencePercent <= 69) {
      return 'Mild DR';
    }
    return 'Severe DR';
  }

  Color _getSeverityColor(String displayLabel) {
    if (displayLabel.contains('Severe')) {
      return Colors.redAccent;
    } else if (displayLabel.contains('Mild')) {
      return Colors.orangeAccent;
    }
    return Colors.green;
  }

  void _openDiagnosisDetails(Map<String, dynamic> diagnosis, String displayLabel) {
    final String date = diagnosis['date'] ?? DateTime.now().toString();
    final double confidence = diagnosis['confidence'] != null
        ? (diagnosis['confidence'] as num).toDouble()
        : 0.0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Results(
          disease: diagnosis['disease'] ?? displayLabel,
          date: date,
          imagePath: diagnosis['imagePath'] ?? '',
          confidence: confidence,
          patientName: diagnosis['patientName'],
          patientId: diagnosis['patientId'],
        ),
      ),
    );
  }

}
