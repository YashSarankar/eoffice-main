import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../Auth/login_screen.dart';

class AchievementForm extends StatefulWidget {
  @override
  _AchievementFormState createState() => _AchievementFormState();
}

class _AchievementFormState extends State<AchievementForm> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> achievementCategories =
      []; // Store categories with IDs and names
  String? selectedAchievementType;
  String? _selectedCategory;
  TextEditingController _achievementTextController = TextEditingController();
  TextEditingController _memoController = TextEditingController();
  File? _referenceDocument;
  bool isUserSignVerified = false;

  @override
  void initState() {
    super.initState();
    getAchievementCategories(); // Fetch categories when the form initializes
  }

  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Fetch achievement categories from API
  Future<void> getAchievementCategories() async {
    try{
      String? token = await getAuthToken();
      if (token == null) {
        throw Exception('User is not logged in');
      }
      final response = await http.post(
        Uri.parse('https://eofficess.com/api/get-category-achivement'),
        headers: {
          'Authorization': 'Bearer $token',
        }
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success']) {
          setState(() {
            achievementCategories = List<Map<String, dynamic>>.from(
              jsonResponse['data'].map((item) => {
                'id': item['id'],
                'name': item['name'],
                'memo': item['memo'], // Include memo here
              }),
            );
          });
        }  else if(response.statusCode==401){
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
        } else {
          print('Failed to load Achievement Categories');
        }
      }
    }catch(e){
      print(e);
    }
  }

  // Function to convert HTML to plain text
  String convertHtmlToPlainText(String html) {
    final document = parse(html);
    return document.body?.text ?? ''; // Return empty string if body is null
  }

  // Fetch the memo corresponding to the selected achievement category
  void _updateAchievementText() {
    if (_selectedCategory != null) {
      var selectedCategory = achievementCategories.firstWhere(
          (category) => category['id'].toString() == _selectedCategory,
          orElse: () => {'memo': ''});

      _achievementTextController.text =
          convertHtmlToPlainText(selectedCategory['memo']);
    } else {
      _achievementTextController.clear();
    }
  }

  // File picker for reference document
  Future<void> _pickReferenceDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (result != null) {
      setState(() {
        _referenceDocument = File(result.files.single.path!);
      });
    }
  }

  Future<void> _submitForm() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('id');

    var dio = Dio();

    File file = _referenceDocument!;

    String fileName = file.path.split('/').last;

    String path = file.path;

    FormData formData = FormData.fromMap({
      "user_id": userId,
      "achivement_name": _selectedCategory,
      "achivement_memo": _achievementTextController.text,
      "refrence_docs": await MultipartFile.fromFile(
        path,
        filename: fileName,
      ),
    });

    try {
      var response = await dio.post(
        "https://eofficess.com/api/achivement-store",
        data: formData,
      );

      if (response.statusCode == 201) {
        print("form submited");
      } else {
        print("form not submitted");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Form Not Submitted!!");
      print("error occurred  $e");
    }
  }

  onSubmitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_referenceDocument == null) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Center(
                child: Text(
                  "Please upload documents",
                  style: TextStyle(fontSize: 20),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Center(
                    child: Text(
                      "OK",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                )
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return WillPopScope(
              onWillPop: () async =>
                  false, // Prevent back navigation during upload
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    title: const Text(
                      "Uploading File",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.0),
                          child: CircularProgressIndicator(
                            // value: progress > 0 ? progress : null,
                            strokeWidth: 6.0,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );

        // Perform the form submission
        await _submitForm().whenComplete(() {
          Navigator.pop(context);
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Center(
                child: Text("Form Submitted"),
              ),
              backgroundColor: Colors.green,
            ),
          );
        });
      }
    }
  }

  void _verifyUserSignature() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Rounded corners
          ),
          contentPadding: const EdgeInsets.all(20), // Padding for content
          content: Column(
            mainAxisSize: MainAxisSize.min, // Adjust height dynamically
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 48,
              ),
              const SizedBox(height: 10),
              const Text(
                "Are You Sure?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isUserSignVerified = true;
                      Navigator.pop(context);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  ),
                  child: const Text(
                    "Yes",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  ),
                  child: const Text(
                    "No",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
          actionsAlignment: MainAxisAlignment.center, // Center-align buttons
        );
      },
    );
  }

  @override
  void dispose() {
    _achievementTextController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievement Form',
            style: TextStyle(color: Colors.white, fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        backgroundColor: const Color(0xFF4769B2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Dropdown for category selection
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text('Select Achievement'),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                items: achievementCategories
                    .map((category) => DropdownMenuItem<String>(
                          value: category['id'].toString(),
                          child: Text(category['name']),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                  _updateAchievementText();
                },
                validator: (value) =>
                    value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16.0),

              // Text area for achievement
              TextFormField(
                controller: _achievementTextController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Achievement Text (Formatted)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter achievement text' : null,
              ),
              const SizedBox(height: 16.0),

              // Upload reference document
              const Text('Reference Document (PDF/Image):',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4769B2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _pickReferenceDocument,
                child: Text(
                    _referenceDocument == null
                        ? 'Upload Document'
                        : 'Change Document',
                    style: const TextStyle(fontSize: 14, color: Colors.white)),
              ),
              if (_referenceDocument != null)
                Text('Document: ${_referenceDocument!.path.split('/').last}',
                    style: const TextStyle(fontSize: 14)),

              const SizedBox(height: 24.0),

              // User signature
              const Text('User Signature:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUserSignVerified
                      ? Colors.green
                      : const Color(0xFF4769B2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () =>
                    !isUserSignVerified ? _verifyUserSignature() : {},
                child: Text(!isUserSignVerified ? 'Verify' : 'Verified',
                    style: const TextStyle(fontSize: 14, color: Colors.white)),
              ),

              const SizedBox(height: 16.0),

              // Submit button
              ElevatedButton(
                onPressed: isUserSignVerified ? onSubmitForm : null,
                child: const Text('Submit Achievement',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUserSignVerified
                      ? const Color(0xFF4769B2)
                      : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
