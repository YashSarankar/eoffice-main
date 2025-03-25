import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../Auth/login_screen.dart';
import '../../api_services.dart';
import '../main_screen.dart';

class DocumentUploadScreen extends StatefulWidget {
  final String? bookType;
  final int? currentPage;
  final String? pagePath;

  DocumentUploadScreen({
    Key? key,
    this.bookType,
    this.currentPage,
    this.pagePath,
    required String category,
  }) : super(key: key);

  @override
  _DocumentUploadScreenState createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _documents = []; // List to hold multiple documents
  List<String> _documentTypes = [];
  late TabController _tabController;

  // Fields to store user info from SharedPreferences
  String _state = '';
  String _district = '';
  String _taluka = '';
  List<Map<String, dynamic>> _uploadedDocuments = [];
  bool _isLoading = false;
  ApiService apiService = ApiService();

  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchUploadedDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('id');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found')),
      );
      return;
    }
    final uri = Uri.parse(
        'https://eofficess.com/api/view-user-documents?user_id=$userId');
    try {
      String? token = await getAuthToken();
      if (token == null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
        throw Exception('User is not logged in');
      }
      final response = await http.post(uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _uploadedDocuments = List<Map<String, dynamic>>.from(data['data']);
          });
        }else if(response.statusCode==401){
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'])),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error fetching uploaded documents')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _fetchDocumentList(); // Fetch document types when the screen initializes
    _documents.add({'type': '', 'file': null});

    _tabController.addListener(() {
      if (_tabController.indexIsChanging && _tabController.index == 1) {
        _fetchUploadedDocuments(); // Fetch uploaded documents on tab change
      }
    });
  }

  Future<void> _fetchDocumentList() async {
    try {
      final documentTypes = await apiService.fetchDocumentList(context);
      setState(() {
        _documentTypes = documentTypes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching document list: $e')),
      );
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _state = prefs.getString('state') ?? 'N/A';
      _district = prefs.getString('district') ?? 'N/A';
      _taluka = prefs.getString('taluka') ?? 'N/A';
    });
  }

  Future<void> _pickFile(int index) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _documents[index]['file'] = File(result.files.single.path!);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected')),
      );
    }
  }

  bool _hasValidDocument() {
    return _documents.any((doc) =>
        doc['type'] != null && doc['type']!.isNotEmpty && doc['file'] != null);
  }

  Future<void> _uploadFiles() async {
    if (!_hasValidDocument()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all documents before submitting')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('id');
    final token = await getAuthToken(); // Get the auth token

    if (userId == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID or authentication token not found')),
      );
      setState(() {
        _isLoading = false;
      });
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => UserAppLoginScreen()));
      return;
    }

    var dio = Dio();
    // Add authorization header
    dio.options.headers['Authorization'] = 'Bearer $token';

    print("DOCUMETNS: $_documents");
    List<String> names = [];
    List<File> files = [];
    for (var i in _documents) {
      names.add(i['type']);
      files.add(i['file']);
    }
    print("NAMES: $names");
    print("FILE: $files");

    List<dynamic> multiparts = [];

    for (var i in files) {
      File file = i;
      String fileName = file.path.split('/').last;
      String path = file.path;
      multiparts.add(await MultipartFile.fromFile(
        path,
        filename: fileName,
      ));
    }
    print("MULTI: $multiparts");

    FormData formData = FormData.fromMap({
      "user_id": userId,
      "document-name[]": names,
      "document-upload[]": multiparts
    });

    try {
      var response = await dio.post(
        "https://eofficess.com/api/add-user-document",
        data: formData,
      );
      if (response.statusCode == 201) {
        final responseData = response.data;
        print(responseData);
        if (responseData['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Documents submitted successfully')),
          );
          // clear the documents....
          _documents.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to upload file'),
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to upload file: ${response.statusCode}'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadFile(String? documentName, String? docName) async {
    if (documentName == null || documentName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No document available to download')),
      );
      return;
    }

    final documentUrl = 'https://eofficess.com/images/$documentName';

    // Request storage permissions
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    try {
      final response = await http.get(Uri.parse(documentUrl));

      if (response.statusCode == 200) {
        // Get the directory to save the file
        final directory = await getExternalStorageDirectory();
        final filePath = '${directory!.path}/$documentName';

        // Save the file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File downloaded: $filePath')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download file')),
        );
      }
    } catch (e) {
      print('Error downloading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occurred while downloading the file')),
      );
    }
  }

  Future<void> _downloadAndPreviewFile(
      BuildContext context, String documentName) async {
    if (documentName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No document available to preview')),
      );
      return;
    }

    // Construct the URL for the image
    final String url = 'https://eofficess.com/images/$documentName';

    // Get the temporary directory to save the file
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$documentName';

    try {
      // Download the file
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Save the file to the temporary directory
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Show the image or PDF in an AlertDialog
        _showPreviewDialog(context, filePath);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to Preview document')),
        );
      }
    } catch (e) {
      print('Error downloading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred during file preview')),
      );
    }
  }

  void _showPreviewDialog(BuildContext context, String filePath) {
    // Get the file extension
    final fileExtension = filePath.split('.').last;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Document Preview'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300, // Set a fixed height
            child: fileExtension == 'pdf'
                ? PDFView(filePath: filePath) // PDF display
                : Image.file(File(filePath)), // Image display
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareFile(String? documentName) async {
    if (documentName == null || documentName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No document available to share')),
      );
      return;
    }

    final directory = await getExternalStorageDirectory();
    final filePath = '${directory!.path}/$documentName';
    final file = File(filePath);

    if (await file.exists()) {
      // Create an XFile from the file
      final xFile = XFile(filePath);
      // Share the file using the share_plus package
      await Share.shareXFiles([xFile],
          text: 'Check out this document: $documentName');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('File does not exist, please download it first')),
      );
    }
  }

  dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0, // Remove shadow
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 24, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          },
        ),
        title: const Text(
          'Document Upload',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF4769B2),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF4769B2),
              border: Border(
                bottom: BorderSide(color: Colors.white10, width: 1),
              ),
            ),
            child: TabBar(
              physics: const NeverScrollableScrollPhysics(),
              unselectedLabelColor: Colors.white60,
              labelColor: Colors.white,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              controller: _tabController,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.upload_file, size: 20),
                      SizedBox(width: 8),
                      Text('Upload'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.folder_open, size: 20),
                      SizedBox(width: 8),
                      Text('View'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Document List
                          Column(
                            children: _documents.map((doc) {
                              int index = _documents.indexOf(doc);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Card(
                                  color: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: DropdownButtonFormField<
                                                  String>(
                                                value:
                                                    doc['type']?.isEmpty ?? true
                                                        ? null
                                                        : doc['type'],
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Document Type',
                                                  border: OutlineInputBorder(),
                                                ),
                                                items: _documentTypes
                                                    .map((docType) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: docType,
                                                    child: Text(docType),
                                                  );
                                                }).toList(),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _documents[index]['type'] =
                                                        value ?? '';
                                                  });
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                minimumSize: const Size(40, 40),
                                                backgroundColor:
                                                    const Color(0xFF4769B2),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              onPressed: () => _pickFile(index),
                                              child: const Icon(
                                                  Icons.upload_file,
                                                  color: Colors.white),
                                            ),
                                            if (index > 0)
                                              IconButton(
                                                icon: const Icon(Icons.delete),
                                                color: Colors.red,
                                                onPressed: () {
                                                  setState(() {
                                                    _documents.removeAt(index);
                                                  });
                                                },
                                              ),
                                          ],
                                        ),
                                        if (_documents[index]['file'] != null)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: Text(
                                              'File: ${_documents[index]['file']!.path.split('/').last}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.center,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _documents.add({'type': '', 'file': null});
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4769B2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Add Another Document',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Spacer(),
                    if (_hasValidDocument())
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _uploadFiles,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF4769B2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  )
                                : const Text(
                                    'Upload Documents',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.white),
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
                Column(
                  children: [
                    Expanded(
                      child: _uploadedDocuments.isEmpty
                          ? Center(
                        child: Text(
                          'No documents available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      )
                          : ListView.builder(
                        itemCount: _uploadedDocuments.length,
                        itemBuilder: (context, index) {
                          final document = _uploadedDocuments[index];
                          return ListTile(
                            title: Text(
                              document['doc_name'] ?? 'Untitled',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(document['document'] ?? 'No file'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.download),
                                  onPressed: () => _downloadFile(
                                      document['document'], document['doc_name']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_red_eye),
                                  onPressed: () {
                                    if (document['document'] != null) {
                                      _downloadAndPreviewFile(
                                          context, document['document']);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share),
                                  onPressed: () =>
                                      _shareFile(document['document']),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
}

// user_id   1
// documents[0][name]   pan_card
// documents[0][file]   file
// documents[1][name]   aa_card
// documents[1][file]   file
