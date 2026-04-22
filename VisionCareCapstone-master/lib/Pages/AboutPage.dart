import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:auto_size_text/auto_size_text.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final Size screenSize = MediaQuery.of(context).size;
    // Calculate responsive text sizes
    final double titleSize = screenSize.width * 0.06; // 6% of screen width
    final double subtitleSize = screenSize.width * 0.05; // 5% of screen width
    final double bodySize = screenSize.width * 0.04; // 4% of screen width
    final double smallSize = screenSize.width * 0.035; // 3.5% of screen width

    return Scaffold(
      backgroundColor: const Color(0xFFF8EFE8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: AutoSizeText(
          'about_cdd'.tr(),
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: titleSize,
          ),
          maxLines: 1,
          minFontSize: 16,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenSize.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo/Image with gradient overlay
            Center(
              child: Container(
                height: screenSize.height * 0.25, // 25% of screen height
                width: double.infinity,
                margin: EdgeInsets.symmetric(vertical: screenSize.height * 0.02),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Image.asset(
                        'Assets/images/FarmImage.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: screenSize.height * 0.02,
                        left: screenSize.width * 0.05,
                        right: screenSize.width * 0.05,
                        child: AutoSizeText(
                          'empowering_farmers'.tr(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: subtitleSize,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          minFontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // What is CDD Section
            Container(
              padding: EdgeInsets.all(screenSize.width * 0.05),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'what_is_cdd'.tr(),
                    style: TextStyle(
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF14919B),
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.02),
                  AutoSizeText(
                    'cdd_description'.tr(),
                    style: TextStyle(
                      fontSize: bodySize,
                      height: 1.6,
                      color: const Color(0xFF333333),
                    ),
                    minFontSize: 12,
                    maxLines: 10,
                  ),
                ],
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),

            // Features Section
            Container(
              padding: EdgeInsets.all(screenSize.width * 0.05),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'key_features'.tr(),
                    style: TextStyle(
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF14919B),
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.02),
                  _buildFeatureItem(
                    context: context,
                    icon: Icons.camera_alt,
                    title: 'real_time_detection'.tr(),
                    description: 'real_time_description'.tr(),
                  ),
                  _buildFeatureItem(
                    context: context,
                    icon: Icons.info_outline,
                    title: 'disease_info'.tr(),
                    description: 'disease_info_description'.tr(),
                  ),
                  _buildFeatureItem(
                    context: context,
                    icon: Icons.history,
                    title: 'history_tracking'.tr(),
                    description: 'history_description'.tr(),
                  ),
                  _buildFeatureItem(
                    context: context,
                    icon: Icons.psychology,
                    title: 'expert_guidance'.tr(),
                    description: 'expert_description'.tr(),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),

            // How to Use Section
            Container(
              padding: EdgeInsets.all(screenSize.width * 0.05),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'how_to_use'.tr(),
                    style: TextStyle(
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF14919B),
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.02),
                  _buildStepItem(context, '1', 'step_1'.tr()),
                  _buildStepItem(context, '2', 'step_2'.tr()),
                  _buildStepItem(context, '3', 'step_3'.tr()),
                  _buildStepItem(context, '4', 'step_4'.tr()),
                ],
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final Size screenSize = MediaQuery.of(context).size;
    final double featureTitleSize = screenSize.width * 0.045;
    final double featureDescSize = screenSize.width * 0.035;

    return Padding(
      padding: EdgeInsets.only(bottom: screenSize.height * 0.02),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(screenSize.width * 0.03),
            decoration: BoxDecoration(
              color: const Color(0xFF45DFB1).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, 
              size: screenSize.width * 0.06, 
              color: const Color(0xFF45DFB1)
            ),
          ),
          SizedBox(width: screenSize.width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  title,
                  style: TextStyle(
                    fontSize: featureTitleSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                  maxLines: 2,
                  minFontSize: 12,
                ),
                SizedBox(height: screenSize.height * 0.01),
                AutoSizeText(
                  description,
                  style: TextStyle(
                    fontSize: featureDescSize,
                    height: 1.5,
                    color: Colors.grey[600],
                  ),
                  maxLines: 4,
                  minFontSize: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(BuildContext context, String number, String description) {
    final Size screenSize = MediaQuery.of(context).size;
    final double stepTextSize = screenSize.width * 0.04;

    return Padding(
      padding: EdgeInsets.only(bottom: screenSize.height * 0.02),
      child: Row(
        children: [
          Container(
            width: screenSize.width * 0.08,
            height: screenSize.width * 0.08,
            decoration: BoxDecoration(
              color: const Color(0xFF45DFB1).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: const Color(0xFF45DFB1),
                  fontWeight: FontWeight.bold,
                  fontSize: stepTextSize,
                ),
              ),
            ),
          ),
          SizedBox(width: screenSize.width * 0.04),
          Expanded(
            child: AutoSizeText(
              description,
              style: TextStyle(
                fontSize: stepTextSize,
                color: const Color(0xFF333333),
                height: 1.5,
              ),
              maxLines: 3,
              minFontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
