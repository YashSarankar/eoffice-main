import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eoffice/Auth/login_screen.dart';
import 'package:eoffice/Screens/OtherScreens/achievment_form.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../salary_R/services/notification_service.dart';

class AchievementView extends StatefulWidget {
  @override
  _AchievementViewState createState() => _AchievementViewState();
}

class _AchievementViewState extends State<AchievementView> {
  List<Map<String, String>> _achievementData = [];
  List<Map<String, String>> _filteredData = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _fetchAchievementData();
  }

  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Function to fetch data from API
  Future<void> _fetchAchievementData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('id');

    try {
      String? token = await getAuthToken();
      if (token == null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
        throw Exception('User is not logged in');
      }
      final response = await http.post(Uri.parse(
          'https://eofficess.com/api/get-user-achivement?user_id=$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> achievements =
              responseData['data']; // Get the list of achievements
          setState(() {
            _achievementData = achievements.map((achievement) {
              return {
                'sn': achievement['id']?.toString() ??
                    '', // Convert to string and handle null
                'achievement_name':
                    achievement['achivement_name']?.toString() ??
                        '', // Convert to string and handle null
                'status': achievement['status']?.toString() ??
                    '', // Convert to string and handle null
              };
            }).toList();
            _filteredData = _achievementData; // Initially show all data
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
  void _filterAchievements(String status) {
    setState(() {
      _selectedStatus = status;
      if (status == 'All') {
        _filteredData = _achievementData;
      } else {
        _filteredData = _achievementData
            .where(
                (achievement) => achievement['status'] == status.toLowerCase())
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('Status: $status', style: TextStyle(fontSize: 14)),
              SizedBox(height: 8),
              Text('Id: $id', style: TextStyle(fontSize: 14)),
              SizedBox(height: 16),

              // Add PDF Viewer inside the dialog
              Container(
                height: 300, // Fixed height for the PDF viewer
                child: SfPdfViewer.network(
                  'https://eofficess.com/api/user-acheivment-pdf/$id', // Dynamic PDF URL based on achievement ID
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
                          'https://eofficess.com/api/user-acheivment-pdf/$id';
                      await _downloadFile(context, downloadUrl, id);
                    },
                    child:
                        Text('Download', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: () async {
                      final filePath = '/storage/emulated/0/Download/$id.pdf';
                      await _shareFile(context, filePath, 'Achievement PDF');
                    },
                    child: Text('Share', style: TextStyle(color: Colors.white)),
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
              child: Text("Close", style: TextStyle(color: Colors.black)),
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

      // Trigger a notification after successful download
      await NotificationService.showNotification(
        title: 'Download Complete',
        body: 'The PDF has been successfully downloaded to $savePath.',
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
        title: const Text('Achievement Data',
            style: TextStyle(color: Colors.white, fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              _filterAchievements(value);
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
        backgroundColor: const Color(0xFF4769B2),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? const Center(child: Text('No Data'))
              : _filteredData.isEmpty
                  ? const Center(child: Text('No achievement data available'))
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
                                          child: Text('Achievement Name',
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
                                                  "${item['achievement_name']}"))),
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
                                                          .orange, // For 'pending' or other statuses
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                          height: 60,
                                          child: IconButton(
                                              onPressed: () => _showAction(
                                                  item['achievement_name']!,
                                                  item['status']!,
                                                  item['sn']!),
                                              icon: Icon(
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
      //       _isLoading
      //           ? const Center(child: CircularProgressIndicator()) // Show loading indicator while fetching data
      //           : _hasError
      //           ? const Center(child: Text('Failed to load data')) // Show error message on failure
      //           : _filteredData.isEmpty
      //           ? const Center(child: Text('No achievement data available')) // Show if no data is available
      //           : Expanded(
      //         child: SingleChildScrollView(
      //           scrollDirection: Axis.horizontal, // Enable horizontal scrolling
      //           child: DataTable(
      //             columns: const [
      //               DataColumn(label: Text('ID')),
      //               DataColumn(label: Text('Achievement Name')),
      //               DataColumn(label: Text('Status')),
      //               DataColumn(label: Text('Action')),
      //             ],
      //             rows: _filteredData.map((data) {
      //               return DataRow(
      //                 cells: [
      //                   DataCell(Text(data['sn']!)),
      //                   DataCell(Text(data['achievement_name']!)),
      //                   DataCell(
      //                     Text(
      //                       data['status']!,
      //                       style: TextStyle(
      //                         color: data['status'] == 'approved'
      //                             ? Colors.green
      //                             : data['status'] == 'rejected'
      //                             ? Colors.red
      //                             : Colors.orange, // for 'pending'
      //                         fontWeight: FontWeight.bold,
      //                       ),
      //                     ),
      //                   ),
      //                   DataCell(
      //                     Row(children: [
      //                       IconButton(onPressed: (){}, icon: Icon(Icons.download)),
      //                       IconButton(onPressed: (){}, icon: Icon(Icons.remove_red_eye)),
      //                       IconButton(onPressed: (){}, icon: Icon(Icons.share)),
      //
      //
      //                     ],)
      //                   ),
      //                 ],
      //               );
      //             }).toList(),
      //           ),
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4769B2),
        onPressed: () async {
          // Await the result from AchievementForm
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AchievementForm()),
          );

          // Check if new data was added (result is true)
          if (result == true) {
            _fetchAchievementData(); // Reload data if a new achievement was added
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
