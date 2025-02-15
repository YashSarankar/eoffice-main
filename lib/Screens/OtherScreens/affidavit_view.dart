import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eoffice/Screens/OtherScreens/affidavit_form.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../Auth/login_screen.dart';
import '../../salary_R/services/notification_service.dart';

class AffidavitView extends StatefulWidget {
  @override
  _AffidavitViewState createState() => _AffidavitViewState();
}

class _AffidavitViewState extends State<AffidavitView> {
  List<Map<String, String>> _affidavitData = []; // To store API response data
  List<Map<String, String>> _filteredData = []; // To store filtered data
  bool _isLoading = true; // To show loading indicator
  bool _hasError = false; // To handle errors
  String _selectedStatus = 'All'; // Track selected filter status

  @override
  void initState() {
    super.initState();
    _fetchAffidavitData(); // Fetch the affidavit data on initialization
  }

  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Function to fetch data from API
  Future<void> _fetchAffidavitData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('id');

    try {
      String? token = await getAuthToken();
      if (token == null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
        throw Exception('User is not logged in');
      }
      final response = await http.post(Uri.parse(
          'https://eofficess.com/api/get-user-affidavit?user_id=$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Assuming the data you want is in responseData['data'], update the table data
        if (responseData['success'] == true) {
          final List<dynamic> affidavits =
              responseData['data']; // Get the list of affidavits
          setState(() {
            _affidavitData = affidavits.map((affidavit) {
              return {
                'sn': affidavit['id']?.toString() ??
                    '', // Convert to string and handle null
                'affidavit_name': affidavit['affidavit_name']?.toString() ??
                    '', // Convert to string and handle null
                'status': affidavit['status']?.toString() ??
                    '', // Convert to string and handle null
              };
            }).toList();
            _filteredData = _affidavitData; // Initially show all data
            _isLoading = false;
          });
        } else if(response.statusCode==401){
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
        }else {
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
      print('Error: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  // Function to filter data based on selected status
  void _filterAffidavits(String status) {
    setState(() {
      _selectedStatus = status;
      if (status == 'All') {
        _filteredData = _affidavitData;
      } else {
        _filteredData = _affidavitData
            .where((affidavit) => affidavit['status'] == status.toLowerCase())
            .toList();
      }
    });
  }

//- - - - - - - ----------------------------------------------------------------
  void _showAction(String name, String status, String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Displaying the details of the affidavit
              Text(
                'Name: $name',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text('Status: $status', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Text('Id: $id', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),

              // Adding PDF Viewer inside the dialog
              Container(
                height: 300, // Fixed height for the PDF viewer
                child: SfPdfViewer.network(
                  'https://eofficess.com/api/user-affidavit-pdf/$id', // Dynamic PDF URL based on affidavit ID
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
                          'https://eofficess.com/api/user-affidavit-pdf/$id';
                      await _downloadFile(context, downloadUrl, id);
                    },
                    child: const Text('Download',
                        style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: () async {
                      final filePath = '/storage/emulated/0/Download/$id.pdf';
                      await _shareFile(context, filePath, 'Affidavit PDF');
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
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Close", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

// Download file logic
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

      // Trigger a notification after successful download
      await NotificationService.showNotification(
        title: 'Download Complete',
        body: 'The file has been successfully downloaded to $savePath.',
      );

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

// Share file logic
  Future<void> _shareFile(
      BuildContext context, String filePath, String title) async {
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
        const SnackBar(
            content: Text('File not found. Please download it first.')),
      );
      print("File not found: $filePath");
    }
  }

//----------------------------------------------------------------x
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Affidavit Data',
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
              _filterAffidavits(value);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? const Center(child: Text('No Data'))
              : _filteredData.isEmpty
                  ? const Center(child: Text('No affidavit data available'))
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
                                          child: Text('Affidavit Name',
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
                                                  "${item['affidavit_name']}"))),
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
                                                  item['affidavit_name']!,
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
      // Padding(
      //   padding: const EdgeInsets.all(16.0),
      //   child: Column(
      //     children: [
      //       Row(
      //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //         children: [
      //           // Title on the left
      //           const Text(
      //             'Affidavit Data',
      //             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      //           ),
      //           // Filter icon on the right side
      //
      //         ],
      //       ),
      //       const SizedBox(height: 20),
      //       _isLoading
      //           ? const Center(child: CircularProgressIndicator()) // Show loading indicator while fetching data
      //           : _hasError
      //           ? const Center(child: Text('Failed to load data')) // Show error message on failure
      //           : _filteredData.isEmpty
      //           ? const Center(child: Text('No affidavit data available')) // Show if no data is available
      //           : Expanded(
      //         child: DataTable(
      //           columns: const [
      //             DataColumn(label: Text('ID')),
      //             DataColumn(label: Text('Affidavit Name')),
      //             DataColumn(label: Text('Status')),
      //           ],
      //           rows: _filteredData.map((data) {
      //             return DataRow(
      //               cells: [
      //                 DataCell(Text(data['sn']!)),
      //                 DataCell(Text(data['affidavit_name']!)),
      //                 DataCell(
      //                   Text(
      //                     data['status']!,
      //                     style: TextStyle(
      //                       color: data['status'] == 'approved'
      //                           ? Colors.green
      //                           : data['status'] == 'rejected'
      //                           ? Colors.red
      //                           : Colors.yellow, // for 'pending'
      //                       fontWeight: FontWeight.bold,
      //                     ),
      //                   ),
      //                 ),
      //               ],
      //             );
      //           }).toList(),
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4769B2),
        onPressed: () async {
          // Navigate to the AffidavitForm screen and wait for the result
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AffidavitForm()),
          );

          // If the result is true, reload the affidavit data
          if (result == true) {
            _fetchAffidavitData();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
