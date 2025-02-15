import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api_services.dart'; // Ensure ApiService is correctly imported
import 'package:http/http.dart' as http;

class LeaveManagementForm extends StatefulWidget {
  @override
  _LeaveManagementFormState createState() => _LeaveManagementFormState();
}

class _LeaveManagementFormState extends State<LeaveManagementForm> {
  final _formKey = GlobalKey<FormState>();

  // Fields
  String? _userId;
  DateTime _leaveStartDate = DateTime.now();
  DateTime _leaveEndDate = DateTime.now();
  DateTime _leaveAppliedStartDate = DateTime.now();
  DateTime _leaveAppliedEndDate = DateTime.now();
  String? _leaveSubject;
  String? _leaveDescription;
  int _totalLeaveDays = 0;
  bool _isFromTotalLeave = false;
  List<String> leaveType = [];
  String? selectedLeaveType;
  String? _district;
  String? _state;
  String? _taluka;

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
    _calculateTotalLeaveDays();
    getLeaveCategory();
  }

  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> getLeaveCategory() async {
    try{
      String? token = await getAuthToken();
      if (token == null) {
        throw Exception('User is not logged in');
      }
      final response = await http.post(
        Uri.parse('https://eofficess.com/api/get-leave-category'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success']) {
          setState(() {
            leaveType = List<String>.from(
                jsonResponse['data'].map((item) => item['leave_type']));
          });
        } else {
          // Handle error
          print('Failed to load leave types');
        }
      }
    }catch(e){
      throw e;
    }
  }

  Future<void> _loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('id').toString();
      _state = prefs.getString('state') ?? 'N/A';
      _district = prefs.getString('district') ?? 'N/A';
      _taluka = prefs.getString('taluka') ?? 'N/A';
    });
  }

  Future<void> _selectDate(BuildContext context, DateTime initialDate,
      Function(DateTime) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != initialDate) {
      onDateSelected(picked);
      _calculateTotalLeaveDays();
    }
  }

  void _calculateTotalLeaveDays() {
    setState(() {
      _totalLeaveDays = _leaveAppliedEndDate.difference(_leaveAppliedStartDate).inDays +
          1; // Including the start date
    });
  }

  Widget _buildDateField(
      String label, DateTime selectedDate, Function(DateTime) onDateChanged) {
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(selectedDate),
    );
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Icon(Icons.calendar_today),
        border: OutlineInputBorder(),
      ),
      controller: dateController,
      onTap: () async {
        await _selectDate(context, selectedDate, (date) {
          setState(() {
            onDateChanged(date);
          });
          dateController.text = DateFormat('yyyy-MM-dd').format(date);
        });
      },
    );
  }

  Widget _buildStaticField(String label, String value) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Text(
        value,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildTotalLeaveDaysField() {
    return _buildStaticField('Total Leave Days', '$_totalLeaveDays days');
  }

  Widget _buildLeaveSourceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Is this leave being deducted from your total available leaves?",
          style: TextStyle(fontSize: 16),
        ),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: Text('Yes'),
                value: true,
                groupValue: _isFromTotalLeave,
                onChanged: (value) {
                  setState(() {
                    _isFromTotalLeave = value!;
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: Text('No'),
                value: false,
                groupValue: _isFromTotalLeave,
                onChanged: (value) {
                  setState(() {
                    _isFromTotalLeave = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Create an instance of ApiService
      final apiService = ApiService();

      // Convert boolean to "yes" or "no"
      String isFromTotalLeave = _isFromTotalLeave ? "yes" : "no";

      // Submit the leave request
      try {
        await apiService.submitLeaveRequest(
          context: context,
          userId: _userId ?? '',
          leaveStartDate: _leaveStartDate,
          leaveEndDate: _leaveEndDate,
          leaveAppliedStartDate: _leaveAppliedStartDate,
          leaveAppliedEndDate: _leaveAppliedEndDate,
          leaveSubject: _leaveSubject ?? '',
          leaveDescription: _leaveDescription ?? '',
          leaveCategory: selectedLeaveType ?? '',
         isFromTotalLeave: isFromTotalLeave,
         district: _district!,
          state: _state!,
          taluka: _taluka!,
          totalLeaveDays: _totalLeaveDays.toString(), // Convert totalLeaveDays to string
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave applied successfully')),
        );

        // Navigate back to the main screen
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context);
        });
      } catch (error) {
        // rethrow;
        // Handle error appropriately
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to apply leave')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4769B2),
        title: const Text('Leave Management',
            style: TextStyle(color: Colors.white, fontSize: 20)),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 16),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                        child: leaveType.isNotEmpty
                            ? Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black54),
                                  // Set your desired border color
                                  borderRadius: BorderRadius.circular(
                                      6), // Set the border radius
                                ),
                                child: DropdownButton(
                                  hint: Text('Select Leave Type'),
                                  underline: SizedBox(),
                                  // Remove the default underline
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 12.0),
                                  isExpanded: true,
                                  // Make the dropdown take the full width
                                  value: selectedLeaveType,
                                  items: leaveType
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem(
                                      value: value,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        // Add some padding to the dropdown items
                                        child: Text(value),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedLeaveType = newValue;
                                    });
                                  },
                                ),
                              )
                            : Center(child: CircularProgressIndicator()),
                      ),
                      // Leave Subject
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Leave Subject',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _leaveSubject = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Leave Description
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Leave Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        // Makes the text field larger for multi-line input
                        onChanged: (value) {
                          setState(() {
                            _leaveDescription = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Leave Start Date
                      _buildDateField('Leave Start Date', _leaveStartDate,
                          (date) {
                        setState(() {
                          _leaveStartDate = date;
                        });
                      }),

                      const SizedBox(height: 16),

                      // Leave End Date
                      _buildDateField('Leave End Date', _leaveEndDate, (date) {
                        setState(() {
                          _leaveEndDate = date;
                        });
                      }),

                      const SizedBox(height: 16),

                      // Leave Applied Start Date
                      _buildDateField(
                          'Leave Applied Start Date', _leaveAppliedStartDate,
                          (date) {
                        setState(() {
                          _leaveAppliedStartDate = date;
                        });
                      }),

                      const SizedBox(height: 16),

                      // Leave Applied End Date
                      _buildDateField(
                          'Leave Applied End Date', _leaveAppliedEndDate,
                          (date) {
                        setState(() {
                          _leaveAppliedEndDate = date;
                        });
                      }),

                      const SizedBox(height: 16),

                      // Total Leave Days
                      _buildTotalLeaveDaysField(),

                      const SizedBox(height: 16),

                      // Leave Source
                      _buildLeaveSourceField(),

                      const SizedBox(height: 16),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4769B2),
                          minimumSize: const Size(double.infinity, 40),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0)),
                        ),
                        child: const Text('Submit Leave Request',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
