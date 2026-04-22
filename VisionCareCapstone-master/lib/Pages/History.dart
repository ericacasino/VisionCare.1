import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../database/database_helper.dart';
import 'Results.dart';
import 'Dashboard.dart';
import 'PatientDetails.dart';
import 'ExportReport.dart';

class History extends StatefulWidget {
  const History({Key? key}) : super(key: key);

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteScreening(Map<String, dynamic> screening) async {
    try {
      if (screening['imagePath'] != null && screening['imagePath'].isNotEmpty) {
        final file = File(screening['imagePath']);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await _databaseHelper.deleteDiagnosis(screening['id']);
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_deleting_diagnosis'.tr())),
        );
      }
    }
  }

  /// Safe date parsing to handle multiple formats
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'No date available';
    try {
      // Try ISO format first
      return DateFormat('MMM d, yyyy - HH:mm').format(DateTime.parse(dateStr));
    } catch (e) {
      // Fallback for older entries already in the DB
      return dateStr;
    }
  }

  Color _getStatusColor(String disease) {
    final normalized = disease.toLowerCase();
    if (normalized.contains('normal')) {
      return Colors.green;
    } else if (normalized.contains('mild')) {
      return Colors.orange;
    } else if (normalized.contains('severe')) {
      return Colors.red;
    }
    return Colors.blue;
  }

  Widget _buildSearchBar(double width) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: width * 0.03),
      padding: EdgeInsets.symmetric(horizontal: width * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2239),
        borderRadius: BorderRadius.circular(width * 0.1),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: const Color(0xFF5ED3F2),
            size: width * 0.07,
          ),
          SizedBox(width: width * 0.03),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              style: const TextStyle(color: Colors.white70),
              decoration: InputDecoration(
                hintText: 'search_disease'.tr(),
                hintStyle: const TextStyle(color: Colors.white30),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreeningList(double width) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _databaseHelper.getDiagnoses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF5ED3F2)));
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: width * 0.15, color: Colors.white10),
                const SizedBox(height: 16),
                Text(
                  'no_matching_diagnoses'.tr(),
                  style: const TextStyle(color: Colors.white30),
                ),
              ],
            ),
          );
        }

        final filteredScreenings = snapshot.data!.where((screening) {
          return screening['disease'].toString().toLowerCase().contains(_searchQuery);
        }).toList();

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: width * 0.05),
          itemCount: filteredScreenings.length,
          itemBuilder: (context, index) {
            final screening = filteredScreenings[index];
            final disease = screening['disease'] ?? 'Unknown';
            final double confidence = (screening['confidence'] ?? 0.0) as double;
            final Color statusColor = _getStatusColor(disease);

            return _buildScreeningCard(width, screening, disease, confidence, statusColor);
          },
        );
      },
    );
  }

  Widget _buildScreeningCard(double width, Map<String, dynamic> screening, String disease, double confidence, Color statusColor) {
    return Container(
      margin: EdgeInsets.only(bottom: width * 0.05),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2239),
        borderRadius: BorderRadius.circular(width * 0.06),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (context) => Results(
            disease: disease,
            date: screening['date'],
            imagePath: screening['imagePath'] ?? '',
            confidence: confidence,
            patientName: screening['patientName'],
            patientId: screening['patientId'],
          ),
        )),
        onLongPress: () => _showDeleteDialog(screening),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(width * 0.06),
                  child: screening['imagePath'] != null
                      ? Image.file(
                          File(screening['imagePath']),
                          height: width * 0.45,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: width * 0.45,
                          width: double.infinity,
                          color: Colors.grey[900],
                          child: const Icon(Icons.image_not_supported, color: Colors.white12),
                        ),
                ),
                Positioned(
                  top: 15,
                  right: 15,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: width * 0.16,
                        height: width * 0.16,
                        child: CircularProgressIndicator(
                          value: confidence,
                          strokeWidth: 6,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            confidence > 0.6 ? Colors.orange : Colors.yellow.shade700,
                          ),
                        ),
                      ),
                      Text(
                        '${(confidence * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.03,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: -15,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B2239),
                        borderRadius: BorderRadius.circular(width * 0.02),
                        border: Border.all(color: Colors.white12, width: 1),
                      ),
                      child: Icon(
                        Icons.analytics_outlined,
                        color: Colors.white70,
                        size: width * 0.05,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(width * 0.04, width * 0.06, width * 0.04, width * 0.04),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          disease,
                          style: TextStyle(
                            fontSize: width * 0.042,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFA726),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: width * 0.01),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.white38),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(screening['date']),
                              style: const TextStyle(fontSize: 11, color: Colors.white38),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> screening) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('confirm_delete'.tr()),
        content: Text('delete_diagnosis_confirmation'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteScreening(screening);
            },
            child: Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFF011627),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'recent_results'.tr(),
          style: TextStyle(
            color: Colors.white,
            fontSize: width * 0.055,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF011627),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white54),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Dashboard()),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExportReport()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(width),
          Expanded(
            child: _buildScreeningList(width),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(width),
    );
  }

  Widget _buildBottomNavigationBar(double width) {
    return BottomNavigationBar(
      currentIndex: 2,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Dashboard()),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PatientDetails()),
          );
        }
      },
      elevation: 10,
      backgroundColor: const Color(0xFF001529),
      selectedItemColor: const Color(0xFF5ED3F2),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: width * 0.025,
      unselectedFontSize: width * 0.025,
      iconSize: width * 0.05,
      items: [
        _buildNavigationBarItem('Home', 'home', width),
        _buildNavigationBarItem('ScanNavBar', 'scan', width),
        _buildNavigationBarItem('DiagnosIcon', 'diagnose', width),
      ],
    );
  }

  BottomNavigationBarItem _buildNavigationBarItem(
      String iconName, String label, double width) {
    return BottomNavigationBarItem(
      icon: Image.asset(
        'Assets/images/$iconName.png',
        height: width * 0.05,
        width: width * 0.05,
        color: Colors.white,
      ),
      label: label.tr(),
      activeIcon: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF45DFB1),
          borderRadius: BorderRadius.circular(width * 0.025),
        ),
        padding: EdgeInsets.all(width * 0.02),
        child: Image.asset(
          'Assets/images/$iconName.png',
          height: width * 0.05,
          width: width * 0.05,
        ),
      ),
    );
  }
}
