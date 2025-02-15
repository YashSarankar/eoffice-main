import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:eoffice/Auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChecklistForm extends StatefulWidget {
  final String bookType;
  final int currentPage;
  final File pageFile;

  const ChecklistForm({
    Key? key,
    required this.bookType,
    required this.currentPage,
    required this.pageFile,
  }) : super(key: key);

  @override
  _ChecklistFormState createState() => _ChecklistFormState();
}

class _ChecklistFormState extends State<ChecklistForm> {
  String? selectedChecklistName;
  String? checklistCompleted;
  String? hasReceipt;
  String? selectedReceiptNumber;

  List<String> _checklistNames = [];
  List<String> _receiptNumbers = [];
  bool _isLoadingCategories = true;
  bool _isLoadingReceipts = true;
  int? _userId; // Variable to store user ID

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _getUserId(); // Fetch the user ID from SharedPreferences
  }

  Future<void> _getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userIdString = prefs.getString('id'); // Fetch as String

    if (userIdString != null) {
      setState(() {
        _userId = int.tryParse(userIdString); // Convert String to int
      });
      await _fetchReceiptNumbers(); // Fetch receipt numbers after setting userId
    }
  }
  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }


  Future<void> _fetchCategories() async {
    String? token = await getAuthToken();
    if (token == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
      throw Exception('User is not logged in');
    }
    final url = 'https://eofficess.com/api/get-book-checklist';
    try {
      final response = await http.post(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is List) {
          final dataList = data['data'] as List<dynamic>;
          setState(() {
            _checklistNames = dataList
                .map((item) =>
            (item as Map<String, dynamic>)['checklist_name'] as String)
                .toList();
            _isLoadingCategories = false;
          });
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (error) {
      print('Error fetching categories: $error');
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _fetchReceiptNumbers() async {
    if (_userId == null) return; // Check if userId is available
    final url =
        'https://eofficess.com/api/get-receipt-no?user_id=$_userId'; // Use the fetched user ID

    try {
      final response = await http.post(Uri.parse(url));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['receipts No'] is List) {
          final receiptList = data['receipts No'] as List<dynamic>;
          setState(() {
            _receiptNumbers = receiptList
                .map((item) =>
            (item as Map<String, dynamic>)['receipt_no'] as String)
                .toList();
            _isLoadingReceipts = false;
          });
        } else {
          throw Exception('Invalid response format for receipts');
        }
      } else {
        throw Exception('Failed to load receipt numbers');
      }
    } catch (error) {
      print('Error fetching receipt numbers: $error');
      setState(() {
        _isLoadingReceipts = false;
      });
    }
  }

  Future<bool> storeChecklist({
    required String checklistName,
    required String processStatus,
    // required String receiptProcessStatus,
    String? receiptNumber,
    required String status,
    required String receiptStatus,

  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('id');



    var dio = Dio();

    File file = widget.pageFile;
    String fileName = file.path.split('/').last;
    String path = file.path;



    FormData formData = FormData.fromMap({
     "page_file": await MultipartFile.fromFile(path, filename: fileName,),
      "checklist_name": checklistName,
      "process_status": processStatus,
      "page_no": widget.currentPage,
      "Status": status,
      "receipt_status":receiptStatus,
      "receipt_no": receiptNumber ?? '',
      "user_id": userId,
    });

    try{
      var response = await dio.post(
        'https://eofficess.com/api/store-checklist',
        data: formData,
      );

      if(response.statusCode == 201){

        final responseData = response.data;
        if(responseData['status']== "success"){
          return true;
        }else{
          return true;
        }

      }else{
        return false;
      }


    }catch (e){
      return false;
    }


  }



  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4769B2),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Add to ${widget.bookType}',
            style: const TextStyle(color: Colors.white, fontSize: 20)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              child: _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                ),
                value: selectedChecklistName,
                items: _checklistNames.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedChecklistName = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            if (selectedChecklistName != null) ...[
              Text('Is the category completed?',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 5),
              Row(
                children: [
                  Radio<String>(
                    value: 'Yes',
                    groupValue: checklistCompleted,
                    onChanged: (String? value) {
                      setState(() {
                        checklistCompleted = value;
                      });
                    },
                  ),
                  const Text('Yes'),
                  Radio<String>(
                    value: 'No',
                    groupValue: checklistCompleted,
                    onChanged: (String? value) {
                      setState(() {
                        checklistCompleted = value;
                      });
                    },
                  ),
                  const Text('No'),
                ],
              ),
            ],
            if (checklistCompleted == 'No') ...[
              const Text('Have you already applied for this receipt?',
                  style: TextStyle(fontSize: 16)),
              const SizedBox(height: 5),
              Row(
                children: [
                  Radio<String>(
                    value: 'Apply',
                    groupValue: hasReceipt,
                    onChanged: (String? value) {
                      setState(() {
                        hasReceipt = value;
                      });
                    },
                  ),
                  const Text('Apply'),
                  Radio<String>(
                    value: 'No Apply',
                    groupValue: hasReceipt,
                    onChanged: (String? value) {
                      setState(() {
                        hasReceipt = value;
                      });
                    },
                  ),
                  const Text('No Apply'),
                ],
              ),
            ],
            if (hasReceipt == 'Apply') ...[
              Text('Select Receipt No',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 5),
              _isLoadingReceipts
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Receipt No',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                ),
                value: selectedReceiptNumber,
                items: _receiptNumbers.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedReceiptNumber = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a receipt number';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4769B2),
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              onPressed: () async {
                if (selectedChecklistName == null) {
                  _showMessage('Please select a checklist name.');
                  return;
                }
                String processStatus = checklistCompleted! ;
                // String receiptProcessStatus = hasReceipt == 'Apply' ? 'Applied' : 'Not Applied';
                String status = checklistCompleted == 'Yes' ? 'pending' : 'pending';
                String receiptStatus = checklistCompleted == "Yes" ? "Completed" :
                hasReceipt == 'Apply' ? 'in-progress' : 'Pending';

                if (await storeChecklist(
                  checklistName: selectedChecklistName!,
                  processStatus: processStatus,
                  receiptNumber: selectedReceiptNumber,
                  status: status,
                  receiptStatus: receiptStatus,

                )) {
                  _showMessage('Checklist submitted successfully!');
                  Navigator.pop(context);
                } else {
                  _showMessage('Failed to submit checklist. Please try again.');
                }
              },
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
