// import 'dart:convert';
// import 'dart:ffi';
// import 'package:eoffice/Auth/login_screen.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:path/path.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import 'Models/leave_count.dart';
// import 'Models/receipt_by_status.dart';
// import 'Models/receipt_model.dart';
//
// class ApiService {
//   static const String _baseUrl = 'https://eofficess.com/api';
//
//   Future<String?> getAuthToken() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getString('auth_token');
//   }
//
//   static Future<Map<String, dynamic>> login(String mobileNumber) async {
//     final url = Uri.parse(
//         'https://eofficess.com/api/login-via-mobile?mobile=$mobileNumber');
//     final response = await http.post(url);
//
//     if (response.statusCode == 200 || response.statusCode == 201) {
//       final responseData = json.decode(response.body);
//       if (responseData['msg'] == 'OTP sent successfully') {
//         // Return both the message and the OTP
//         return {'msg': responseData['msg'], 'otp': responseData['otp']};
//       } else {
//         throw Exception('Error: ${responseData['msg']}');
//       }
//     } else {
//       throw Exception('Failed to send OTP. Please try again.');
//     }
//   }
//
//   static Future<Map<String, dynamic>> verifyOtp(
//       String mobile, String otp) async {
//     final url = Uri.parse('$_baseUrl/verify-otp?mobile=$mobile&otp=$otp');
//
//     try {
//       final response = await http.post(url);
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final responseData = json.decode(response.body);
//
//         // Save the token to SharedPreferences
//         if (responseData['msg'] == 'OTP verified successfully') {
//           SharedPreferences prefs = await SharedPreferences.getInstance();
//           await prefs.setString('auth_token', responseData['token']);
//           print(responseData['token']);
//           print("This is my token $responseData['token']");
//           return {'status': 'success', 'data': responseData};
//         } else {
//           return {'status': 'error', 'message': 'Failed to verify OTP'};
//         }
//       } else {
//         return {'status': 'error', 'message': 'Failed to verify OTP'};
//       }
//     } catch (error) {
//       return {'status': 'error', 'message': 'An error occurred: $error'};
//     }
//   }
//   Future<void> logout(BuildContext context) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//     await prefs.remove('auth_token'); // Remove the token
//     // Navigate to login screen
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => UserAppLoginScreen()),
//     );
//   }
//
//   Future<void> submitLeaveRequest({
//     required String userId,
//     required DateTime leaveStartDate,
//     required DateTime leaveEndDate,
//     required DateTime leaveAppliedStartDate,
//     required DateTime leaveAppliedEndDate,
//     required String leaveSubject,
//     required String leaveDescription,
//     required String leaveCategory,
//     required String totalLeaveDays,
//     required String isFromTotalLeave,
//     required String state,
//     required String district,
//     required String taluka,
//   }) async {
//     final url = Uri.parse('$_baseUrl/add-leaves');
//
//     try {
//       final response = await http.post(
//         url,
//         headers: <String, String>{
//           'Content-Type': 'application/json; charset=UTF-8',
//         },
//         body: jsonEncode({
//           'user_id': userId,
//           "state": state,
//           "district": district,
//           "taluka": taluka,
//           'leave_category': leaveCategory,
//           'subject': leaveSubject,
//           'description': leaveDescription,
//           'start_date': leaveStartDate.toIso8601String(),
//           'end_date': leaveEndDate.toIso8601String(),
//           "deduct_from_available_leave": isFromTotalLeave,
//           'apply_start_date': leaveAppliedStartDate.toIso8601String(),
//           'apply_end_date': leaveAppliedEndDate.toIso8601String(),
//           'total_leave_days': totalLeaveDays.toString(),
//           // Ensure totalLeaveDays is included
//         }),
//       );
//       print('User ID: $userId');
//       print('Leave Start Date: $leaveStartDate');
//       print('Leave End Date: $leaveEndDate');
//       print('Leave Applied Start Date: $leaveAppliedStartDate');
//       print('Leave Applied End Date: $leaveAppliedEndDate');
//       print('Leave Subject: $leaveSubject');
//       print('Leave Description: $leaveDescription');
//       print('Leave Category: $leaveCategory');
//       print('Total Leave Days: $totalLeaveDays');
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         // Handle successful response if needed
//         print('Leave request submitted successfully');
//       } else {
//         // Handle errors here based on response status code
//         throw Exception('Failed to submit leave request: ${response.body}');
//       }
//     } catch (e) {
//       print('Error occurred: $e');
//       throw Exception('Error occurred while submitting leave request: $e');
//     }
//   }
//
//   Future<Map<String, dynamic>> getReceiptMonthlyCount(String userId) async {
//     final response = await http.post(
//       Uri.parse('https://eofficess.com/api/get-receipt-monthly-count'),
//       body: {
//         'user_id': userId, // Send user_id as a parameter in the body
//       },
//     );
//
//     print('Response Status: ${response.statusCode}');
//     print('Response Body: ${response.body}');
//
//     if (response.statusCode == 200) {
//       // If the server returns a 200 OK response, parse the JSON.
//       return json.decode(response.body);
//     } else {
//       // If the server did not return a 200 OK response, throw an error.
//       throw Exception('Failed to load monthly receipt data');
//     }
//   }

//   Future<List<String>> fetchDocumentList(BuildContext context) async {
//     final String url = '$_baseUrl/document-list';
//
//     try {
//       // Get the token from SharedPreferences
//       String? savedToken = await getAuthToken();
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       print('Token: $token');
//       if (token == null || await checkAndLogoutIfTokenMismatch()|| token != savedToken) {
//         print('My Token is: $token');
//         await logout(context);
//         throw Exception('User is not logged in');
//       }
//
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Authorization': 'Bearer $token',
//           // Include token in the Authorization header
//         },
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final Map<String, dynamic> jsonResponse = json.decode(response.body);
//         if (jsonResponse['success'] == true) {
//           final List<dynamic> documentList = jsonResponse['data'];
//           return documentList
//               .map<String>((doc) => doc['doc_name'] as String)
//               .toList();
//         } else {
//           throw Exception('Failed to load document list');
//         }
//       } else {
//         throw Exception('Failed to load document list');
//       }
//     } catch (e) {
//       // Handle the exception, possibly log the user out if token is invalid or missing
//       print('Error fetching document list: $e');
//       throw Exception('Error fetching document list: $e');
//     }
//   }
//
//   Future<List<String>> fetchChecklistNames() async {
//     final url = Uri.parse('https://eofficess.com/api/get-book-checklist');
//
//     try {
//       // Get the token from SharedPreferences
//       String? savedToken = await getAuthToken();
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       if (token == null || await checkAndLogoutIfTokenMismatch()|| savedToken != token) {
//         print('My Token is: $token');
//         // Token is not available, log the user out
//         throw Exception('User is not logged in');
//       }
//
//       final response = await http.post(
//         url,
//         headers: {
//           'Authorization': 'Bearer $token',
//           // Pass token in the Authorization header
//         },
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final data = json.decode(response.body);
//         if (data['success']) {
//           // Extract checklist names from the response
//           return (data['data'] as List)
//               .map((item) => item['checklist_name'] as String)
//               .toList();
//         } else {
//           throw Exception('Failed to load checklist');
//         }
//       } else {
//         throw Exception('Failed to load checklist');
//       }
//     } catch (e) {
//       // Handle the exception, possibly log the user out if token is invalid or missing
//       throw Exception('Error fetching checklist: $e');
//     }
//   }
//
//   Future<GetReceiptResponse> getReceipt(String userId,BuildContext context) async {
//     var url = Uri.parse('$_baseUrl/get-receipt?user_id=$userId');
//     try {
//       String? savedToken = await getAuthToken();
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       if (token == null || await checkAndLogoutIfTokenMismatch()||savedToken ==token) {
//         print('My Token is: $token');
//
//         //navigate to login screen
//         await logout(context);
//         throw Exception('User is not logged in');
//       }
//
//       final response = await http.post(
//         url,
//         headers: {
//           'Authorization': 'Bearer $token',
//           // Pass token in the Authorization header
//         },
//       );
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return GetReceiptResponse.fromJson(json.decode(response.body));
//       } else {
//         throw Exception('Failed to load receipts');
//       }
//     } catch (e) {
//       throw Exception('Error fetching receipts: $e');
//     }
//   }
//
//   Future<LeaveCountResponse?> getLeaveCount(BuildContext context, int userId) async {
//     final String url = "$_baseUrl/get-leave-count?user_id=$userId";
//
//     try {
//       // Get the token from SharedPreferences
//       String? savedToken = await getAuthToken();
//       print('Saved Token: $savedToken');
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       if (token == null || await checkAndLogoutIfTokenMismatch()|| savedToken != token) {
//         print('My Token is: $token');
//         await logout(context);
//         // Token is not available, log the user out
//         throw Exception('User is not logged in');
//       }
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Authorization': 'Bearer $token',
//           // Include token in the Authorization header
//         },
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final Map<String, dynamic> jsonResponse = json.decode(response.body);
//         return LeaveCountResponse.fromJson(jsonResponse);
//       } else {
//         throw Exception('Failed to load leave count');
//       }
//     } catch (e) {
//       // Handle the exception, possibly log the user out if token is invalid or missing
//       print("Error fetching leave count: $e");
//       return null;
//     }
//   }
//
//   Future<Map<String, dynamic>> getSalary(BuildContext context, int userId) async {
//     final String url = 'https://eofficess.com/api/get-salary?user_id=$userId';
//
//     try {
//       // Get the token from SharedPreferences
//       String? savedToken = await getAuthToken();
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//
//       if (token == null || await checkAndLogoutIfTokenMismatch()|| savedToken != token) {
//         print('My Token is: $token');
//         await logout(context);
//         // Token is not available, log the user out
//         throw Exception('User is not logged in');
//       }
//
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Authorization': 'Bearer $token',
//           // Include token in the Authorization header
//         },
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return json.decode(response.body);
//       } else {
//         throw Exception('Failed to load salary');
//       }
//     } catch (e) {
//       // Handle the exception, possibly log the user out if token is invalid or missing
//       print('Error fetching salary: $e');
//       throw Exception('Error fetching salary: $e');
//     }
//   }
//
//   Future<ReceiptByStatus> fetchReceiptsByStatus(BuildContext context, int userId) async {
//     final String url =
//         'https://eofficess.com/api/getreceiptbystatus?user_id=$userId';
//
//     try {
//       // Get the token from SharedPreferences
//       String? savedToken = await getAuthToken();
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       if (token == null || await checkAndLogoutIfTokenMismatch()|| savedToken != token) {
//         print('My Token is: $token');
//         logout(context);
//         // Token is not available, log the user out
//         throw Exception('User is not logged in');
//       }
//
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Authorization': 'Bearer $token',
//           // Include token in the Authorization header
//         },
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return ReceiptByStatus.fromJson(json.decode(response.body));
//       } else {
//         throw Exception('Failed to load receipts');
//       }
//     } catch (e) {
//       // Handle the exception, possibly log the user out if token is invalid or missing
//       print('Error fetching receipts by status: $e');
//       throw Exception('Error fetching receipts by status: $e');
//     }
//   }
//
//   Future<bool> submitPromotion({
//     required String designation,
//     required String additionalSalary,
//     required String incrementType,
//     required String incrementName,
//     required String description,
//     required String incrementDate,
//     required String salaryCalculationType,
//     required String additionalAmount,
//     String? filePath,
//     String? userSignature,
//   }) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$_baseUrl/add-promotion'),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({
//           'designation': designation,
//           'additional_salary': additionalSalary,
//           'increment_type': incrementType,
//           'increment_name': incrementName,
//           'description': description,
//           'increment_date': incrementDate,
//           'salary_calculation_type': salaryCalculationType,
//           'additional_amount': additionalAmount,
//           'file_path': filePath,
//           'user_signature': userSignature,
//         }),
//       );
//
//       // Check if the response was successful
//       return response.statusCode == 200;
//     } catch (e) {
//       print("Error: $e");
//       return false;
//     }
//   }
// }


import 'dart:convert';
import 'package:eoffice/Auth/login_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'Models/leave_count.dart';
import 'Models/receipt_by_status.dart';
import 'Models/receipt_model.dart';

class ApiService {
  static const String _baseUrl = 'https://eofficess.com/api';

  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> handleUnauthorizedResponse(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear stored token
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => UserAppLoginScreen()), // Redirect to login screen
    );
  }


  static Future<Map<String, dynamic>> login(String mobileNumber) async {
    final url = Uri.parse('https://eofficess.com/api/login-via-mobile?mobile=$mobileNumber');
    final response = await http.post(url);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(response.body);
      if (responseData['msg'] == 'OTP sent successfully') {
        return {'msg': responseData['msg'], 'otp': responseData['otp']};
      } else {
        throw Exception('Error: ${responseData['msg']}');
      }
    } else {
      throw Exception('Failed to send OTP. Please try again.');
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(String mobile, String otp) async {
    final url = Uri.parse('$_baseUrl/verify-otp?mobile=$mobile&otp=$otp');
    try {

      final response = await http.post(url);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        if (responseData['msg'] == 'OTP verified successfully') {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String newToken = responseData['token'];
          await prefs.setString('auth_token', newToken);
          return {'status': 'success', 'data': responseData};
        } else {
          return {'status': 'error', 'message': 'Failed to verify OTP'};
        }
      } else {
        return {'status': 'error', 'message': 'Failed to verify OTP'};
      }
    } catch (error) {
      return {'status': 'error', 'message': 'An error occurred: $error'};
    }
  }

  Future<Map<String, dynamic>> getReceiptMonthlyCount(BuildContext context,String userId) async {
   try{
     String? token = await getAuthToken();
     if (token == null) {
       throw Exception('User is not logged in');
     }
     final response = await http.post(
       Uri.parse('https://eofficess.com/api/get-receipt-monthly-count'),
       headers: {
         'Authorization': 'Bearer $token',
       },
       body: {
         'user_id': userId,
       },
     );

     if (response.statusCode == 200) {
       return json.decode(response.body);
     } else if (response.statusCode == 401) {
       // Token expired or invalid, logout user
       await handleUnauthorizedResponse(context);
       throw Exception('Token expired or invalid');
     }else {
       throw Exception('Failed to load monthly receipt data');
     }
   } catch (e) {
     throw Exception('Failed to load monthly receipt data');
   }
  }


  Future<ReceiptByStatus> fetchReceiptsByStatus(BuildContext context, int userId) async {
    final String url = 'https://eofficess.com/api/getreceiptbystatus?user_id=$userId';

    try {
      String? token = await getAuthToken();
      if (token == null) {
        await handleUnauthorizedResponse(context);
        throw Exception('User is not logged in');
      }

      print('Token: $token');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ReceiptByStatus.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        // Token expired or invalid, logout user
        await handleUnauthorizedResponse(context);
        throw Exception('Token expired or invalid');
      }else {
        throw Exception('Failed to load receipts');
      }
    } catch (e) {
      throw Exception('Error fetching receipts by status: $e');
    }
  }

  Future<void> submitLeaveRequest({
    required BuildContext context,
    required String userId,
    required DateTime leaveStartDate,
    required DateTime leaveEndDate,
    required DateTime leaveAppliedStartDate,
    required DateTime leaveAppliedEndDate,
    required String leaveSubject,
    required String leaveDescription,
    required String leaveCategory,
    required String totalLeaveDays,
    required String isFromTotalLeave,
    required String state,
    required String district,
    required String taluka,
  }) async {
    final url = Uri.parse('$_baseUrl/add-leaves');

    try {
      String? token = await getAuthToken();
      if (token == null ) {
        await handleUnauthorizedResponse(context);
        throw Exception('User is not logged in');
      }

      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
          "state": state,
          "district": district,
          "taluka": taluka,
          'leave_category': leaveCategory,
          'subject': leaveSubject,
          'description': leaveDescription,
          'start_date': leaveStartDate.toIso8601String(),
          'end_date': leaveEndDate.toIso8601String(),
          "deduct_from_available_leave": isFromTotalLeave,
          'apply_start_date': leaveAppliedStartDate.toIso8601String(),
          'apply_end_date': leaveAppliedEndDate.toIso8601String(),
          'total_leave_days': totalLeaveDays.toString(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Leave request submitted successfully');
      }else if (response.statusCode == 401) {
        // Token expired or invalid, logout user
        await handleUnauthorizedResponse(context);
        throw Exception('Token expired or invalid');
      } else {
        throw Exception('Failed to submit leave request: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error occurred while submitting leave request: $e');
    }
  }

  Future<List<String>> fetchDocumentList(BuildContext context) async {
    final String url = '$_baseUrl/document-list';

    try {
      String? token = await getAuthToken();
      if (token == null ) {
        await handleUnauthorizedResponse(context);
        throw Exception('User is not logged in');
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          final List<dynamic> documentList = jsonResponse['data'];
          return documentList.map<String>((doc) => doc['doc_name'] as String).toList();
        }else if (response.statusCode == 401) {
          // Token expired or invalid, logout user
          await handleUnauthorizedResponse(context);
          throw Exception('Token expired or invalid');
        } else {
          throw Exception('Failed to load document list');
        }
      } else {
        throw Exception('Failed to load document list');
      }
    } catch (e) {
      throw Exception('Error fetching document list: $e');
    }
  }

  Future<List<String>> fetchChecklistNames(BuildContext context) async {
    final url = Uri.parse('https://eofficess.com/api/get-book-checklist');

    try {
      String? token = await getAuthToken();
      if (token == null) {
        await handleUnauthorizedResponse(context);
        throw Exception('User is not logged in');
      }

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['data'] as List).map((item) => item['checklist_name'] as String).toList();
        }else if (response.statusCode == 401) {
          // Token expired or invalid, logout user
          await handleUnauthorizedResponse(context);
          throw Exception('Token expired or invalid');
        } else {
          throw Exception('Failed to load checklist');
        }
      } else {
        throw Exception('Failed to load checklist');
      }
    } catch (e) {
      throw Exception('Error fetching checklist: $e');
    }
  }

  Future<GetReceiptResponse> getReceipt(String userId, BuildContext context) async {
    var url = Uri.parse('$_baseUrl/get-receipt?user_id=$userId');
    try {
      String? token = await getAuthToken();
      if (token == null) {
        await handleUnauthorizedResponse(context);
        throw Exception('User is not logged in');
      }

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return GetReceiptResponse.fromJson(json.decode(response.body));
      }else if (response.statusCode == 401) {
        // Token expired or invalid, logout user
        await handleUnauthorizedResponse(context);
        throw Exception('Token expired or invalid');
      } else {
        throw Exception('Failed to load receipts');
      }
    } catch (e) {
      throw Exception('Error fetching receipts: $e');
    }
  }

  Future<LeaveCountResponse?> getLeaveCount(BuildContext context, int userId) async {
    final String url = "$_baseUrl/get-leave-count?user_id=$userId";

    try {
      String? token = await getAuthToken();
      if (token == null) {
        await handleUnauthorizedResponse(context);
        throw Exception('User is not logged in');
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return LeaveCountResponse.fromJson(jsonResponse);
      }else if (response.statusCode == 401) {
        // Token expired or invalid, logout user
        await handleUnauthorizedResponse(context);
        throw Exception('Token expired or invalid');
      } else {
        throw Exception('Failed to load leave count');
      }
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getSalary(BuildContext context, int userId) async {
    final String url = 'https://eofficess.com/api/get-salary?user_id=$userId';

    try {
      String? token = await getAuthToken();
      if (token == null) {
        await handleUnauthorizedResponse(context);
        throw Exception('User is not logged in');
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        // Token expired or invalid, logout user
        await handleUnauthorizedResponse(context);
        throw Exception('Token expired or invalid');
      }else {
        throw Exception('Failed to load salary');
      }
    } catch (e) {
      throw Exception('Error fetching salary: $e');
    }
  }

  Future<bool> submitPromotion({
    required String designation,
    required String additionalSalary,
    required String incrementType,
    required String incrementName,
    required String description,
    required String incrementDate,
    required String salaryCalculationType,
    required String additionalAmount,
    String? filePath,
    String? userSignature,
  }) async {
    try {
      String? token = await getAuthToken();
      if (token == null) {
        throw Exception('User is not logged in');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/add-promotion'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'designation': designation,
          'additional_salary': additionalSalary,
          'increment_type': incrementType,
          'increment_name': incrementName,
          'description': description,
          'increment_date': incrementDate,
          'salary_calculation_type': salaryCalculationType,
          'additional_amount': additionalAmount,
          'file_path': filePath,
          'user_signature': userSignature,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}