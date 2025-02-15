import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'add_salary_screen.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'services/notification_service.dart';


class SalaryListScreen extends StatefulWidget {
  @override
  State<SalaryListScreen> createState() => _SalaryListScreenState();
}

class _SalaryListScreenState extends State<SalaryListScreen> {
  List<Map<String, String>> _salaryData = [];
  List<Map<String, String>> _filteredData = []; // To store filtered salary data
  bool _isLoading = true; // To show loading indicator
  bool _hasError = false;
  String selectedStatus = 'All'; // Default filter value

  @override
  void initState() {
    super.initState();
    _fetchSalaryData();
  }

  Future<void> _fetchSalaryData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('id');

    try {
      final response = await http.post(
          Uri.parse('https://eofficess.com/api/show-salary?user_id=$userId'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> salaries = responseData['data'];
          setState(() {
            _salaryData = salaries.map((salary) {
              return {
                'sno': salary['id']?.toString() ?? '',
                'slapAmount': salary['slap_amount']?.toString() ?? '--',
                'level': salary['label']?.toString() ?? 'N/A',
                'status': salary['status']?.toString() ?? 'Pending',
                'gradeAmount': salary['grade_amount']?.toString() ?? '--',
                'directAddedAmount':
                    salary['direct_added_amount']?.toString() ?? '--',
                'salaryAmount': salary['salary_amount']?.toString() ?? '--',
                'mergeAmount': salary['merge_amount']?.toString() ?? '--',
                'directTotalSalary':
                    salary['direct_total_salary']?.toString() ?? '--',
              };
            }).toList();

            _filterSalary(selectedStatus); // Filter based on initial status
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _filterSalary(String status) {
    setState(() {
      if (status == 'All') {
        _filteredData = _salaryData;
      } else {
        _filteredData = _salaryData
            .where((salary) =>
                salary['status']?.toLowerCase() == status.toLowerCase())
            .toList();
      }
    });
  }


//----------------------------------------------------------------
void _showInfoDialog(
    String sno,
    String slapAmount,
    String level,
    String status,
    String gradeAmount,
    String directAddedAmount,
    String salaryAmount,
    String mergeAmount,
    String directTotalSalary) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Salary Info',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('SNO:', sno),
              _buildInfoRow('Slap Amount:', slapAmount),
              _buildInfoRow('Level:', level),
              _buildInfoRow('Status:', status),
              _buildInfoRow('Grade Amount:', gradeAmount),
              _buildInfoRow('Direct Added Amount:', directAddedAmount),
              _buildInfoRow('Salary Amount:', salaryAmount),
              _buildInfoRow('Merge Amount:', mergeAmount),
              _buildInfoRow('Direct Total Salary:', directTotalSalary),
              const SizedBox(height: 16),

              // PDF Viewer
              Container(
                height: 300,
                child: SfPdfViewer.network(
                  'https://eofficess.com/api/user-salary-pdf/$sno',
                ),
              ),

              const SizedBox(height: 16),

              // Buttons in Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                    onPressed: () async {
                      final downloadUrl =
                          'https://eofficess.com/api/user-salary-pdf/$sno';
                      await _downloadFile(context, downloadUrl, sno);

                      // Trigger a notification after a successful download
                      await NotificationService.showNotification(
                        title: 'Download Successful',
                        body: 'Salary PDF for SNO $sno has been downloaded.',
                      );
                    },
                    child: const Text('Download',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue),
                    onPressed: () async {
                      final filePath = '/storage/emulated/0/Download/$sno.pdf';
                      await _shareFile(context, filePath, 'Salary Info');

                      // Trigger a notification after a successful share
                      await NotificationService.showNotification(
                        title: 'Share Successful',
                        body: 'Salary PDF for SNO $sno is ready to share.',
                      );
                    },
                    child: const Text('Share',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.black)),
          ),
        ],
      );
    },
  );
}

Future<void> _downloadFile(BuildContext context, String url, String sno) async {
  try {
    final downloadsDirectory = Directory('/storage/emulated/0/Download');
    if (!downloadsDirectory.existsSync()) {
      downloadsDirectory.createSync(recursive: true);
    }

    String savePath = '${downloadsDirectory.path}/$sno.pdf';

    Dio dio = Dio();
    await dio.download(url, savePath);
  ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download successful!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.fixed,
          ),
        );
    print("File downloaded to $savePath");
  } catch (e) {
    print("Error downloading file: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to download the file.')),
    );
  }
}

Future<void> _shareFile(BuildContext context, String filePath, String title) async {
  File file = File(filePath);

  if (await file.exists()) {
    try {
      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'Check out this PDF: $title');

      print("Sharing file: ${file.path}");
    } catch (e) {
      print("Error sharing file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share the file.')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File not found. Please download it first.')),
    );
    print("File not found: $filePath");
  }
}

//----------------------------------------------------------------x

  // Helper method to build info row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
              child: Text(value, style: const TextStyle(color: Colors.black))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uniqueStatuses = _salaryData
        .map((item) => item['status'])
        .toSet()
        .toList(); // Unique statuses

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white, // Set the back arrow color to white
        ),
        title: const Text('Salaries List',
            style: TextStyle(color: Colors.white, fontSize: 20)),
        backgroundColor: const Color(0xFF4769B2),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              _filterSalary(value); // Apply filter based on selected value
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'All',
                  child: Text('All'),
                ),
                const PopupMenuItem<String>(
                  value: 'Pending',
                  child: Text('Pending'),
                ),
                const PopupMenuItem<String>(
                  value: 'Approved',
                  child: Text('Approved'),
                ),
                const PopupMenuItem<String>(
                  value: 'Rejected',
                  child: Text('Rejected'),
                ),
              ];
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? const Center(child: Text('Error loading data'))
              : Column(
                  children: [
                    Container(
                      color: Colors.blue[100],
                      child: Table(
                        border: TableBorder.all(),
                        columnWidths: const {
                          0: FractionColumnWidth(0.1),
                          1: FractionColumnWidth(0.3),
                          2: FractionColumnWidth(0.2),
                          3: FractionColumnWidth(0.2),
                          4: FractionColumnWidth(0.2),
                        },
                        children: const [
                          TableRow(
                            children: [
                              SizedBox(
                                  height: 60,
                                  child: Center(
                                      child: Text('SNO',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)))),
                              SizedBox(
                                  height: 60,
                                  child: Center(
                                      child: Text('Slap Amount',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)))),
                              SizedBox(
                                  height: 60,
                                  child: Center(
                                      child: Text('Level',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)))),
                              SizedBox(
                                  height: 60,
                                  child: Center(
                                      child: Text('Status',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)))),
                              SizedBox(
                                  height: 60,
                                  child: Center(
                                      child: Text('Info',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Table(
                          border: TableBorder.all(),
                          columnWidths: const {
                            0: FractionColumnWidth(0.1),
                            1: FractionColumnWidth(0.3),
                            2: FractionColumnWidth(0.2),
                            3: FractionColumnWidth(0.2),
                            4: FractionColumnWidth(0.2),
                          },
                          children: [
                            for (var item in _filteredData)
                              TableRow(
                                children: [
                                  Container(
                                      height: 60,
                                      child: Center(
                                          child: Text('${item['sno']}'))),
                                  Container(
                                      height: 60,
                                      child: Center(
                                          child:
                                              Text('${item['slapAmount']}'))),
                                  Container(
                                      height: 60,
                                      child: Center(
                                          child: Text('${item['level']}'))),
                                  Container(
  height: 60,
  child: Center(
    child: Text(
      item['status']?.trim().toLowerCase() == 'approved_clerk'
          ? 'Pending From HOD'
          : '${item['status']}',
      style: TextStyle(
        fontWeight: FontWeight.bold, // Make text bold
        color: item['status']?.trim().toLowerCase() == 'approved'
            ? Colors.green
            : (item['status']?.trim().toLowerCase() == 'rejected'
                ? Colors.red
                : Colors.orange),
      ),
    ),
  ),
),

                                  Container(
                                    height: 60,
                                    child: Center(
                                      child: IconButton(
                                        icon: const Icon(Icons.info,
                                            color: Colors.blue),
                                        onPressed: () {
                                          _showInfoDialog(
                                            item['sno']!,
                                            item['slapAmount']!,
                                            item['level']!,
                                            item['status']!,
                                            item['gradeAmount']!,
                                            item['directAddedAmount']!,
                                            item['salaryAmount']!,
                                            item['mergeAmount']!,
                                            item['directTotalSalary']!,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddSalaryScreen()));
        },
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFF4769B2),
      ),
    );
  }
}
