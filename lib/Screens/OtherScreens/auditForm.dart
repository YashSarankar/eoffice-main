import 'dart:convert';

import 'package:eoffice/Screens/OtherScreens/audit_add_form.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../Auth/login_screen.dart';

class AuditForm extends StatefulWidget {
  @override
  _AuditFormState createState() => _AuditFormState();
}

class _AuditFormState extends State<AuditForm> {
  List<Map<String, String>> _auditData = [];
  List<Map<String, String>> _filteredData = []; // To store API response data
  bool _isLoading = true; // To show loading indicator
  bool _hasError = false;
  String selectedStatus = 'All';

// To handle errors

  @override
  void initState() {
    super.initState();
    _fetchAuditData();
  }

  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchAuditData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('id');

    try {
      String? token = await getAuthToken();
      if (token == null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
        throw Exception('User is not logged in');
      }
      final response = await http.post(Uri.parse(
          'https://eofficess.com/api/get-user-audit?user_id=$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Assuming the data you want is in responseData['data'], update the table data
        if (responseData['success'] == true) {
          final List<dynamic> audits =
              responseData['data']; // Get the list of audits
          setState(() {
            // Convert dynamic response to a list of maps with string types
            _auditData = audits.map((audit) {
              return {
                'sn': audit['id']?.toString() ??
                    '', // Convert to string and handle null
                'audit_name': audit['audit_name']?.toString() ??
                    '', // Convert to string and handle null
                'status': audit['status']?.toString() ??
                    '', // Convert to string and handle null
              };
            }).toList();

            _filterAudit(selectedStatus);

            _isLoading = false;
          });
        }else if(response.statusCode==401){
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
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
      print('Error: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _filterAudit(String status) {
    setState(() {
      if (status == 'All') {
        _filteredData = _auditData;
      } else {
        _filteredData = _auditData
            .where((audit) => audit['status'] == status.toLowerCase())
            .toList();
      }
    });
  }

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
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text('Status: $status', style: TextStyle(fontSize: 14)),
                SizedBox(height: 8),
                Text('Id: $id', style: TextStyle(fontSize: 14)),
                SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      onPressed: () async {
                        // Add your download logic here
                      },
                      child: Text('Download',
                          style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue),
                      onPressed: () {
                        // Share.share(imageUrl);
                      },
                      child:
                          Text('Share', style: TextStyle(color: Colors.white)),
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
                  child: Text(
                    "Close",
                    style: TextStyle(color: Colors.black),
                  ))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Data',
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
              _filterAudit(value);
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
                  ? const Center(child: Text('No audit data available'))
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
                                          child: Text('Audit Name',
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
                                                  "${item['audit_name']}"))),
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
                                                  item['audit_name']!,
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4769B2),
        onPressed: () async {
          // Navigate to StoreAuditForm and wait for the result
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => StoreAuditForm()),
          );

          // Check if the result indicates that new audit data was added
          if (result == true) {
            _fetchAuditData(); // Refresh audit data
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
