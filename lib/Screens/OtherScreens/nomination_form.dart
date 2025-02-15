import 'dart:convert';
import 'package:eoffice/Auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NominationForm extends StatefulWidget {
  @override
  _NominationFormState createState() => _NominationFormState();
}

class _NominationFormState extends State<NominationForm>
    with SingleTickerProviderStateMixin {
  final List<FormData> _forms = [];
  final List<String> _personTypes = ['---', 'Main Nominee', 'Sub Nominee'];
  double _mainPersonTotalPercentage = 0.0;
  double _subPersonTotalPercentage = 0.0;
  List<Map<String, dynamic>> nominationTypes = [];
  String? selectedNominationType;
  bool isDisabled = false;
  TabController? _tabController;

  String? witness1Mobile;
  String? witness2Mobile;
  String? witness1FullName; // New
  String? witness2FullName; // New

  bool isMainNomineeVerified = false;
  bool isWitness1Verified = false;
  bool isWitness2Verified = false;
  String? userId;

  // User data fields controllers
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _joiningDateController = TextEditingController();
  final TextEditingController _userBirthDateController =
      TextEditingController();
  final TextEditingController controller1 = TextEditingController();
  final TextEditingController controller2 = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final _formFieldKey = GlobalKey<FormFieldState>();
  final _formFieldKeyOTP = GlobalKey<FormFieldState>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _addForm(); // Start with one form initially
    _tabController = TabController(length: 3, vsync: this);
    fetchNominationTypes();
    fetchAndSetUserId();
  }

  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }


  Future<void> fetchNominationTypes() async {
  try {
    String? token = await getAuthToken();
    if (token == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
      throw Exception('User is not logged in');
    }
    final response = await http.post(
      Uri.parse('https://eofficess.com/api/get-nomination-type?user_id=121'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success']) {
        setState(() {
          nominationTypes = jsonResponse['data']
              .map<Map<String, dynamic>>((item) => {
                    'type': item['nomination_type'],
                    'status': item['type_status'] as int, // Ensure type is int
                  })
              .toList();
        });
      }
    } else if(response.statusCode==401){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
    }else {
      print('Failed to load nomination types');
    }
  } catch (e) {
    print('Error fetching nomination types: $e');
  }
}

  void fetchAndSetUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('id');
  }

  Future<bool> sendOTP(String mobNo) async {
    if (userId == null) {
      _showErrorSnackbar("Invalid UserId");
    }

    final uri =
        Uri.parse("https://eofficess.com/api/verify-witness-otp?user_id=$userId"
            "&witness_mobile_no=$mobNo");

    try {
      final response = await http.post(uri);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        _showErrorSnackbar("Please check witness number");
        return false;
      }
    } catch (e) {
      _showErrorSnackbar("Error in sending OTP");
      return false;
    }
  }

  Future<bool> validateOTP(String OTP, String mobNo) async {
    final uri = Uri.parse(
        "https://eofficess.com/api/confirm-witness-otp?otp=$OTP&witness_mobile_no=$mobNo");

    try {
      final response = await http.post(uri);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        _showErrorSnackbar("Incorrect OTP");
        return false;
      }
    } catch (e) {
      _showErrorSnackbar("Error occurred while verifying OTP");
      return false;
    }
  }

  List<Map<String, dynamic>> prepareNominees() {
    return _forms.map((form) {
      return {
        "nominee_name": form.nameController.text,
        "nominee_dob": form.birthDateController.text,
        "nominee_age": int.tryParse(form.ageController.text) ?? 0,
        "atypical_event": form.atypicalEventController.text ?? "None",
        "relationship_nominee": form.relationController.text,
        "nominee_type": form.personType,
        "nominee_amount":
            double.tryParse(form.percentageController.text) ?? 0.0,
      };
    }).toList();
  }

// submit (R_S)
  Future<void> submitNomination(
    String dob,
    String joinDate,
    String nominationType,
    String position,
  ) async {
    // Step 1: Validate essential fields
    if (userId == null) {
      _showErrorSnackbar("Invalid UserId");
      return;
    }
    if (witness1Mobile == null || witness2Mobile == null) {
      _showErrorSnackbar("Witness mobile numbers are required");
      return;
    }

    // API endpoint
    final uri = Uri.parse("https://eofficess.com/api/add-nomination");

    // Prepare nominees data (ensure the function prepareNominees is working as expected)
    List<Map<String, dynamic>> nominees = prepareNominees();

    // Build request payload
    Map<String, dynamic> requestBody = {
      "user_id": userId,
      "birth_date": dob,
      "join_date": joinDate,
      "nomination_type": nominationType,
      "position": position,
      "witness_one_mobile": witness1Mobile,
      "witness_two_mobile": witness2Mobile,
      "witness_first_fullname": witness1FullName,
      "witness_second_fullname": witness2FullName,
      "nominees": nominees,
    };

    try {
      // Step 2: Log request details for debugging
      print(
          "Submitting request to $uri with payload: ${jsonEncode(requestBody)}");

      // Send POST request
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      // Step 3: Log response details
      print("Received response with status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      // Step 4: Handle response
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showErrorSnackbar("Form Submitted Successfully");
        Navigator.pop(context);
      } else {
        final responseBody = jsonDecode(response.body);
        final responseMessage = responseBody['message'] ?? "An error occurred";
        _showErrorSnackbar("Error: ${response.statusCode} - $responseMessage");
      }
    } catch (e) {
      // Step 5: Log any exceptions
      print("Exception occurred: $e");
      _showErrorSnackbar("Error occurred while submitting the form: $e");
    }
  }

//ok

  @override
  void dispose() {
    for (var form in _forms) {
      form.dispose();
    }
    _tabController?.dispose();
    super.dispose();
    _positionController.dispose();
    _joiningDateController.dispose();
    _userBirthDateController.dispose();
    controller1.dispose();
    controller2.dispose();
    otpController.dispose();
  }

  void _addForm() {
    if (_mainPersonTotalPercentage == 100 && _subPersonTotalPercentage == 100) {
      _showErrorSnackbar(
          'Cannot add more forms. Total percentage for both Main and Sub Nominee has reached 100%.');
      return;
    }

    setState(() {
      _forms.add(FormData(
        nameController: TextEditingController(),
        birthDateController: TextEditingController(),
        relationController: TextEditingController(),
        ageController: TextEditingController(),
        percentageController: TextEditingController(),
        atypicalEventController: TextEditingController(),
        personType: '---',
      ));
    });
    // Scroll to the newly added form after the state has been updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void _removeForm(int index) {
    setState(() {
      final removedForm = _forms.removeAt(index);
      _updateTotalPercentages();
      removedForm.dispose();
    });
  }

  void _updateTotalPercentages() {
    double mainPersonTotal = 0.0;
    double subPersonTotal = 0.0;

    for (var form in _forms) {
      final percentageText = form.percentageController.text;
      final percentage = double.tryParse(percentageText) ?? 0.0;

      if (form.personType == 'Main Nominee') {
        mainPersonTotal += percentage;
      } else if (form.personType == 'Sub Nominee') {
        subPersonTotal += percentage;
      }
    }

    setState(() {
      _mainPersonTotalPercentage = mainPersonTotal;
      _subPersonTotalPercentage = subPersonTotal;
    });
  }

  void _validateAndSaveForm(FormData form) {
    final percentageText = form.percentageController.text;
    final percentage = double.tryParse(percentageText) ?? 0.0;
    final personType = form.personType;

    if (personType == null) {
      return;
    }

    double currentTotal = personType == 'Main Nominee'
        ? _mainPersonTotalPercentage
        : _subPersonTotalPercentage;

    double newTotal =
        currentTotal - (form.previousPercentage ?? 0.0) + percentage;

    if (newTotal > 100) {
      _showErrorSnackbar(
          'Total percentage for $personType cannot exceed 100%.');
      form.percentageController.text =
          form.previousPercentage?.toString() ?? '';
    } else {
      setState(() {
        form.previousPercentage = percentage;
        _updateTotalPercentages();
      });
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      setState(() {
        controller.text = '${selectedDate.toLocal()}'.split(' ')[0];
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

  void _verifyMainNominee() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Are You Sure?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            "Please confirm if you want to proceed with verifying the main nominee.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isMainNomineeVerified = true;
                      Navigator.pop(context);
                    });
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
                    "Yes",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10), // Space between buttons
                OutlinedButton(
                  onPressed: () {
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
                    "No",
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
          actionsAlignment: MainAxisAlignment.center,
        );
      },
    );
  }


  void _witnessVerification(int witnessNum, TextEditingController txtController) {
  final TextEditingController nameController = TextEditingController();

  // Create unique keys for each TextFormField
  final nameFieldKey = GlobalKey<FormFieldState>();
  final mobileFieldKey = GlobalKey<FormFieldState>();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Rounded corners for the dialog
        ),
        title: const Text(
          "Enter Witness Details",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Full Name Field
            TextFormField(
              key: nameFieldKey, // Unique key for the full name field
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Witness Full Name",
                hintText: "Enter full name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 16.0),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the witness\'s full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Mobile Number Field
            TextFormField(
              key: mobileFieldKey, // Unique key for the mobile field
              controller: txtController,
              decoration: InputDecoration(
                labelText: "Mobile Number",
                hintText: "Enter 10-digit mobile number",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 16.0),
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
        actions: [
          // Verify Button
          ElevatedButton(
            onPressed: () async {
              if (nameFieldKey.currentState!.validate() &&
                  mobileFieldKey.currentState!.validate()) {
                // Save name and mobile number for the current witness
                if (witnessNum == 1) {
                  witness1FullName = nameController.text;
                  witness1Mobile = txtController.text;
                } else {
                  witness2FullName = nameController.text;
                  witness2Mobile = txtController.text;
                }

                // Validate that mobile numbers are not the same
                if ((witnessNum == 1 && witness1Mobile == witness2Mobile) ||
                    (witnessNum == 2 && witness2Mobile == witness1Mobile)) {
                  _showErrorSnackbar(
                      "Mobile number of both witnesses cannot be the same");
                } else {
                  // Attempt to send OTP
                  final isOTPSend = await sendOTP(txtController.text);
                  if (isOTPSend) {
                    Navigator.pop(context);
                    _otpDialog(witnessNum, txtController.text);
                  } else {
                    _showErrorSnackbar("Failed to send OTP. Please try again.");
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Rounded corners for the button
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 20,
              ),
            ),
            child: const Text(
              "Send OTP",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10), // Space between buttons
          // Cancel Button
          OutlinedButton(
            onPressed: () {
              // Clear text controllers when canceling
              txtController.clear();
              nameController.clear();
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Rounded corners for the button
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 20,
              ),
            ),
            child: const Text(
              "Cancel",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.red,
              ),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center, // Center the buttons
      );
    },

  );
}


  void _otpDialog(int witnessNo, String mobNo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Rounded corners for the dialog
          ),
          title: const Text(
            "Enter OTP",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Adjusts the content size to avoid extra space
            children: [
              TextFormField(
                key: _formFieldKeyOTP,
                controller: otpController,
                decoration: InputDecoration(
                  hintText: "Enter 6-digit OTP",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
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
              const SizedBox(height: 10), // Reduced spacing between input and button
            ],
          ),
          actions: [
            // Verify Button
            ElevatedButton(
              onPressed: () async {
                if (_formFieldKeyOTP.currentState!.validate()) {
                  final isVerify = await validateOTP(otpController.text, mobNo);
                  if (isVerify) {
                    otpController.clear();

                    Navigator.pop(context);
                    setState(() {
                      if (witnessNo == 1) {
                        isWitness1Verified = true;
                      } else if (witnessNo == 2) {
                        isWitness2Verified = true;
                      }
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners for the button
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
              ),
              child: const Text(
                "Verify",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center, // Center the buttons
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool disableAddFormButton =
        _mainPersonTotalPercentage == 100 && _subPersonTotalPercentage == 100;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        titleSpacing: 0,
        backgroundColor: const Color(0xFF4769B2),
        title: const Text('Nomination Form',
            style: TextStyle(color: Colors.white, fontSize: 20)),
        // bottom: TabBar(
        //   isScrollable: false,
        //   physics: NeverScrollableScrollPhysics(),
        //   indicatorColor: Colors.white,
        //   indicatorPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        //   unselectedLabelStyle: TextStyle(
        //       fontSize: 16, fontWeight: FontWeight.normal, color: Colors.white),
        //   labelStyle: TextStyle(
        //       fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        //   controller: _tabController,
        //   tabs: [
        //     Tab(text: 'Nominee'),
        //     Tab(text: 'D-Signature'),
        //     // Tab(text: 'Finalize'),
        //   ],
        // ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            children: [
              // First Section: Nominee Details
              Column(
                children: [
                  ListView(
                    controller: _scrollController,
                    shrinkWrap:
                        true, // Allows ListView to wrap around its contents
                    physics:
                        const NeverScrollableScrollPhysics(), // Disable scrolling inside ListView
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextFormField(
                          controller: _positionController,
                          decoration: const InputDecoration(
                            labelText: 'Position',
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextFormField(
                          controller: _joiningDateController,
                          decoration: InputDecoration(
                            labelText: 'Joining Date',
                            border: const OutlineInputBorder(),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () =>
                                  _selectDate(_joiningDateController),
                            ),
                          ),
                          readOnly: true,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextFormField(
                          controller: _userBirthDateController,
                          decoration: InputDecoration(
                            labelText: 'Birth Date',
                            border: const OutlineInputBorder(),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () =>
                                  _selectDate(_userBirthDateController),
                            ),
                          ),
                          readOnly: true,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child:Container(
  decoration: BoxDecoration(
    border: Border.all(color: Colors.grey),
    borderRadius: BorderRadius.circular(8.0),
  ),
  child: nominationTypes.isNotEmpty
      ? DropdownButton<String>(
          hint: Text('Select Nomination Type'),
          underline: SizedBox(),
          isExpanded: true,
          value: selectedNominationType,
          onChanged: (String? newValue) {
            // Allow selection only if `type_status` is 0
            final selectedItem = nominationTypes.firstWhere(
              (type) => type['type'] == newValue,
            );

            if (selectedItem['status'] == 0) {
              setState(() {
                selectedNominationType = newValue;
              });
            }
          },
          items: nominationTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type['type'],
              enabled: type['status'] == 0, // Disable if status == 1
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
                child: Text(
                  type['type'],
                  style: TextStyle(
                    color: type['status'] == 0
                        ? Colors.black
                        : Colors.grey, // Grey out non-selectable items
                  ),
                ),
              ),
            );
          }).toList(),
        )
      : Center(child: CircularProgressIndicator()),
),
                      ),
                      const SizedBox(height: 16.0),
                      Column(
                        children: [
                          for (int i = 0; i < _forms.length; i++)
                            Builder(builder: (context) {
                              final form = _forms[i];
                              final isMainPerson =
                                  form.personType == 'Main Nominee';
                              return Card(
                                color: Colors.grey[50],
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 16.0),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      TextFormField(
                                        controller: form.nameController,
                                        decoration: const InputDecoration(
                                          labelText: 'Nominee Full Name',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 12.0),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16.0),
                                      TextFormField(
                                        controller: form.birthDateController,
                                        decoration: InputDecoration(
                                          labelText: 'Nominee Birth Date',
                                          border: const OutlineInputBorder(),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12.0),
                                          suffixIcon: IconButton(
                                            icon: const Icon(
                                                Icons.calendar_today),
                                            onPressed: () => _selectDate(
                                                form.birthDateController),
                                          ),
                                        ),
                                        readOnly: true,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please select a birth date';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16.0),
                                      TextFormField(
                                        controller: form.relationController,
                                        decoration: const InputDecoration(
                                          labelText: 'Nominee Relation',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 12.0),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter the relation';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16.0),
                                      TextFormField(
                                        controller: form.ageController,
                                        decoration: const InputDecoration(
                                          labelText: 'Nominee Age',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 12.0),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter the age';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16.0),
                                      if (isMainPerson)
                                        TextFormField(
                                          controller:
                                              form.atypicalEventController,
                                          decoration: const InputDecoration(
                                            labelText: 'Atypical Event',
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 12.0),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter an atypical event';
                                            }
                                            return null;
                                          },
                                        ),
                                      if (isMainPerson)
                                        const SizedBox(height: 16.0),
                                      TextFormField(
                                        controller: form.percentageController,
                                        decoration: const InputDecoration(
                                          labelText: 'Nominee Percentage',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 12.0),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) =>
                                            _validateAndSaveForm(form),
                                      ),
                                      const SizedBox(height: 16.0),
                                      DropdownButtonFormField<String>(
                                        value: form.personType,
                                        decoration: const InputDecoration(
                                          labelText: 'Nominee Type',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 12.0),
                                        ),
                                        items: _personTypes
                                            .map((type) =>
                                                DropdownMenuItem<String>(
                                                  value: type,
                                                  child: Text(type),
                                                ))
                                            .toList(),
                                        onChanged:
                                            isDisabled // Disable dropdown if isDisabled is true
                                                ? null
                                                : (value) {
                                                    setState(() {
                                                      form.personType = value;
                                                      _updateTotalPercentages();
                                                    });
                                                  },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please select a nominee type';
                                          }
                                          return null;
                                        },
                                      ),
                                      if (i != 0)
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () => _removeForm(i),
                                            tooltip: 'Remove Nominee',
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            })
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      minimumSize: const Size(double.infinity, 40),
                      backgroundColor: disableAddFormButton
                          ? Colors.grey
                          : const Color(0xFF4769B2),
                    ),
                    onPressed: disableAddFormButton ? null : _addForm,
                    child: const Text('Add Nominee',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Second Section: Upload Documents
              Column(
                children: <Widget>[
                  _verifySignature("Verify Main Nominee Signature",
                      isMainNomineeVerified, _verifyMainNominee),
                  _verifySignature(
                      "Witness Verification Signature 1",
                      isWitness1Verified,
                      () => _witnessVerification(1, controller1)),
                  _verifySignature(
                      "Witness Verification Signature 2",
                      isWitness2Verified,
                      () => _witnessVerification(2, controller2)),

                  // _buildUploadSection(
                  //   'Upload Main Nominee Signature',
                  //   _signatureMainUserPath,
                  //       () => pickImage('mainUser'),
                  // ),
                  // SizedBox(height: 16.0),
                  // _buildUploadSection(
                  //   'Upload Witness Verification Signature 1',
                  //   _signatureExtraVerificationPath1,
                  //       () => pickImage('extraVerification1'),
                  // ),
                  // SizedBox(height: 16.0),
                  // _buildUploadSection(
                  //   'Upload Witness Verification Signature 2',
                  //   _signatureExtraVerificationPath2,
                  //       () => pickImage('extraVerification2'),
                  // ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      minimumSize: const Size(double.infinity, 40),
                      backgroundColor: isWitness2Verified &&
                              isWitness1Verified &&
                              isMainNomineeVerified
                          ? const Color(0xFF4769B2)
                          : Colors.grey,
                    ),
                    onPressed: () {
                      if (isWitness2Verified &&
                          isWitness1Verified &&
                          isMainNomineeVerified) {
                        submitNomination(
                            _userBirthDateController.text,
                            _joiningDateController.text,
                            selectedNominationType!,
                            _positionController.text);
                      }
                    },
                    child: const Text('Submit Form',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _verifySignature(
      String label, bool isVerified, VoidCallback onUpload) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        title: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: ElevatedButton.icon(
          // icon: Icon(
          //   Icons.upload_file,
          //   color: Colors.white,
          // ),
          label: isVerified
              ? const Text(
                  "Verified",
                  style: TextStyle(color: Colors.white),
                )
              : const Text(
                  "Verify",
                  style: TextStyle(color: Colors.white),
                ),
          onPressed: isVerified
              ? () {
                  _showErrorSnackbar("Already Verified");
                }
              : onUpload,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isVerified ? Colors.green : const Color(0xFF4769B2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ),
    );
  }
}

class FormData {
  TextEditingController nameController;
  TextEditingController birthDateController;
  TextEditingController relationController;
  TextEditingController ageController;
  TextEditingController percentageController;
  TextEditingController atypicalEventController;
  String? personType;
  double? previousPercentage;

  FormData({
    required this.nameController,
    required this.birthDateController,
    required this.relationController,
    required this.ageController,
    required this.percentageController,
    required this.atypicalEventController,
    required this.personType,
  });

  void dispose() {
    nameController.dispose();
    birthDateController.dispose();
    relationController.dispose();
    ageController.dispose();
    percentageController.dispose();
    atypicalEventController.dispose();
  }
}
