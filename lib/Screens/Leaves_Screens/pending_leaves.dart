import 'dart:convert';
import 'dart:io';
import 'package:eoffice/Auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../salary_R/services/notification_service.dart';

class PendingLeaves extends StatefulWidget {
  const PendingLeaves({Key? key}) : super(key: key);

  @override
  State<PendingLeaves> createState() => _PendingLeavesState();
}

class _PendingLeavesState extends State<PendingLeaves> {
  List<Map<String, dynamic>> pendingLeaveRequests = [];
  List<bool> _selectedItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPendingLeaves();
  }

  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> fetchPendingLeaves() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('id');
    try{
      String? token = await getAuthToken();
      if (token == null) {
        throw Exception('User is not logged in');
      }
      if (userId != null) {
        final response = await http.post(
          Uri.parse('https://eofficess.com/api/get-user-leaves?user_id=$userId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = json.decode(response.body);
          if (data['success']) {
            pendingLeaveRequests =
            List<Map<String, dynamic>>.from(data['Total Pending Request']);
            _selectedItems = List.generate(
                pendingLeaveRequests.length, (index) => false);
          } else if(response.statusCode==401){
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
          }else {
            print('Failed to fetch pending leave requests: ${data['message']}');
          }
        } else {
          print('Failed to fetch pending leave requests: ${response.statusCode}');
        }
      } else {
        print('User ID not found in shared preferences');
      }

      setState(() {
        isLoading = false;
      });
    }catch(e){
      print('Error: $e');
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      _selectedItems[index] = !_selectedItems[index];
    });
  }

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
        content: SizedBox(
          height: 400,
          child: Column(
            children: [
              Expanded(
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
                          final directory = Directory('/storage/emulated/0/Download');
                          if (!directory.existsSync()) {
                            directory.createSync();
                          }
                          final file = File('${directory.path}/leave_request.pdf');
                          await file.writeAsBytes(response.bodyBytes);

                          // Trigger notification using NotificationService
                          await NotificationService.showNotification(
                            title: 'Download Successful',
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
                            const SnackBar(
                              content: Text('Failed to download PDF'),
                            ),
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
                  const SizedBox(height: 10),
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
                            const SnackBar(
                              content: Text('Failed to fetch PDF for sharing'),
                            ),
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



  @override
  Widget build(BuildContext context) {
    bool anySelected = _selectedItems.contains(true);
    String? selectedLeaveId;
    if (anySelected) {
      selectedLeaveId = pendingLeaveRequests[_selectedItems.indexOf(true)]['id']
          .toString();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pending Leaves',
            style: TextStyle(color: Colors.white, fontSize: 20)),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: const Color(0xFF4769B2),
      ),
      floatingActionButton: anySelected
          ? FloatingActionButton(
              onPressed: () {
                if (selectedLeaveId != null) {
                  _showPdfDialog(
                      'https://eofficess.com/api/user-leave-pdf/$selectedLeaveId');
                }
              },
              child: const Icon(Icons.download, color: Colors.white),
              backgroundColor: const Color(0xFF4769B2),
            )
          : null,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pendingLeaveRequests.isEmpty
          ? const Center(
        child: Text(
          'No leave requests available.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      )
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: ListView.builder(
          itemCount: pendingLeaveRequests.length,
          itemBuilder: (context, index) {
            final request = pendingLeaveRequests[index];
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
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  'From: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(request['start_date']))}\n'
                      'To: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(request['end_date']))}',
                ),
                trailing: Text(
                  request['status'] == 'approved_clerk'
                      ? 'Pending From HOD'
                      : request['status'].toString().capitalize(),
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),

    );
  }
}

extension StringCapitalize on String {
  String capitalize() {
    return isNotEmpty
        ? this[0].toUpperCase() + substring(1).toLowerCase()
        : '';
  }
}
