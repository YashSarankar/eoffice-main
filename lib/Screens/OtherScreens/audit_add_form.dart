import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../Auth/login_screen.dart';
import 'auditForm.dart';

class StoreAuditForm extends StatefulWidget {
  @override
  _StoreAuditPageState createState() => _StoreAuditPageState();
}

class _StoreAuditPageState extends State<StoreAuditForm> {
  final _formKey = GlobalKey<FormState>();

  String? _userId;
  String? _auditName;
  String? _description;
  String? _auditRemark;
  String? _auditorName;
  String? _reasonDescription;
  String? _position;
  String? _organisationName;
  String? _auditorVerificationDescription;
  bool isUserSignVerified = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('id'); // Assuming 'id' is stored as user ID
    });
  }

  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        String? token = await getAuthToken();
        if (token == null) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
          throw Exception('User is not logged in');
        }
        final response = await http.post(
          Uri.parse('https://eofficess.com/api/store-audit'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'user_id': _userId,
            'audit_name': _auditName,
            'description': _description,
            'audit_remark': _auditRemark,
            'auditor_name': _auditorName,
            'reason_description': _reasonDescription,
            'position': _position,
            'organisation_name': _organisationName,
            'auditor_veri_des': _auditorVerificationDescription,
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audit stored successfully')),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }else if(response.statusCode==401){
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
        } else {
          throw Exception('Failed to store audit');
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to store audit')),
        );
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
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isUserSignVerified = true;
                        Navigator.pop(context);
                      });
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    ),
                    child: const Text(
                      "Yes",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    ),
                    child: const Text(
                      "No",
                      style: TextStyle(
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

        });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF4769B2),
          title: const Text(
            'Add Audit Details',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),

        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTextFormField(
                    label: 'Audit Name',
                    onChanged: (value) {
                      setState(() {
                        _auditName = value;
                      });
                    },
                  ),
                  _buildTextFormField(
                    label: 'Description',
                    onChanged: (value) {
                      setState(() {
                        _description = value;
                      });
                    },
                  ),
                  _buildTextFormField(
                    label: 'Audit Remark',
                    onChanged: (value) {
                      setState(() {
                        _auditRemark = value;
                      });
                    },
                  ),
                  _buildTextFormField(
                    label: 'Auditor Name',
                    onChanged: (value) {
                      setState(() {
                        _auditorName = value;
                      });
                    },
                  ),
                  _buildTextFormField(
                    label: 'Reason Description',
                    onChanged: (value) {
                      setState(() {
                        _reasonDescription = value;
                      });
                    },
                  ),
                  _buildTextFormField(
                    label: 'Position',
                    onChanged: (value) {
                      setState(() {
                        _position = value;
                      });
                    },
                  ),
                  _buildTextFormField(
                    label: 'Organisation Name',
                    onChanged: (value) {
                      setState(() {
                        _organisationName = value;
                      });
                    },
                  ),
                  _buildTextFormField(
                    label: 'Auditor Verification Description',
                    onChanged: (value) {
                      setState(() {
                        _auditorVerificationDescription = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      isUserSignVerified ? null : _verifyUserSignature();
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize:
                          const Size(double.infinity, 50), // Full-width button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: isUserSignVerified
                          ? Colors.green
                          : const Color(0xFF4769B2), // Change button color
                    ),
                    child: Text(
                      !isUserSignVerified ? 'Verify' : 'Verified',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isUserSignVerified ? _submitForm : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize:
                          const Size(double.infinity, 50), // Make button full-width
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: Colors.blueAccent, // Change button color
                    ),
                    child: const Text(
                      'Submit Audit',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Second Tab: View Report
      ),
    );
  }

  Widget _buildTextFormField(
      {required String label, required Function(String) onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(
          bottom: 16.0), // Bottom spacing for better layout
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), // Rounded corners
            borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0, vertical: 14.0), // Padding inside the field
        ),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}
