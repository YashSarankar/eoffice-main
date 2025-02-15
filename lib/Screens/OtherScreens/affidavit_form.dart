import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:html/parser.dart' show parse;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Auth/login_screen.dart';

class AffidavitForm extends StatefulWidget {
  @override
  _AffidavitFormState createState() => _AffidavitFormState();
}

class _AffidavitFormState extends State<AffidavitForm> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> affidavitCategories = []; // Store categories with IDs and names
  String? selectedAffidavitType;
  String? _selectedCategory;
  TextEditingController _affidavitTextController = TextEditingController();
  TextEditingController _memoController = TextEditingController();
  File? _referenceDocument;
  String? userId;
  double progress = 0.0;
  bool isWitnessVerified = false;
  final _formFieldKey = GlobalKey<FormFieldState>();
  final _formFieldKeyOTP = GlobalKey<FormFieldState>();
  final TextEditingController witnessController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getLeaveCategory();
    fetchAndSetUserId();
  }




  void fetchAndSetUserId()async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('id');
  }


  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }


  // Fetch affidavit categories from API
  Future<void> getLeaveCategory() async {
   try{
     String? token = await getAuthToken();
     if (token == null) {
       throw Exception('User is not logged in');
     }
     final response = await http.post(
       Uri.parse('https://eofficess.com/api/get-category-affidavit'),
         headers: {
           'Authorization': 'Bearer $token',
         }
     );
     if (response.statusCode == 200 || response.statusCode == 201) {
       final jsonResponse = json.decode(response.body);
       if (jsonResponse['success']) {
         setState(() {
           affidavitCategories = List<Map<String, dynamic>>.from(
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
         // Handle error
         print('Failed to load Affidavit Category');
       }
     }
   }catch(e){
     print(e);
   }
  }





  String convertHtmlToPlainText(String htmlText) {
    // Regular expression to remove all HTML tags
    final RegExp htmlTagRegExp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    // Replace the HTML tags with an empty string
    return htmlText.replaceAll(htmlTagRegExp, '').trim();
  }



  // Fetch the memo corresponding to the selected affidavit category
  void _updateAffidavitText() {
    if (_selectedCategory != null) {
      // Find the selected category or return an empty map if not found
      var selectedCategory = affidavitCategories.firstWhere(
              (category) => category['id'].toString() == _selectedCategory,
          orElse: () => {'memo': ''} // Return a map with an empty memo
      );

      print("SELECTED CATEGORY ${selectedCategory['memo']}");
      // Update the affidavit text area with the corresponding memo converted to plain text
      var plainTextMemo = convertHtmlToPlainText(selectedCategory['memo']);
      _affidavitTextController.text = plainTextMemo ?? '';


    } else {
      _affidavitTextController.clear(); // Clear if not found
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


  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.grey[800],
      ),
    );
  }


  Future<bool> sendOTP(String mobNo)async{
    if(userId == null){
      _showErrorSnackbar("Invalid UserId");
    }

    final uri =
    Uri.parse("https://eofficess.com/api/verify-witness-otp?user_id=$userId"
        "&witness_mobile_no=$mobNo");


    try{
      final response = await http.post(uri);
      if(response.statusCode == 200 || response.statusCode == 201){
        return true;
      }else{
        _showErrorSnackbar("Please check witness number");
        return false;
      }
    }catch(e){
      _showErrorSnackbar("Error in sending OTP");
      return false;
    }


  }

  Future<bool> validateOTP(String OTP, String mobNo)async{
    final uri = Uri.parse("https://eofficess.com/api/confirm-witness-otp?otp=$OTP&witness_mobile_no=$mobNo");

    try{
      final response = await http.post(uri);
      if(response.statusCode == 200 || response.statusCode == 201){
        return true;
      }else{
        _showErrorSnackbar("Incorrect OTP");
        return false;
      }
    }catch(e){
      _showErrorSnackbar("Error occurred while verifying OTP");
      return false;
    }


  }



  Future<void> _submitForm()async{
    var dio = Dio();

    File file1 = _referenceDocument!;


    String fileName1 = file1.path.split('/').last;


    String path1 = file1.path;

    
    FormData formData = FormData.fromMap({
      "user_id": userId,
      "affidavit_name": _selectedCategory,
      "affidavit_memo": _affidavitTextController.text,
      "witness_mobile_no": witnessController.text,
      "refrence_docs": await MultipartFile.fromFile(path1, filename: fileName1,),

    });
    
    try{

      var response = await dio.post(
        "https://eofficess.com/api/affidavit-store",
        data: formData,
      );

      if(response.statusCode == 201){
        _showErrorSnackbar("Submitted");
      }else{
        _showErrorSnackbar("Not Submitted");
      }

    }catch(e){
      Fluttertoast.showToast(msg: "Form Not Submitted!!");
      print("error occurred  $e");
    }
  }



  onSubmitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_referenceDocument == null ) {
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
              onWillPop: () async => false, // Prevent back navigation during upload
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Center(child: Text("Form Submitted"),),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
          Navigator.pop(context, true);
        });

      }
    }
  }


  void _witnessVerification() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Enter Witness Number",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Adjust content size to fit
              children: [
                TextFormField(
                  key: _formFieldKey,
                  controller: witnessController,
                  decoration: InputDecoration(
                    hintText: "Enter 10-digit mobile number",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a mobile number';
                    }
                    final regex = RegExp(r'^[0-9]{10}$');
                    if (!regex.hasMatch(value)) {
                      return 'Please enter a valid 10-digit mobile number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    if (_formFieldKey.currentState!.validate()) {
                      final isOTPSend = await sendOTP(witnessController.text);
                      if (isOTPSend) {
                        Navigator.pop(context);
                        _otpDialog(witnessController.text);
                      }
                    }
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
                    "Send OTP",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    witnessController.clear();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }



  void _otpDialog(String mobNo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Enter OTP",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: _formFieldKeyOTP,
                controller: otpController,
                decoration: InputDecoration(
                  hintText: "Enter 6-digit OTP",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  hintStyle: TextStyle(color: Colors.grey[600]),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the OTP';
                  }
                  final regex = RegExp(r'^\d{6}$');
                  if (!regex.hasMatch(value)) {
                    return 'Please enter a valid 6-digit OTP';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    if (_formFieldKeyOTP.currentState!.validate()) {
                      final isVerify = await validateOTP(otpController.text, mobNo);
                      if (isVerify) {
                        otpController.clear();
                        Navigator.pop(context);
                        setState(() {
                          isWitnessVerified = true;
                        });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 20,
                    ),
                  ),
                  child: const Text(
                    "Verify",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    otpController.clear();
                    witnessController.clear();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 20,
                    ),
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }




  @override
  void dispose() {
    _affidavitTextController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Affidavit Form', style: TextStyle(color: Colors.white, fontSize: 20)),
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
                hint: const Text('Select Affidavit'),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                items: affidavitCategories.map((category) => DropdownMenuItem<String>(
                  value: category['id'].toString(), // Use ID as the value
                  child: Text(category['name']),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                  _updateAffidavitText(); // Update affidavit text when category changes
                },
                validator: (value) => value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16.0),

              // Text area for affidavit
              TextFormField(
                controller: _affidavitTextController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Affidavit Text (Formatted)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter affidavit text' : null,
              ),
              const SizedBox(height: 16.0),
              // Upload reference document
              const Text('Reference Document (PDF/Image):', style: TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4769B2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _pickReferenceDocument,
                child: Text(_referenceDocument == null ? 'Upload Document' : 'Change Document', style: const TextStyle(fontSize: 14, color: Colors.white)),
              ),
              if (_referenceDocument != null)
                Text('Document: ${_referenceDocument!.path.split('/').last}', style: const TextStyle(fontSize: 14)),

              const SizedBox(height: 24.0),


              const Text('Witness Signature:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: !isWitnessVerified ?const Color(0xFF4769B2) : Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => !isWitnessVerified? _witnessVerification() : {},  // false means it's witness signature
                child: Text(!isWitnessVerified ? 'Verify Witness Signature' : 'Witness Signature is verified', style: const TextStyle(fontSize: 14, color: Colors.white)),
              ),

              const SizedBox(height: 32.0),

              // Submit button
              ElevatedButton(
                onPressed: (){onSubmitForm();},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4769B2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Submit', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
