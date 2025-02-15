import 'package:eoffice/Screens/Profile_Screens/userprofile_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Import this for SharedPreferences

import '../../Auth/login_screen.dart';

class UserProfileForm extends StatefulWidget {
  const UserProfileForm({super.key});

  @override
  _UserProfileFormState createState() => _UserProfileFormState();
}

class _UserProfileFormState extends State<UserProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();

  String userId = '';
  String state = '';
  String district = '';
  String taluka = '';
  String firstName = '';
  String middleName = '';
  String lastName = '';
  String mobile = '';
  String address = '';
  int totalLeave = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('id') ?? "";
      firstName = prefs.getString('first_name') ?? '';
      lastName = prefs.getString('last_name') ?? '';
      middleName = prefs.getString('middle_name') ?? '';
      mobile = prefs.getString('number') ?? '';
      address = prefs.getString('address') ?? '';
      state = prefs.getString('state') ?? '';
      district = prefs.getString('district') ?? '';
      taluka = prefs.getString('taluka') ?? '';
      totalLeave = prefs.getInt('leaves') ?? 0;
      _contactController.text = mobile;
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.grey[800],
      ),
    );
  }

  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }


  Future<void> edit(String mob) async {
    if (userId == null) {
      _showErrorSnackbar("Invalid User Id");
      return;
    }
    final uri = Uri.parse(
        "https://eofficess.com/api/update-mobile?user_id=$userId&mobile=$mob");

    try {
      String? token = await getAuthToken();
      if (token == null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
        throw Exception('User is not logged in');
      }
      final res = await http.post(uri,
      headers: {
        'Authorization': 'Bearer $token',
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        _showErrorSnackbar("Mobile Number Updated");
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear(); // Clear all preferences to log out
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => UserAppLoginScreen()),
          (Route<dynamic> route) => false,
        );
      }else if(res.statusCode==401){
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
      } else {
        _showErrorSnackbar("Not Updated");
      }
    } catch (e) {
      _showErrorSnackbar("Error Occurred");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('User Profile',
            style: TextStyle(color: Colors.white, fontSize: 20)),
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Color(0xFF4769B2),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Display Form Fields with saved data
              _readOnlyContainer("State: $state"),
              const SizedBox(height: 16),
              _readOnlyContainer("District: $district"),
              const SizedBox(height: 16),
              _readOnlyContainer("Taluka: $taluka"),
              const SizedBox(height: 16),
              _readOnlyContainer("First Name: $firstName"),
              const SizedBox(height: 16),
              _readOnlyContainer("Middle Name: $middleName"),
              const SizedBox(height: 16),
              _readOnlyContainer("Last Name: $lastName"),
              const SizedBox(height: 16),
              _buildTextFormField(_contactController, 'Contact',
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _readOnlyContainer("Address: $address"),
              const SizedBox(height: 16),
              _readOnlyContainer("Total Leaves : ${totalLeave.toString()}"),
              const SizedBox(height: 16),
              // Edit Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    edit(_contactController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0)),
                    textStyle: TextStyle(fontSize: 18),
                    minimumSize: Size(double.infinity, 40),
                    backgroundColor: Color(0xFF4769B2),
                  ),
                  child:
                      const Text('Edit', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _readOnlyContainer(String txt) {
    return Container(
      padding: EdgeInsets.all(10),
      height: 48,
      width: double.infinity,
      child: Text(
        txt,
        style: TextStyle(fontSize: 18),
      ),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String labelText,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey, width: 1.0),
        ),
        suffixIcon: Icon(Icons.edit),
      ),
      keyboardType: keyboardType,
    );
  }
}
