import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:eoffice/Auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';

class ReceiptFormScreen extends StatefulWidget {
  const ReceiptFormScreen({super.key});

  @override
  _ReceiptFormScreenState createState() => _ReceiptFormScreenState();
}

class _ReceiptFormScreenState extends State<ReceiptFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _category;
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _currentDate;
  String? _pdfFileName;
  bool _isUploading = false;
  bool _isLoadingCategories = true;
  List<String> _categories = [];
  String? _userId;
  FilePickerResult? _filePickerResult;
  final ImagePicker _picker = ImagePicker();
  List<File> _imageFiles = [];

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _fetchCategories();
    _getUserId();
  }

  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('id');
    });
  }

  Future<void> _fetchCategories() async {
    String? token = await getAuthToken();
    if (token == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
      throw Exception('User is not logged in');
    }

    final url = 'https://eofficess.com/api/get-checklist';

    try {
      final response = await http.post(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      print('API Response for Categories: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true && data['data'] is List) {
          final dataList = data['data'] as List<dynamic>;

          setState(() {
            _categories = dataList
                .map((item) => (item as Map<String, dynamic>)['name'] as String)
                .toList();
            _isLoadingCategories = false;
          });
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (error) {
      print('Error fetching categories: $error');
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? selectedImage =
          await _picker.pickImage(source: ImageSource.gallery);

      if (selectedImage != null) {
        setState(() {
          _imageFiles = [File(selectedImage.path)];
          _pdfFileName = null;
        });

        print('Image selected with size: ${_imageFiles[0].lengthSync()} bytes');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected.')),
        );
        print('No image selected or the user canceled.');
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image')),
      );
    }
  }

  Future<void> _pickPDF() async {
    _filePickerResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (_filePickerResult != null) {
      setState(() {
        _pdfFileName = _filePickerResult!.files.single.name;
        _imageFiles.clear();
        _isUploading = true;
      });

      await Future.delayed(const Duration(seconds: 3));

      setState(() {
        _isUploading = false;
      });
    }
  }
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    final uri = Uri.parse('https://eofficess.com/api/store-receipt');
    final request = http.MultipartRequest('POST', uri);

    // Retrieve the stored token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    // If a token exists, set it in the headers
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    } else {
      // Handle case where token is not available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authorization token not found')),
      );
      setState(() {
        _isUploading = false;
      });
      return;
    }

    // Add fields to the request
    request.fields['user_id'] = _userId!;
    request.fields['category'] = _category ?? '';
    request.fields['subject'] = _subjectController.text;
    request.fields['description'] = _descriptionController.text;

    // Attach file if exists
    if (_pdfFileName != null && _filePickerResult != null) {
      final pdfFile = File(_filePickerResult!.files.single.path!);
      request.files.add(await http.MultipartFile.fromPath(
        'receipt_pdf',
        pdfFile.path,
        filename: _pdfFileName,
      ));
      print('Added PDF file to request: $_pdfFileName');
    } else if (_imageFiles.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'receipt_pdf', // Use 'receipt_pdf' as the field name
          _imageFiles[0].readAsBytesSync(),
          filename: 'image.jpg',
        ),
      );
      print('Added image as receipt_pdf to request');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a PDF or an image to upload.')),
      );
      setState(() {
        _isUploading = false;
      });
      return;
    }

    try {
      final response = await request.send();

      final responseData = await response.stream.bytesToString();
      print('API Response for Receipt Submission: $responseData');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseData) as Map<String, dynamic>;

        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Receipt added successfully!')));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to add receipt: ${data['message']}')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to add receipt: ${response.reasonPhrase}')));
      }
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $error')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }


  // Future<void> _submitForm() async {
  //   if (!_formKey.currentState!.validate()) {
  //     return;
  //   }
  //   if (_userId == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('User ID not found')),
  //     );
  //     return;
  //   }
  //
  //   setState(() {
  //     _isUploading = true;
  //   });
  //
  //   final uri = Uri.parse('https://eofficess.com/api/store-receipt');
  //   final request = http.MultipartRequest('POST', uri,);
  //
  //   request.fields['user_id'] = _userId!;
  //   request.fields['category'] = _category ?? '';
  //   request.fields['subject'] = _subjectController.text;
  //   request.fields['description'] = _descriptionController.text;
  //
  //   if (_pdfFileName != null && _filePickerResult != null) {
  //     final pdfFile = File(_filePickerResult!.files.single.path!);
  //     request.files.add(await http.MultipartFile.fromPath(
  //       'receipt_pdf',
  //       pdfFile.path,
  //       filename: _pdfFileName,
  //     ));
  //     print('Added PDF file to request: $_pdfFileName');
  //   } else if (_imageFiles.isNotEmpty) {
  //     request.files.add(
  //       http.MultipartFile.fromBytes(
  //         'receipt_pdf', // Use 'receipt_pdf' as the field name
  //         _imageFiles[0].readAsBytesSync(),
  //         filename: 'image.jpg',
  //       ),
  //     );
  //     print('Added image as receipt_pdf to request');
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //           content: Text('Please select a PDF or an image to upload.')),
  //     );
  //     setState(() {
  //       _isUploading = false;
  //     });
  //     return;
  //   }
  //
  //   try {
  //     final response = await request.send();
  //
  //     final responseData = await response.stream.bytesToString();
  //     print('API Response for Receipt Submission: $responseData');
  //
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       final data = jsonDecode(responseData) as Map<String, dynamic>;
  //
  //       if (data['success'] == true) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(content: Text('Receipt added successfully!')));
  //         Navigator.pop(context);
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //             content: Text('Failed to add receipt: ${data['message']}')));
  //       }
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //           content: Text('Failed to add receipt: ${response.reasonPhrase}')));
  //     }
  //   } catch (error) {
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(SnackBar(content: Text('Error: $error')));
  //   } finally {
  //     setState(() {
  //       _isUploading = false;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Receipt',
            style: TextStyle(color: Colors.white, fontSize: 20)),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const MainScreen()));
          },
        ),
        backgroundColor: const Color(0xFF4769B2),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 8.0),
                      ),
                      value: _category,
                      items: _categories.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _category = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a subject';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
  onPressed: _pickImage,
  icon: const Icon(Icons.image, color: Colors.white), // Set icon color to white
  label: const Text(
    'Select Image',
    style: TextStyle(color: Colors.white), // Set text color to white
  ),
  style: ElevatedButton.styleFrom(
    minimumSize: const Size(150, 40), // Set minimum size
    backgroundColor: const Color(0xFF4769B2), // Set background color
  ),
),

                  ElevatedButton.icon(
                    onPressed: _pickPDF,
                    icon: const Icon(Icons.picture_as_pdf,color: Colors.white),
                    label: const Text(
                      'Select PDF',
                      style: TextStyle(
                          color: Colors.white), // Set text color to white
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 40), // Set minimum size
                      backgroundColor:
                          const Color(0xFF4769B2), // Set background color
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  backgroundColor: const Color(0xFF4769B2),
                ),
                onPressed: _isUploading ? null : _submitForm,
                child: _isUploading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text(
                        'Submit',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
