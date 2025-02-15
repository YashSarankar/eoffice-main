import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Screens/main_screen.dart';
import '../api_services.dart'; // Import the ApiService
import 'package:intl/intl.dart'; // Import the intl package for date formatting

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String otp;

  OtpScreen({required this.phoneNumber, required this.otp});

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _otp = "";

  Future<void> verifyOtp() async {
    final result = await ApiService.verifyOtp(widget.phoneNumber, _otp);

    // Check the response status to verify if OTP verification was successful
    if (result['status'] == 'success') {
      final responseData = result['data'];

      // Get the stored token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // The token received from the response
      String newToken = responseData['token'] ?? '';

      // Proceed if the token is not empty
      if (newToken.isNotEmpty) {
        // Store the new token
        await prefs.setString('auth_token', newToken);

        // Set user logged in status
        await prefs.setBool('login_status', true);

        // Get and format birth date if available
        String birthDateRaw = responseData['birth_date'] ?? '';
        String formattedBirthDate = birthDateRaw.isNotEmpty
            ? DateFormat('MMMM d, yyyy').format(DateTime.parse(birthDateRaw))
            : '';

        var userResponseData = responseData;
        print(responseData['data']);

        // Store user data in SharedPreferences
        await prefs.setString('id', responseData['data']['id'].toString());
        await prefs.setString('is_admin', userResponseData['data']['is_admin'] ?? '');
        await prefs.setString('joining_start_salary', userResponseData['data']['joining_start_salary'].toString() ?? '');
        await prefs.setString('joining_date', userResponseData['data']['joining_date'].toString() ?? '');
        await prefs.setString('profile_pic', userResponseData['data']['profile_pic'] ?? '');
        await prefs.setString('username', userResponseData['data']['username'] ?? '');
        await prefs.setString('org_id', userResponseData['data']['org_id'].toString());
        await prefs.setString('depart_id', userResponseData['data']['depart_id'].toString());
        await prefs.setString('design_id', userResponseData['data']['design_id'].toString());
        await prefs.setString('first_name', userResponseData['data']['first_name'] ?? '');
        await prefs.setString('middle_name', userResponseData['data']['middle_name'] ?? '');
        await prefs.setString('last_name', userResponseData['data']['last_name'] ?? '');
        await prefs.setString('number', userResponseData['data']['number'].toString() ?? '');
        await prefs.setString('address', userResponseData['data']['address'] ?? '');
        await prefs.setString('state', userResponseData['data']['state'] ?? '');
        await prefs.setString('district', userResponseData['data']['district'] ?? '');
        await prefs.setString('taluka', userResponseData['data']['taluka'] ?? '');
        await prefs.setInt('leaves', responseData['data']['leaves'] ?? 0);
        await prefs.setInt('available_leave', responseData['data']['available_leave'] ?? 0);
        await prefs.setString('old_book', userResponseData['data']['old_book'] ?? '');
        await prefs.setString('email', userResponseData['data']['email'] ?? '');
        await prefs.setString('email_verified_at', userResponseData['data']['email_verified_at'] ?? '');
        await prefs.setBool('login_status', userResponseData['data']['login_status']??false);
        await prefs.setString('caste', userResponseData['data']['caste'] ?? '');
        await prefs.setString('gender', userResponseData['data']['gender'] ?? '');
        await prefs.setString('after_mar_first_name', userResponseData['data']['after_mar_first_name'] ?? '');
        await prefs.setString('after_mar_mid_name', userResponseData['data']['after_mar_mid_name'] ?? '');
        await prefs.setString('after_mar_last_name', userResponseData['data']['after_mar_last_name'] ?? '');
        await prefs.setString('address_B', userResponseData['data']['address_B'] ?? '');
        await prefs.setString('father_name', userResponseData['data']['father_name'] ?? '');
        await prefs.setString('father_address', userResponseData['data']['father_address'] ?? '');
        await prefs.setString('birth_date', userResponseData['data']['birth_date'].toString() ?? '');
        await prefs.setString('birth_text', userResponseData['data']['birth_text'] ?? '');
        await prefs.setString('birth_mark', userResponseData['data']['birth_mark'] ?? '');
        await prefs.setString('height', userResponseData['data']['height'].toString() ?? '');
        await prefs.setString('qualification', userResponseData['data']['qualification'] ?? '');
        await prefs.setString('another_qualification', userResponseData['data']['another_qualification'] ?? '');
        await prefs.setString('digital_sig', userResponseData['data']['digital_sig'] ?? '');
        await prefs.setString('digital_sig_verify', userResponseData['data']['digital_sig_verify'] ?? '');
        await prefs.setString('certificate_no', userResponseData['data']['certificate_no'].toString() ?? '');
        await prefs.setString('post_name', userResponseData['data']['post_name'] ?? '');
        await prefs.setString('role_name', userResponseData['data']['role_name'] ?? '');
        await prefs.setString('owner_id', userResponseData['data']['owner_id'.toString()] ?? '');
        await prefs.setString('status', userResponseData['data']['status'] ?? '');
        await prefs.setString('reject_description', userResponseData['data']['reject_description'] ?? '');
        await prefs.setString('clerk_otp', userResponseData['data']['clerk_otp'].toString());
        await prefs.setString('hod_otp', userResponseData['data']['hod_otp'].toString());
        await prefs.setString('clerk_otp_status', userResponseData['data']['clerk_otp_status'] ?? '');
        await prefs.setString('frwd_hod_id', userResponseData['data']['frwd_hod_id'].toString() ?? '');
        await prefs.setString('hod_otp_status', userResponseData['data']['hod_otp_status'] ?? '');
        await prefs.setString('clerk_verify_staff', userResponseData['data']['clerk_verify_staff'] ?? '');
        await prefs.setString('hod_verify_staff', userResponseData['data']['hod_verify_staff'] ?? '');
        await prefs.setString('user_status', userResponseData['data']['user_status'] ?? '');

        // Navigate to MainScreen after successful OTP verification
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        }
      }
    } else {
      if (mounted) {
        // Show error message if OTP is invalid
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Invalid OTP')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Image.asset(
                  'assets/images/logo.jpg',
                  height: 100,
                ),
                SizedBox(height: 24.0),
                const Text(
                  'Enter Verification Code',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'We have sent a verification code to ${widget.phoneNumber}. Please enter it below to verify.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(height: 24.0),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: PinCodeTextField(
                    appContext: context,
                    length: 6,
                    obscureText: false,
                    animationType: AnimationType.fade,
                    cursorColor: Colors.black,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.underline,
                      borderRadius: BorderRadius.circular(8),
                      fieldHeight: 50,
                      fieldWidth: 40,
                      activeFillColor: Colors.white,
                      inactiveFillColor: Colors.white,
                      selectedFillColor: Colors.white,
                      activeColor: Color(0xFFfcb414),
                      inactiveColor: Colors.grey,
                      selectedColor: Color(0xFFfcb414),
                    ),
                    animationDuration: Duration(milliseconds: 300),
                    backgroundColor: Colors.transparent,
                    enableActiveFill: true,
                    onCompleted: (value) {
                      setState(() {
                        _otp = value;
                      });
                    },
                    onChanged: (value) {
                      setState(() {
                        _otp = value;
                      });
                    },
                    beforeTextPaste: (text) {
                      return true;
                    },
                    keyboardType:
                    TextInputType.number, // Show only numeric keypad
                  ),
                ),
                SizedBox(height: 24.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0)),
                    backgroundColor: Color(0xFF4769B2),
                    minimumSize: Size(double.infinity, 48),
                  ),
                  onPressed: () {
                    if (_otp.length == 6) {
                      verifyOtp();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                            Text('Please enter a valid verification code')),
                      );
                    }
                  },
                  child: Text('Verify Code',
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
