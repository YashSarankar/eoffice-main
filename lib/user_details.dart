// import 'dart:io';
// import 'package:eoffice/salary_R/services/notification_service.dart';
// import 'package:flutter/material.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// import 'package:dio/dio.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter/material.dart';
//
// class UserDetailView extends StatefulWidget {
//   @override
//   _UserDetailViewState createState() => _UserDetailViewState();
// }
//
// class _UserDetailViewState extends State<UserDetailView> {
//   String? _userId; // For dynamic user ID
//   String? _pdfUrl; // For API-generated PDF URL
//   bool _isLoading = true; // For loading state
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchUserId();
//   }
//
//   // Fetch user ID from SharedPreferences and construct the API URL
//   Future<void> _fetchUserId() async {
//     final prefs = await SharedPreferences.getInstance();
//     final userId = prefs.getString('id');
//
//     if (userId != null && userId.isNotEmpty) {
//       setState(() {
//         _userId = userId;
//         _pdfUrl = 'https://eofficess.com/api/user-details/$userId/pdf';
//         _isLoading = false;
//       });
//     } else {
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('User ID not found')),
//       );
//     }
//   }
//
//   // Download the PDF and save it to the device
//   Future<void> _downloadPdf() async {
//     if (_pdfUrl == null) return;
//
//     try {
//       // Request storage permission
//       var status = await Permission.storage.request();
//
//       if (status.isDenied) {
//         // Check if the widget is still mounted before showing the SnackBar
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Storage permission is required to download files'),
//             ),
//           );
//         }
//         return;
//       }
//
//       if (status.isPermanentlyDenied) {
//         // Check if the widget is still mounted before opening app settings
//         if (mounted) {
//           openAppSettings();
//         }
//         return;
//       }
//
//       // Check if we are dealing with Android 11 or higher, and request additional permissions if needed
//       if (Platform.isAndroid && await Permission.manageExternalStorage.isDenied) {
//         var managePermissionStatus = await Permission.manageExternalStorage.request();
//         if (!managePermissionStatus.isGranted) {
//           // Check if the widget is still mounted before showing the SnackBar
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Please allow storage access in settings')),
//             );
//           }
//           return;
//         }
//       }
//
//       // Get the directory where you want to save the file
//       final directory = await getExternalStorageDirectory();
//       if (directory == null) {
//         // Check if the widget is still mounted before showing the SnackBar
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Failed to get directory')),
//           );
//         }
//         return;
//       }
//
//       final filePath = '${directory.path}/user_details.pdf';
//
//       // Download the file using Dio
//       await Dio().download(_pdfUrl!, filePath);
//
//       // Check if the widget is still mounted before showing the SnackBar
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Download successful!'),
//             backgroundColor: Colors.green,
//             behavior: SnackBarBehavior.fixed,
//           ),
//         );
//       }
//
//       // Trigger a notification after successful download
//       await NotificationService.showNotification(
//         title: 'Download Complete',
//         body: 'Your PDF has been downloaded to $filePath.',
//       );
//
//       // Open the file after download
//       OpenFile.open(filePath);
//     } catch (e) {
//       // Check if the widget is still mounted before showing the SnackBar
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to download PDF: $e')),
//         );
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//         titleSpacing: 0,
//         title: const Text('User Details',
//             style: TextStyle(color: Colors.white, fontSize: 20)),
//         backgroundColor: const Color(0xFF4769B2),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _pdfUrl == null
//               ? const Center(child: Text('Unable to fetch user details'))
//               : Column(
//                   children: [
//                     // PDF Viewer in center
//                     Expanded(
//                       child: SfPdfViewer.network(_pdfUrl!),
//                     ),
//
//                     // Download Button
//                     Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: ElevatedButton(
//                         onPressed: _downloadPdf, // Logic for downloading PDF
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF4769B2),
//                           minimumSize: const Size(double.infinity, 40),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                         child: const Text(
//                           "Download Data",
//                           style: TextStyle(fontSize: 16, color: Colors.white),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//     );
//   }
// }
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class UserDetailView extends StatefulWidget {
  @override
  _UserDetailViewState createState() => _UserDetailViewState();
}

class _UserDetailViewState extends State<UserDetailView> {
  String? _userId; // For dynamic user ID
  String? _pdfUrl; // For API-generated PDF URL
  bool _isLoading = true; // For loading state
  double _progress = 0.0; // Track download progress
  bool _isDownloading = false; // Whether a download is in progress

  @override
  void initState() {
    super.initState();
    _fetchUserId();
  }

  // Fetch user ID from SharedPreferences and construct the API URL
  Future<void> _fetchUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('id');

    if (userId != null && userId.isNotEmpty) {
      setState(() {
        _userId = userId;
        _pdfUrl = 'https://eofficess.com/api/user-details/$userId/pdf';
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID not found')),
        );
      }
    }
  }

  // Download the PDF to the app's private storage and open it
  Future<void> _downloadPdf() async {
    if (_pdfUrl == null) return;

    try {
      setState(() {
        _isDownloading = true; // Start the download
        _progress = 0.0; // Reset progress
      });

      // Request permissions for iOS (Android will be handled separately in sandbox)
      await _requestStoragePermission();

      // Get the app's document directory (sandboxed storage)
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/user_details.pdf';

      // Download the file using Dio with a progress callback
      await Dio().download(
        _pdfUrl!,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              // Debugging log to see if the callback is triggered
              print("Progress: received=$received, total=$total");
              _progress = (received / total) * 100;
            });
          }
        },
      );

      if (mounted) {
        // Show success message after download
        Future.delayed(Duration.zero, () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Download successful!'),
                  backgroundColor: Colors.green),
            );
          }
        });
      }

      // Open the downloaded PDF file from the app's sandboxed storage
      OpenFile.open(filePath);

      setState(() {
        _isDownloading = false; // Stop the download indicator
      });
    } catch (e) {
      if (mounted) {
        // Handle download failure
        Future.delayed(Duration.zero, () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to download PDF: $e')),
            );
          }
        });
      }

      setState(() {
        _isDownloading = false; // Stop the download indicator
      });
    }
  }

  // Request storage permission for iOS (Android will be handled separately in sandbox storage)
  Future<void> _requestStoragePermission() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Storage permission is required to download files')),
          );
        }
        return;
      }
    }
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
        title: const Text('User Details',
            style: TextStyle(color: Colors.white, fontSize: 20)),
        backgroundColor: const Color(0xFF4769B2),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Show loading indicator
          : _pdfUrl == null
              ? const Center(child: Text('Unable to fetch user details'))
              : Column(
                  children: [
                    // PDF Viewer in center
                    Expanded(
                      child: SfPdfViewer.network(_pdfUrl!),
                    ),
                    // Download Button
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: _isDownloading ? null : _downloadPdf,
                        // Disable button during download
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4769B2),
                          minimumSize: const Size(double.infinity, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isDownloading
                            ? const CircularProgressIndicator(
                                color: Colors
                                    .white) // Show spinner while downloading
                            : const Text(
                                "Download Data",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                      ),
                    ),
                    // Download Progress Bar
                    if (_isDownloading)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            LinearProgressIndicator(
                              value: _progress /
                                  100, // Value as a percentage (0 to 1)
                              color: Colors.blue,
                              backgroundColor: Colors.grey[200],
                            ),
                            const SizedBox(height: 10),
                            Text('${_progress.toStringAsFixed(0)}%'),
                            // Display the percentage
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}
