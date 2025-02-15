import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eoffice/Screens/OtherScreens/nomination_form.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../Auth/login_screen.dart';
import '../../salary_R/services/notification_service.dart';

class NominationScreen extends StatefulWidget {
  const NominationScreen({super.key});

  @override
  State<NominationScreen> createState() => _NominationScreenState();
}

class _NominationScreenState extends State<NominationScreen> {
  List<Map<String, String>> _nominee = [];
  List<Map<String, String>> _filteredData = [];
  bool _isLoading = true;
  bool _hasError = false;
  String selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _fetchNomineeData();
  }

  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }


  Future<void> _fetchNomineeData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('id');

    try {
      String? token = await getAuthToken();
      if (token == null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
        throw Exception('User is not logged in');
      }
      final response = await http
          .get(Uri.parse('https://eofficess.com/api/nominations/$userId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print("RESPONSEDATA: $responseData");

        if (responseData['success']) {
          final List<dynamic> data = responseData['data']; // `data` is a List
          setState(() {
            _nominee = data.map<Map<String, String>>((item) {
              return {
                'sn': item['id']?.toString() ?? '',
                'nomination_type': item['nomination_type']?.toString() ?? '',
                'status': item['status']?.toString() ?? '',
              };
            }).toList();

            _filterNominee(selectedStatus);
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }else if(response.statusCode==401){
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _filterNominee(String status) {
    setState(() {
      if (status == 'All') {
        _filteredData = _nominee;
      } else {
        _filteredData = _nominee
            .where((nominee) => nominee['status'] == status.toLowerCase())
            .toList();
      }
    });
  }

//----------------------------------------------------------------
  void _showAction(String name, String status, String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Name: $name',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Status: $status', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Text('Id: $id', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),

              // Add PDF Viewer
              Container(
                height: 300, // Set a fixed height for the PDF viewer
                child: SfPdfViewer.network(
                  'https://eofficess.com/api/user-nomination-pdf/$id', // Dynamic PDF URL
                ),
              ),

              // Action Buttons (Download and Share)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () async {
                      final downloadUrl =
                          'https://eofficess.com/api/user-nomination-pdf/$id';
                      await _downloadFile(context, downloadUrl, id);

                      // Trigger a notification after a successful download
                      await NotificationService.showNotification(
                        title: 'Download Successful',
                        body: 'PDF downloaded for $name with ID $id.',
                      );
                    },
                    child: const Text('Download',
                        style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: () async {
                      final filePath = '/storage/emulated/0/Download/$id.pdf';
                      await _shareFile(context, filePath, name);

                      // Trigger a notification after a successful share
                      await NotificationService.showNotification(
                        title: 'Share Successful',
                        body: 'PDF for $name with ID $id is ready to share.',
                      );
                    },
                    child: const Text('Share',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Close", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadFile(
      BuildContext context, String url, String id) async {
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

  Future<void> _shareFile(
      BuildContext context, String filePath, String name) async {
    try {
      // Implement the share functionality here (using share_plus or similar package)
      // Example:
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Here is the PDF for $name.',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File ready for sharing.')),
      );
    } catch (e) {
      print("Error sharing file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share the file.')),
      );
    }
  }

// ----------------------------------------------------------------x
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nomination Screen',
            style: TextStyle(color: Colors.white, fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: const Color(0xFF4769B2),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              _filterNominee(value);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'All',
                child: Text('All'),
              ),
              const PopupMenuItem<String>(
                value: 'pending',
                child: Text('Pending'),
              ),
              const PopupMenuItem<String>(
                value: 'approved',
                child: Text('Approved'),
              ),
              const PopupMenuItem<String>(
                value: 'rejected',
                child: Text('Rejected'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? const Center(child: Text('No Data'))
              : _filteredData.isEmpty
                  ? const Center(child: Text('No Nomination data available'))
                  : Column(
                      children: [
                        Container(
                          color: Colors.blue[100],
                          child: Table(
                            border: TableBorder.all(),
                            columnWidths: const {
                              0: FractionColumnWidth(0.1),
                              1: FractionColumnWidth(0.4),
                              2: FractionColumnWidth(0.3),
                              3: FractionColumnWidth(0.2),
                            },
                            children: const [
                              TableRow(
                                children: [
                                  SizedBox(
                                      height: 60,
                                      child: Center(
                                          child: Text('Id',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold)))),
                                  SizedBox(
                                      height: 60,
                                      child: Center(
                                          child: Text('Nomination Type',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold)))),
                                  SizedBox(
                                      height: 60,
                                      child: Center(
                                          child: Text('Status',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold)))),
                                  SizedBox(
                                      height: 60,
                                      child: Center(
                                          child: Text('Info',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold)))),
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
                                1: FractionColumnWidth(0.4),
                                2: FractionColumnWidth(0.3),
                                3: FractionColumnWidth(0.2),
                              },
                              children: [
                                for (var item
                                    in _filteredData) // Create rows dynamically
                                  TableRow(
                                    children: [
                                      Container(
                                          height: 60,
                                          child: Center(
                                              child: Text('${item['sn']}'))),
                                      Container(
                                          height: 60,
                                          child: Center(
                                              child: Text(
                                                  "${item['nomination_type']}"))),
                                      Container(
                                        height: 60,
                                        child: Center(
                                          child: Text(
                                            item['status'] == 'approved_clerk'
                                                ? 'Pending From HOD'
                                                : item['status']!,
                                            style: TextStyle(
                                              color: item['status'] ==
                                                      'approved'
                                                  ? Colors.green
                                                  : item['status'] == 'rejected'
                                                      ? Colors.red
                                                      : Colors
                                                          .orange, // for 'pending' or other statuses
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                          height: 60,
                                          child: IconButton(
                                              onPressed: () => _showAction(
                                                  item['nomination_type']!,
                                                  item['status']!,
                                                  item['sn']!),
                                              icon: const Icon(
                                                Icons.info,
                                                color: Colors.blue,
                                              ))),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4769B2),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NominationForm()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
