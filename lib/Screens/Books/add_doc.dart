import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class AddDoc extends StatefulWidget {
  final List<String> categories;
  final String path;
  const AddDoc({
    super.key,
    required this.categories,
    required this.path,
  });

  @override
  State<AddDoc> createState() => _AddDocState();
}

class _AddDocState extends State<AddDoc> {
  PdfViewerController _pdfController = PdfViewerController();
  String? selectedCategory;

  bool _isLoading = false;

  Future<void> _uploadSelectedPage(String pagePath, String category) async {
    if (pagePath.isEmpty || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a page and category before submitting')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('id');
    final token = prefs.getString('auth_token'); // Retrieve the auth token

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ID not found')),
      );
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
      return;
    }

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authorization token not found')),
      );
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
      return;
    }

    final uri = Uri.parse('https://eofficess.com/api/add-user-document');

    try {
      // Create the multipart request
      var request = http.MultipartRequest('POST', uri)
        ..fields['user_id'] = userId
        ..fields['doc_name'] = category;

      // Set the Authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Ensure the file exists
      final file = File(pagePath);
      if (await file.exists()) {
        print('File exists at: $pagePath');
        // Add the file to the request
        request.files.add(await http.MultipartFile.fromPath('documents[0][file]', file.path));
      } else {
        print('File does not exist at: $pagePath');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File does not exist at the specified path')),
        );
        return;
      }

      // Debugging output to check the request fields and files
      print('Request fields: ${request.fields}');
      print('Request files:');
      for (var f in request.files) {
        print(' - Filename: ${f.filename}, Length: ${f.length} bytes, Path: ${f.field}');
      }

      // Send the request
      final response = await request.send();

      // Read the response body
      final responseBody = await response.stream.bytesToString();

      // Check the response status
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('File uploaded successfully: $responseBody');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File uploaded successfully')),
        );
      } else {
        print('Failed to upload file: ${response.statusCode}, Body: $responseBody');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload file: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred during file upload')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  // Future<void> _uploadSelectedPage(String pagePath, String category) async {
  //   if (pagePath.isEmpty || category.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Please select a page and category before submitting')),
  //     );
  //     return;
  //   }
  //
  //   setState(() {
  //     _isLoading = true; // Show loading indicator
  //   });
  //
  //   final prefs = await SharedPreferences.getInstance();
  //   final userId = prefs.getString('id');
  //
  //   if (userId == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('User ID not found')),
  //     );
  //     setState(() {
  //       _isLoading = false; // Hide loading indicator
  //     });
  //     return;
  //   }
  //
  //   final uri = Uri.parse('https://eofficess.com/api/add-user-document');
  //
  //   try {
  //     // Create the multipart request
  //     var request = http.MultipartRequest('POST', uri,)
  //       ..fields['user_id'] = userId
  //       ..fields['doc_name'] = category;
  //
  //     // Ensure the file exists
  //     final file = File(pagePath);
  //     if (await file.exists()) {
  //       print('File exists at: $pagePath');
  //       // Add the file to the request
  //       request.files.add(await http.MultipartFile.fromPath('documents[0][file]', file.path));
  //     } else {
  //       print('File does not exist at: $pagePath');
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('File does not exist at the specified path')),
  //       );
  //       return;
  //     }
  //
  //     // Debugging output to check the request fields and files
  //     print('Request fields: ${request.fields}');
  //     print('Request files:');
  //     for (var f in request.files) {
  //       print(' - Filename: ${f.filename}, Length: ${f.length} bytes, Path: ${f.field}');
  //     }
  //
  //     // Send the request
  //     final response = await request.send();
  //
  //     // Read the response body
  //     final responseBody = await response.stream.bytesToString();
  //
  //     // Check the response status
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       print('File uploaded successfully: $responseBody');
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('File uploaded successfully')),
  //       );
  //     } else {
  //       print('Failed to upload file: ${response.statusCode}, Body: $responseBody');
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Failed to upload file: ${response.statusCode}'),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     print('Exception: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('An error occurred during file upload')),
  //     );
  //   } finally {
  //     setState(() {
  //       _isLoading = false; // Hide loading indicator
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Add to Document"),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
          backgroundColor: Color(0xFF4769B2),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 10,
            ),
            Container(
              padding: EdgeInsets.all(5),
              margin: EdgeInsets.all(5),
              height: 60,
              width: 220,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              child: DropdownButton<String>(
                hint: Text("Select Category"),
                value: selectedCategory,
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 16),
                underline: SizedBox(),
                isExpanded: true,
                padding: EdgeInsets.symmetric(horizontal: 10),
                items: widget.categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCategory = newValue;
                  });
                },
              ),
            ),
            Expanded(
              child: Center(
                child: SfPdfViewer.file(
                  File(widget.path),
                  controller: _pdfController,
                ),
              ),
            ),
            Container(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    child: Text('Cancel',style: TextStyle(color: Colors.white),),
                    style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4769B2),),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  ElevatedButton(
                    child: Text('Add',style: TextStyle(color: Colors.white),),
                    style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4769B2),),
                    onPressed: () {
                      if (selectedCategory != null) {
                        _uploadSelectedPage(widget.path, selectedCategory!); // Call the upload method
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Document added')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please select a category')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ));
  }
}
