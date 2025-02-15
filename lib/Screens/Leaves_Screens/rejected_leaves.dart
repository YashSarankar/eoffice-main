import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../Auth/login_screen.dart';
import '../../salary_R/services/notification_service.dart';

class RejectedLeaves extends StatefulWidget {
  const RejectedLeaves({Key? key}) : super(key: key);

  @override
  State<RejectedLeaves> createState() => _RejectedLeavesState();
}

class _RejectedLeavesState extends State<RejectedLeaves> {
  List<Map<String, dynamic>> rejectedLeaveRequests = [];
  List<bool> _selectedItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRejectedLeaves();
  }

  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> fetchRejectedLeaves() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('id');
    try{
      String? token = await getAuthToken();
      if (token == null) {
        throw Exception('User is not logged in');
      }
      if (userId != null) {
        final response = await http.post(
          Uri.parse(
              'https://eofficess.com/api/get-user-leaves?user_id=$userId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = json.decode(response.body);
          if (data['success']) {
            final List<Map<String, dynamic>> totalRejectedRequests =
            List<Map<String, dynamic>>.from(data['Total Rejected Request']);
            rejectedLeaveRequests = totalRejectedRequests;
            _selectedItems =
                List.generate(rejectedLeaveRequests.length, (index) => false);
          } else if(response.statusCode==401){
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
          } else {
            print('Failed to fetch rejected leave requests: ${data['message']}');
          }
        } else {
          print(
              'Failed to fetch rejected leave requests: ${response.statusCode}');
        }
      } else {
        print('User ID not found in shared preferences');
      }

      setState(() {
        isLoading = false;
      });
    }catch(e){
      print(e);
    }
  }

  // Toggle item selection
  void _toggleSelection(int index) {
    setState(() {
      _selectedItems[index] = !_selectedItems[index];
    });
  }

  // Show PDF dialog
 void _showPdfDialog(String apiUrl) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        backgroundColor: Colors.white,
        title: const Text(
          'Preview PDF',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        content: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 800),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 300, // Fixed height for the PDF viewer
                  child: SfPdfViewer.network(apiUrl),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () async {
                        try {
                          final response = await http.get(Uri.parse(apiUrl));
                          if (response.statusCode == 200) {
                            final directory =
                                Directory('/storage/emulated/0/Download');
                            if (!directory.existsSync()) {
                              directory.createSync();
                            }
                            final file = File('${directory.path}/leave_request.pdf');
                            await file.writeAsBytes(response.bodyBytes);

                            // Trigger notification on download success
                            await NotificationService.showNotification(
                              title: 'Download Complete',
                              body: 'PDF saved to ${file.path}',
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download successful!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.fixed,
          ),
        );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to download PDF')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                      child: const Text(
                        'Download',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: () async {
                        try {
                          final response = await http.get(Uri.parse(apiUrl));
                          if (response.statusCode == 200) {
                            final directory = await getTemporaryDirectory();
                            final file = File('${directory.path}/leave_request_share.pdf');
                            await file.writeAsBytes(response.bodyBytes);

                            // Use share_plus package to share the file
                            await Share.shareXFiles(
                              [XFile(file.path)],
                              text: 'Here is your leave request PDF.',
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to fetch PDF for sharing')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                      child: const Text(
                        'Share',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
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


  // Download selected leave requests as PDF
  void _downloadPdf() async {
    final pdf = pw.Document();
    List<Map<String, dynamic>> selectedRequests = [];

    // Collect selected leave requests
    for (int i = 0; i < rejectedLeaveRequests.length; i++) {
      if (_selectedItems[i]) {
        selectedRequests.add(rejectedLeaveRequests[i]);
      }
    }

    // Only create PDF if there are selected requests
    if (selectedRequests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No leave requests selected')),
      );
      return;
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Rejected Leave Requests',
                  style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Name', 'Leave Type', 'From', 'To', 'Status'],
                  ...selectedRequests.map((request) {
                    return [
                      request['subject']?.toString() ?? '',
                      request['leave_category']?.toString() ?? '',
                      DateFormat('yyyy-MM-dd')
                          .format(DateTime.parse(request['start_date'])),
                      DateFormat('yyyy-MM-dd')
                          .format(DateTime.parse(request['end_date'])),
                      request['status'].toString().capitalize(),
                    ];
                  }).toList(),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF to the device
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/rejected_leave_requests.pdf");
    await file.writeAsBytes(await pdf.save());

    // Provide feedback to the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF downloaded to: ${file.path}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool anySelected = _selectedItems.contains(true);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: anySelected
          ? FloatingActionButton(
              onPressed: () {
                // Show the dialog when the FAB is clicked
                String? leaveId = rejectedLeaveRequests.firstWhere((request) => _selectedItems[rejectedLeaveRequests.indexOf(request)])['id'].toString();
                _showPdfDialog('https://eofficess.com/api/user-leave-pdf/$leaveId');
              },
              child: Icon(Icons.download, color: Colors.white),
              backgroundColor: Color(0xFF4769B2),
            )
          : null,
      appBar: AppBar(
        title: const Text('Rejected Leaves', style: TextStyle(color: Colors.white, fontSize: 20)),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: const Color(0xFF4769B2),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : rejectedLeaveRequests.isEmpty
          ? const Center(
        child: Text(
          'No leave requests available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: rejectedLeaveRequests.length,
                      itemBuilder: (context, index) {
                        final request = rejectedLeaveRequests[index];
                        return Card(
                          elevation: 2,
                          color: Colors.white,
                          child: ListTile(
                            leading: Checkbox(
                              value: _selectedItems[index],
                              onChanged: (bool? value) {
                                _toggleSelection(index);
                              },
                            ),
                            title: Text(
                              '${request['subject']} - ${request['leave_category']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              'From: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(request['start_date']))}\n'
                              'To: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(request['end_date']))}',
                            ),
                            trailing: Text(
  request['status'] == 'approved_clerk'
      ? 'Pending From HOD'
      : request['status'].toString(),
  style: TextStyle(
    color: request['status'] == 'approved'
        ? Colors.green
        : request['status'] == 'pending' || request['status'] == 'approved_clerk'
            ? Colors.orange
            : Colors.red,
    fontWeight: FontWeight.bold,
  ),
),

                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

extension StringCapitalize on String {
  String capitalize() {
    return isNotEmpty ? this[0].toUpperCase() + substring(1).toLowerCase() : '';
  }
}
