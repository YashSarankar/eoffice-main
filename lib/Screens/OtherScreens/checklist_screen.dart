import 'dart:io';

import 'package:eoffice/Auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../salary_R/services/notification_service.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  int selectedYear = DateTime.now().year;
  bool isLoading = true;
  List<TableSampleData> tableData = [];
  late PdfViewerController _pgController;

  @override
  void initState() {
    super.initState();
    _pgController = PdfViewerController();
    fetchChecklistData();
  }

  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> fetchChecklistData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('id');

    try{
      String? token = await getAuthToken();
      if (token == null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
        throw Exception('User is not logged in');
      }
      final response = await http.post(Uri.parse(
          'https://eofficess.com/api/get-checklist-status?user_id=$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        }
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success']) {
          List<TableSampleData> fetchedData = (data['data'] as List)
              .map((item) => TableSampleData(
            sNo: item['id'],
            category: item['checklist_name'],
            status: (item['receipt_status'] ?? "Pending").trim(),
            page: item['page_file'],
            date: DateTime.parse(item['created_at']),
          ))
              .toList();

          setState(() {
            tableData = fetchedData;
          });
        }
      } else if(response.statusCode==401){
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
      }else {
        // Handle error
        print('Failed to load checklist data: ${response.statusCode}');
      }

      setState(() {
        isLoading = false;
      });
    }catch(e){
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<TableSampleData> filteredData =
        tableData.where((data) => data.date.year == selectedYear).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist',
            style: const TextStyle(color: Colors.white, fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        titleSpacing: 0,
        backgroundColor: const Color(0xFF4769B2),
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Year:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        DropdownButton<int>(
                          value: selectedYear,
                          items: List.generate(5, (index) {
                            int year = DateTime.now().year - index;
                            return DropdownMenuItem<int>(
                              value: year,
                              child: Text(year.toString()),
                            );
                          }),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedYear = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Table(
                      border: TableBorder.all(color: Colors.grey, width: 1),
                      columnWidths: const <int, TableColumnWidth>{
                        0: FixedColumnWidth(60),
                        1: FixedColumnWidth(110),
                        2: FixedColumnWidth(100),
                        3: FixedColumnWidth(100),
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(
                          decoration:
                              BoxDecoration(color: Colors.blueGrey.shade100),
                          children: [
                            _buildTableHeader('S.No'),
                            _buildTableHeader('Category'),
                            _buildTableHeader('receipt_status'),
                            _buildTableHeader('Info'),
                          ],
                        ),
                        for (var data in filteredData)
                          TableRow(
                            decoration:
                                const BoxDecoration(color: Colors.white),
                            children: [
                              _buildTableCell(data.sNo.toString()),
                              _buildTableCell(
                                data.category,
                                isClickable: false,
                              ),
                               _buildTableCell(
      data.status,
      statusColor: _getStatusColor(data.status),
      child: Text(
        data.status,
        style: TextStyle(
          fontWeight: FontWeight.bold, // Bold status text
          fontSize: 14,
          color: _getStatusColor(data.status), // Apply color for status
        ),
        textAlign: TextAlign.center,
      ),
    ),
                              _buildTableCell(
                                '',
                                child: IconButton(
                                  icon: const Icon(Icons.info,
                                      color: Colors.blue),
                                  onPressed: () =>
                                      _showActionsDialog(context, data),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add your onPressed logic here
        },
        child: const Icon(Icons.download, color: Colors.white),
        backgroundColor: const Color(0xFF4769B2),
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(String text,
      {Color? statusColor,
      bool isClickable = false,
      void Function()? onTap,
      Widget? child}) {
    print('Status: $text, Status Color: $statusColor');
    return GestureDetector(
      onTap: isClickable ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: isClickable ? Colors.transparent : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: child ??
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color:
                    isClickable ? Colors.blue : statusColor ?? Colors.black87,
                fontWeight: isClickable ? FontWeight.bold : FontWeight.normal,
                decoration: isClickable
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
      ),
    );
  }
Color _getStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'COMPLETED':
      return Colors.green;
    case 'IN PROGRESS':
    case 'IN-PROGRESS':
      return Colors.blue;
    case 'REJECTED':
      return Colors.red;
    case 'PENDING':
      return Colors.orange;
    default:
      return Colors.black87;
  }
}


  void _showActionsDialog(BuildContext context, TableSampleData data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          clipBehavior: Clip.antiAliasWithSaveLayer,
          backgroundColor: Colors.white,
          title: Text(
            'Actions for ${data.category}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          content: Container(
            width: 400,
            constraints: const BoxConstraints(maxHeight: 800),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Category: ${data.category}',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 3),
                  Text('Status: ${data.status}',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 3),
                  Text('Date: ${data.date.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 3),
                  if (data.sNo != null)
                    TextButton(
                      onPressed: () {},
                      child: Text('Track Receipt No. ${data.sNo}',
                          style: const TextStyle(color: Colors.blue)),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    height: 300, // Fixed height for the PDF viewer
                    child: SfPdfViewer.network(
                      "https://eofficess.com/images/${data.page}",
                      controller: _pgController,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        onPressed: () {
                          // Show another dialog for downloading PDF
                          _showDownloadDialog(context, data.sNo.toString());
                        },
                        child: const Text('View',
                            style: TextStyle(color: Colors.white)),
                      ),
                      // ElevatedButton(
                      //   style: ElevatedButton.styleFrom(
                      //       backgroundColor: Colors.blue),
                      //   onPressed: () {
                      //     // Add your share logic here
                      //   },
                      //   child: const Text('Share',
                      //       style: TextStyle(color: Colors.white)),
                      // ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }


//----------------------------------------------------------------
void _showDownloadDialog(BuildContext context, String id) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          'Download PDF for $id',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        content: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 800),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ID: $id', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                Container(
                  height: 300, // Fixed height for the PDF viewer
                  child: SfPdfViewer.network(
                    "https://eofficess.com/api/user-checklist-pdf/$id",
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      onPressed: () async {
                        final downloadUrl =
                            'https://eofficess.com/api/user-checklist-pdf/$id';
                        await _downloadFile(context, downloadUrl, id);

                        // Trigger a notification after a successful download
                        await NotificationService.showNotification(
                          title: 'Download Successful',
                          body: 'Checklist PDF for ID $id has been downloaded.',
                        );
                      },
                      child: const Text('Download',
                          style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue),
                      onPressed: () async {
                        final filePath =
                            '/storage/emulated/0/Download/$id.pdf';
                        await _shareFile(context, filePath, 'Checklist PDF');

                        // Trigger a notification after a successful share
                        await NotificationService.showNotification(
                          title: 'Share Successful',
                          body: 'Checklist PDF for ID $id is ready to share.',
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
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text("Close", style: TextStyle(color: Colors.black)),
          ),
        ],
      );
    },
  );
}

Future<void> _downloadFile(BuildContext context, String url, String id) async {
  try {
    // Define the path to the Downloads directory
    final downloadsDirectory = Directory('/storage/emulated/0/Download');

    // Ensure the directory exists
    if (!downloadsDirectory.existsSync()) {
      downloadsDirectory.createSync(recursive: true);
    }

    // Define the file path
    String savePath = '${downloadsDirectory.path}/$id.pdf';

    // Download the file
    Dio dio = Dio();
    await dio.download(url, savePath);

    // Show a SnackBar after successful download
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




  //----------------------------------------------------------------
}

class TableSampleData {
  TableSampleData({
    required this.sNo,
    required this.category,
    required this.status,
    required this.page,
    required this.date,
  });

  final int sNo;
  final String category;
  final String status;
  final String page;
  final DateTime date;
}
