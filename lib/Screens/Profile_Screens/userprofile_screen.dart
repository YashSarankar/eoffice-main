import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Auth/login_screen.dart';
import 'editprofile_screen.dart';

class UserProfileView extends StatefulWidget {
  @override
  _UserProfileViewState createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  String firstName = '';
  String lastName = '';
  String middleName = '';
  String contact = '';
  String address = '';
  String state = '';
  String joiningDate = '';
  String district = '';
  String taluka = '';
  int totalYearlyLeaves = 0;
  String caste = '';
  String addressB = '';
  String fatherName = '';
  String fatherAddress = '';
  String birthDate = '';
  String birthText = '';
  String birthMark = '';
  String height = '';
  String qualification = '';
  String anotherQualification = '';
  String digitalSig = '';
  String digitalSigVerify = '';
  String certificateNo = '';
  String postName = '';
  String createdAt = '';
  String updatedAt = '';
  bool loginStatus = false;
  String email = '';
  String organisation = '';
  String department = '';
  String destination = '';
  String profileImage = '';
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('first_name') ?? '';
      lastName = prefs.getString('last_name') ?? '';
      middleName = prefs.getString('middle_name')?? '';
      contact = prefs.getString('number') ?? '';
      address = prefs.getString('address') ?? '';
      joiningDate = prefs.getString('joining_date') ?? '';
      state = prefs.getString('state') ?? '';
      district = prefs.getString('district') ?? '';
      taluka = prefs.getString('taluka') ?? '';
      totalYearlyLeaves = prefs.getInt('leaves') ?? 0;
      caste = prefs.getString('caste') ?? '';
      addressB = prefs.getString('address_B') ?? '';
      fatherName = prefs.getString('father_name') ?? '';
      fatherAddress = prefs.getString('father_address') ?? '';
      birthDate = prefs.getString('birth_date') ?? 'Not Available';
      birthText = prefs.getString('birth_text') ?? '';
      birthMark = prefs.getString('birth_mark') ?? '';
      height = prefs.getString('height') ?? '';
      qualification = prefs.getString('qualification') ?? '';
      anotherQualification = prefs.getString('another_qualification') ?? '';
      digitalSig = prefs.getString('digital_sig') ?? '';
      digitalSigVerify = prefs.getString('digital_sig_verify') ?? '';
      certificateNo = prefs.getString('certificate_no') ?? '';
      postName = prefs.getString('post_name') ?? '';
      createdAt = prefs.getString('created_at') ?? '';
      updatedAt = prefs.getString('updated_at') ?? '';
      loginStatus = prefs.getBool('login_status') ?? false;
      email = prefs.getString('email')?? '';
      organisation = prefs.getString('org_id') ?? '';
      department = prefs.getString('depart_id') ?? '';
      destination = prefs.getString('design_id') ?? '';
      profileImage = prefs.getString('profile_pic') ?? 'https://eofficess.com/profilephoto/default.jpg';
    });
  }






  @override
  Widget build(BuildContext context) {
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
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontSize: 20)),
        backgroundColor: const Color(0xFF4769B2),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
        child: ListView(
          children: <Widget>[
            // Profile Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Card(
                color: Colors.white,
                // elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blueAccent,
                          image: DecorationImage(
                            image: NetworkImage('https://eofficess.com/profilephoto/$profileImage'), // Use NetworkImage for dynamic URLs
                            fit: BoxFit.cover,
                          ),
                        ),

                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$firstName $middleName $lastName',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              contact,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear(); // Clear all preferences to log out
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const UserAppLoginScreen()),
                                (Route<dynamic> route) => false,
                          );
                        },
                        icon: const Icon(Icons.logout, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Profile Information Card
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // _buildSectionHeader('Personal Information'),
                    _buildProfileInfo('State:', state),
                    _buildProfileInfo('District:', district),
                    _buildProfileInfo('Taluka:', taluka),
                    _buildProfileInfo('Organisation:', organisation.toString()),
                    _buildProfileInfo('Department:', department.toString()),
                    _buildProfileInfo('Designation:', destination.toString()),
                    _buildProfileInfo('Full Name:', '$firstName $middleName $lastName'),
                    _buildProfileInfo('Email:', email ),
                    _buildProfileInfo('Mobile:', contact),
                    _buildProfileInfo('Birth Date:', birthDate),
                    _buildProfileInfo('Birth Text:', birthText),
                    _buildProfileInfo('Location:', address),
                    _buildProfileInfo('Yearly Leaves:', totalYearlyLeaves.toString()),
                    // _buildSectionHeader('Additional Information'),

                    // _buildProfileInfo('Caste:', caste),
                    // _buildProfileInfo('Address B:', addressB),
                    // _buildProfileInfo('Father Name:', fatherName),
                    // _buildProfileInfo('Father Address:', fatherAddress),
                    // _buildProfileInfo('Birth Mark:', birthMark),
                    // _buildProfileInfo('Height:', height),
                    // _buildProfileInfo('Qualification:', qualification),
                    // _buildProfileInfo('Another Qualification:', anotherQualification),
                    // _buildProfileInfo('Digital Signature:', digitalSig),
                    // _buildProfileInfo('Digital Signature Verify:', digitalSigVerify),
                    // _buildProfileInfo('Certificate No:', certificateNo),
                    // _buildProfileInfo('Post Name:', postName),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserProfileForm()),
                  );
                },
                child: const Text('Edit Mobile Number', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), backgroundColor: const Color(0xFF4769B2),
                  textStyle: const TextStyle(fontSize: 18),
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4769B2),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
