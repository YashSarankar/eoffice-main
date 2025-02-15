import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../Auth/login_screen.dart';
import '../../salary_R/services/notification_service.dart';

class TotalLeaveRequests extends StatefulWidget {
  const TotalLeaveRequests({Key? key}) : super(key: key);

  @override
  State<TotalLeaveRequests> createState() => _TotalLeaveRequestsState();
}

class _TotalLeaveRequestsState extends State<TotalLeaveRequests> {
  List<Map<String, dynamic>> leaveRequests = [];
  List<bool> _selectedItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLeaveRequests();
  }
  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }


  Future<void> fetchLeaveRequests() async {
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
            leaveRequests =
            List<Map<String, dynamic>>.from(data['Total Leaves Request']);
            _selectedItems =
                List.generate(leaveRequests.length, (index) => false);
          } else if(response.statusCode==401){
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
          } else {
            print('Failed to fetch leave requests: ${data['message']}');
          }
        } else {
          print('Failed to fetch leave requests: ${response.statusCode}');
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
          content: Container(
            width: 400,
            constraints: const BoxConstraints(maxHeight: 800),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 300,
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
                          await _downloadFile(apiUrl);
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
                          await _shareFile(apiUrl);
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

  Future<void> _downloadFile(String url) async {
    try {
      // Request storage permission
      if (await Permission.storage.request().isGranted) {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          // Get the Download directory path
          final directory = Directory('/storage/emulated/0/Download');
          if (!directory.existsSync()) {
            directory.createSync();
          }

          // Define file path
          final filePath = '${directory.path}/leave_request.pdf';
          final file = File(filePath);

          // Write file to Download directory
          await file.writeAsBytes(response.bodyBytes);

          // Trigger notification
          await NotificationService.showNotification(
            title: 'Download Complete',
            body: 'PDF saved to $filePath',
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _shareFile(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/leave_request.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        await Share.shareXFiles([XFile(filePath)],
            text: 'Check out this PDF file!');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download PDF for sharing')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool anySelected = _selectedItems.contains(true);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: anySelected
          ? FloatingActionButton(
        onPressed: () {
          final selectedIndex = _selectedItems.indexWhere((item) => item);
          if (selectedIndex != -1) {
            final leaveId = leaveRequests[selectedIndex]['id'].toString();
            final pdfUrl =
                'https://eofficess.com/api/user-leave-pdf/$leaveId';
            _showPdfDialog(pdfUrl);
          }
        },
        child: const Icon(Icons.download, color: Colors.white),
        backgroundColor: const Color(0xFF4769B2),
      )
          : null,
      appBar: AppBar(
        title: const Text('Total Leave Requests',
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : leaveRequests.isEmpty
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
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: leaveRequests.length,
                itemBuilder: (context, index) {
                  final request = leaveRequests[index];
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
                        style: TextStyle(
                          color: request['status'] == 'approved'
                              ? Colors.green
                              : request['status'] == 'pending'
                              ? Colors.orange
                              : Colors.red,
                          fontWeight: FontWeight.bold, // Ensures text is bold
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
