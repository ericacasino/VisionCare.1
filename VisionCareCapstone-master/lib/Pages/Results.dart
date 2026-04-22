import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:easy_localization/easy_localization.dart';
import 'Dashboard.dart';


class Results extends StatefulWidget {
  final String disease;
  final String date;
  final String imagePath;
  final double? confidence;
  final String? patientName;
  final String? patientId;

  const Results({
    Key? key,
    required this.disease,
    required this.date,
    required this.imagePath,
    this.confidence,
    this.patientName,
    this.patientId,
  }) : super(key: key);

  @override
  State<Results> createState() => _ResultsState();
}

class _ResultsState extends State<Results> {
  bool _isExporting = false;

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

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'No date available';
    try {
      return DateFormat('MMM d, yyyy - HH:mm').format(DateTime.parse(dateStr));
    } catch (e) {
      return dateStr;
    }
  }

  pw.Widget _getRecommendationWidget(String disease, PdfColor color) {
    final normalized = disease.toLowerCase();
    String title;
    String body;

    if (normalized.contains('normal')) {
      title = "Regular Monitoring:";
      body = "No significant signs of retinopathy were detected. It is recommended to maintain regular eye screenings and continue managing your blood sugar levels as advised by your physician.";
    } else if (normalized.contains('mild')) {
      title = "Ophthalmologist Consultation Recommended:";
      body = "Potential early signs of retinopathy have been identified. It is recommended that you consult an Ophthalmologist for a comprehensive eye examination and professional confirmation.";
    } else if (normalized.contains('severe')) {
      title = "URGENT: Ophthalmologist Consultation Required:";
      body = "Significant signs of retinopathy have been detected. There is an urgent need to consult an Ophthalmologist immediately for professional verification and necessary treatment planning.";
    } else {
      title = "Inconclusive Result:";
      body = "The screening result is inconclusive. For your safety, please consult an Ophthalmologist for a professional verification.";
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: color, fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.Text(body, style: pw.TextStyle(fontSize: 10, color: color, lineSpacing: 2)),
      ],
    );
  }

  Future<void> _exportToPDF() async {
    setState(() => _isExporting = true);
    try {
      final pdf = pw.Document();

      Uint8List? logoBytes;
      try {
        logoBytes = (await rootBundle.load('Assets/images/Logo.png')).buffer.asUint8List();
      } catch (e) {
        debugPrint('Logo asset not found: $e');
      }
      
      final imageFile = File(widget.imagePath);
      Uint8List? scanImageBytes = await imageFile.exists() ? await imageFile.readAsBytes() : null;

      final int probabilityPercent = ((widget.confidence ?? 0.0) * 100).toInt();
      final String displayDisease = widget.disease;
      final Color statusColor = _getStatusColor(displayDisease);
      final PdfColor pdfStatusColor = PdfColor.fromInt(statusColor.value);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (logoBytes != null) pw.Image(pw.MemoryImage(logoBytes), width: 70),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('VISIONCARE', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.Text('Advanced Eye Screening Report', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Date: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ],
                ),
                pw.Divider(thickness: 1.5, color: PdfColors.blue900),
                pw.SizedBox(height: 20),
                pw.Center(child: pw.Text('DIABETIC RETINOPATHY ANALYSIS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
                pw.SizedBox(height: 20),
                pw.Text('PATIENT INFORMATION', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Container(
                  margin: const pw.EdgeInsets.symmetric(vertical: 10),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                  child: pw.Column(
                    children: [
                      _buildPdfRow('Name:', widget.patientName ?? 'N/A'),
                      _buildPdfRow('Patient ID:', widget.patientId ?? 'N/A'),
                      _buildPdfRow('Scan Date:', _formatDate(widget.date)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('PROBABILITY: $probabilityPercent%', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            displayDisease.toUpperCase(),
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: pdfStatusColor),
                          ),
                        ],
                      ),
                    ),
                    if (scanImageBytes != null)
                      pw.Container(
                          height: 150,
                          width: 150,
                          padding: const pw.EdgeInsets.all(2),
                          decoration: pw.BoxDecoration(border: pw.Border.all(color: pdfStatusColor, width: 2)),
                          child: pw.Image(pw.MemoryImage(scanImageBytes), fit: pw.BoxFit.contain)),
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(color: PdfColor.fromInt(statusColor.withOpacity(0.1).value)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('RECOMMENDATION:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: pdfStatusColor)),
                      pw.SizedBox(height: 8),
                      _getRecommendationWidget(displayDisease, pdfStatusColor),
                    ],
                  ),
                ),
                pw.Spacer(),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Doctor: ____________________________________________________', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 12),
                    pw.Text('Professional License No.: ___________________________________', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 12),
                    pw.Text('Position/Specialization: ___________________________________', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 12),
                    pw.Text('Affiliated Institution/Clinic: _______________________________', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 24),
                    pw.Text('Signature: _________________________________________________', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(color: PdfColors.grey400),
                pw.Center(child: pw.Text('This result is for Pre-Screening purposes only and is not a medical diagnosis. Please consult an Opthalmologist for confirmation.', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic))),
              ],
            );
          },
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/VisionCare_Report_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Report saved to Documents'),
          action: SnackBarAction(label: 'OPEN', onPressed: () => OpenFile.open(file.path)),
        ));
      }
    } catch (e) {
      debugPrint("PDF Export Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to export PDF: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int probabilityPercent = ((widget.confidence ?? 0.0) * 100).toInt();
    final Color statusColor = _getStatusColor(widget.disease);
    
    final String displayDisease = widget.disease.toLowerCase().contains('normal') ? 'Normal'.tr() :
                                  widget.disease.toLowerCase().contains('mild') ? 'Mild Diabetic Retinopathy'.tr() :
                                  widget.disease.toLowerCase().contains('severe') ? 'Severe Diabetic Retinopathy'.tr() :
                                  widget.disease;

    return Scaffold(
      backgroundColor: const Color(0xFF011627),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              Icon(
                widget.disease.toLowerCase().contains('normal') ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                color: statusColor,
                size: 100,
              ),
              const SizedBox(height: 20),
              Text('Probability: $probabilityPercent%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              Text(
                displayDisease.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: statusColor),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'This result is for Pre-Screening purposes only and is not a medical diagnosis. Please consult an Opthalmologist for confirmation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7), fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 40),
              const Divider(color: Colors.white24),
              const SizedBox(height: 20),
              _buildInfoRow('Patient Name', widget.patientName ?? 'N/A'),
              _buildInfoRow('Patient ID', widget.patientId ?? 'N/A'),
              _buildInfoRow('Scan Date', _formatDate(widget.date)),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: statusColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'RECOMMENDATION',
                          style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 1.1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildUiRecommendation(displayDisease, statusColor),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportToPDF,
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: Text(_isExporting ? 'EXPORTING...' : 'EXPORT TO PDF', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Dashboard()),
                  (route) => false,
                ),
                child: const Text('Back to Dashboard', style: TextStyle(color: Color(0xFF5ED3F2), fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUiRecommendation(String disease, Color color) {
    final normalized = disease.toLowerCase();
    String body;

    if (normalized.contains('normal')) {
      body = "No significant signs of retinopathy were detected. It is recommended to maintain regular eye screenings and continue managing your blood sugar levels as advised by your physician.";
    } else if (normalized.contains('mild')) {
      body = "Early signs of retinopathy have been detected. It is recommended that you consult an Ophthalmologist for a comprehensive eye examination and professional confirmation.";
    } else if (normalized.contains('severe')) {
      body = "Significant signs of retinopathy have been detected. There is an urgent need to consult an Ophthalmologist immediately for professional verification and necessary treatment planning.";
    } else {
      body = "The screening result is inconclusive. For your safety, please consult an Ophthalmologist for a professional verification.";
    }

    return Text(
      body,
      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.5),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 80, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
          pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }
}
