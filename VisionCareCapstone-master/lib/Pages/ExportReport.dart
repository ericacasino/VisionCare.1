import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../database/database_helper.dart';
import 'package:open_file/open_file.dart';
import '../utils/date_format_utils.dart';

class ExportReport extends StatefulWidget {
  const ExportReport({Key? key}) : super(key: key);

  @override
  State<ExportReport> createState() => _ExportReportState();
}

class _ExportReportState extends State<ExportReport> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  String? _lastExportedFilePath;

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _openExportedFile() async {
    if (_lastExportedFilePath != null) {
      final file = File(_lastExportedFilePath!);
      if (await file.exists()) {
        final result = await OpenFile.open(_lastExportedFilePath!);
        if (result.type != ResultType.done) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open file: ${result.message}')),
            );
          }
        }
      }
    }
  }

  pw.Widget _buildDistributionChart(Map<String, int> diseaseCount, double total) {
    final List<pw.TableRow> rows = [];
    
    // Add header row
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: PdfColors.grey300,
        ),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Condition',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Count',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Percentage',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Distribution',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    // Add data rows
    diseaseCount.forEach((disease, count) {
      final percentage = (count / total * 100).toStringAsFixed(1);
      final barWidth = (count / total * 50).round(); // Max 50 characters for the bar
      final bar = '█' * barWidth;
      
      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(disease),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(count.toString()),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('$percentage%'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(bar),
            ),
          ],
        ),
      );
    });

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      columnWidths: {
        0: const pw.FlexColumnWidth(2), // Condition
        1: const pw.FlexColumnWidth(1), // Count
        2: const pw.FlexColumnWidth(1), // Percentage
        3: const pw.FlexColumnWidth(3), // Distribution bar
      },
      children: rows,
    );
  }

  pw.Widget _buildPieChart(Map<String, int> diseaseCount, double total) {
    // Create a simple visual representation using colored boxes
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: diseaseCount.entries.toList().asMap().entries.map((entry) {
        final disease = entry.value.key;
        final count = entry.value.value;
        final percentage = (count / total * 100).toStringAsFixed(1);
        
        // Use different colors for each condition
        final colors = [
          PdfColors.blue300,
          PdfColors.green300,
          PdfColors.amber300,
          PdfColors.pink300,
          PdfColors.purple300,
          PdfColors.teal300,
          PdfColors.red300,
          PdfColors.indigo300,
        ];
        
        final color = colors[entry.key % colors.length];
        final barWidth = (double.parse(percentage) * 2).round(); // Scale the bar width
        
        return pw.Container(
          margin: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(
            children: [
              pw.Container(
                width: 12,
                height: 12,
                color: color,
              ),
              pw.SizedBox(width: 5),
              pw.Expanded(
                flex: 3,
                child: pw.Text('$disease: $count ($percentage%)'),
              ),
              pw.Expanded(
                flex: 7,
                child: pw.Container(
                  height: 15,
                  width: barWidth.toDouble(),
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildTrendChart(List<Map<String, dynamic>> scans) {
    // Group scans by date
    final Map<String, Map<String, int>> dateData = {};
  
    // Process last 7 days of data
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('MM/dd').format(date);
      dateData[dateStr] = {};
    }
  
    // Count scans by date and condition
    for (final scan in scans) {
      final date = DateTime.parse(scan['date']);
      final dateStr = DateFormat('MM/dd').format(date);
      final disease = scan['disease'] as String;
    
      if (dateData.containsKey(dateStr)) {
        dateData[dateStr]![disease] = (dateData[dateStr]![disease] ?? 0) + 1;
      }
    }
  
    // Create a simpler bar chart using a table with visual bars
    final List<pw.TableRow> rows = [];
  
    // Add header row
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: PdfColors.grey300,
        ),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Date',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          ...dateData.keys.map((date) => 
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                date,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            )
          ).toList(),
        ],
      ),
    );
  
    // Get all unique conditions
    final allConditions = <String>{};
    for (final dateEntry in dateData.entries) {
      allConditions.addAll(dateEntry.value.keys);
    }
  
    // Add data rows for each condition
    for (final disease in allConditions) {
      final List<pw.Widget> cells = [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(disease),
        ),
      ];
    
      for (final dateStr in dateData.keys) {
        final count = dateData[dateStr]![disease] ?? 0;
        final bar = '█' * count; // Simple visual bar
        
        cells.add(
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text('$count $bar'),
          ),
        );
      }
    
      rows.add(pw.TableRow(children: cells));
    }
  
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      children: rows,
    );
  }

  Future<void> _exportToPDF() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both start and end dates'.tr())),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final scans = await _databaseHelper.getDiagnoses();
      final filteredScans = scans.where((scan) {
        final scanDate = DateTime.parse(scan['date']);
        return scanDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
               scanDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();

      if (filteredScans.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('no_diagnoses_found'.tr())),
        );
        return;
      }

      // Get the current locale's language code
      final String currentLocale = context.locale.languageCode;

      // Calculate condition distribution
      final Map<String, int> conditionCount = {};
      for (var scan in filteredScans) {
        final disease = scan['disease'] as String;
        conditionCount[disease] = (conditionCount[disease] ?? 0) + 1;
      }
      final total = filteredScans.length.toDouble();

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context pdfContext) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Diabetic Retinopathy Screening Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      DateFormatUtils.formatDate(DateTime.now(), currentLocale, 'MMM d, yyyy'),
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'Report Period: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      '${DateFormatUtils.formatDate(_startDate!, currentLocale, 'MMM d, yyyy')} - ${DateFormatUtils.formatDate(_endDate!, currentLocale, 'MMM d, yyyy')}',
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Summary Statistics',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Metric', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Value', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total Scans in Period'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${filteredScans.length}'),
                      ),
                    ],
                  ),
                  ...conditionCount.entries.map((entry) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${entry.key} Cases'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${entry.value} (${(entry.value / total * 100).toStringAsFixed(1)}%)'),
                      ),
                    ],
                  )),
                ],
              ),
              
              pw.SizedBox(height: 30),
              pw.Text(
                'Detailed Screening Records',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2), // Date & Time
                  1: const pw.FlexColumnWidth(2), // Patient Name
                  2: const pw.FlexColumnWidth(1.5), // Patient ID
                  3: const pw.FlexColumnWidth(1.5), // Condition
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Date & Time',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Patient Name',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Patient ID',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Condition',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Data rows
                  ...filteredScans.map((scan) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            DateFormatUtils.formatDate(DateTime.parse(scan['date']), currentLocale, 'MMM d, yyyy - HH:mm'),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(scan['patientName'] ?? 'N/A'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(scan['patientId'] ?? 'N/A'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(scan['disease']),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ];
          },
        ),
      );

      // Save to Downloads directory
      final output = await getExternalStorageDirectory();
      final fileName = 'diabetic_retinopathy_report_${DateFormatUtils.formatDate(DateTime.now(), currentLocale, 'yyyyMMdd_HHmmss')}.pdf';
      final filePath = '${output?.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      setState(() {
        _lastExportedFilePath = filePath;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Report Exported Successfully'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('File saved as:'),
                  const SizedBox(height: 8),
                  Text(
                    fileName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Location:'),
                  const SizedBox(height: 8),
                  Text(
                    output?.path ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _openExportedFile();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Open'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting report: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: const Color(0xFF011627),
      appBar: AppBar(
        title: Text('export_report'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0B2239),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'select_date_range'.tr(),
              style: TextStyle(
                fontSize: width * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: width * 0.06),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('start_date'.tr(), style: const TextStyle(color: Colors.white70)),
                      SizedBox(height: width * 0.02),
                      InkWell(
                        onTap: () => _selectDate(context, true),
                        child: Container(
                          padding: EdgeInsets.all(width * 0.035),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B2239),
                            border: Border.all(color: Colors.white12),
                            borderRadius: BorderRadius.circular(width * 0.03),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _startDate != null
                                    ? DateFormatUtils.formatDate(_startDate!, context.locale.languageCode, 'MMM d, yyyy')
                                    : 'select_date'.tr(),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const Icon(Icons.calendar_today, color: Color(0xFF5ED3F2), size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: width * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('end_date'.tr(), style: const TextStyle(color: Colors.white70)),
                      SizedBox(height: width * 0.02),
                      InkWell(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: EdgeInsets.all(width * 0.035),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B2239),
                            border: Border.all(color: Colors.white12),
                            borderRadius: BorderRadius.circular(width * 0.03),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _endDate != null
                                    ? DateFormatUtils.formatDate(_endDate!, context.locale.languageCode, 'MMM d, yyyy')
                                    : 'select_date'.tr(),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const Icon(Icons.calendar_today, color: Color(0xFF5ED3F2), size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: width * 0.1),
            if (_lastExportedFilePath != null)
              Padding(
                padding: EdgeInsets.only(bottom: width * 0.04),
                child: Center(
                  child: TextButton.icon(
                    onPressed: _openExportedFile,
                    icon: const Icon(Icons.file_open, color: Color(0xFF5ED3F2)),
                    label: const Text('Open Last Exported Report', style: TextStyle(color: Color(0xFF5ED3F2))),
                  ),
                ),
              ),
            Center(
              child: Container(
                width: width * 0.8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(width * 0.1),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _exportToPDF,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    backgroundColor: const Color(0xFF5ED3F2),
                    padding: EdgeInsets.symmetric(vertical: width * 0.04),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(width * 0.1),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2),
                        )
                      : Text(
                          'export_to_pdf'.tr().toUpperCase(),
                          style: TextStyle(
                            fontSize: width * 0.04,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
