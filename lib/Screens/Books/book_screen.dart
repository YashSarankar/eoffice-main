import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eoffice/Auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Models/oldbook_model.dart';
import 'add_checklist.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:cross_file/cross_file.dart';
import 'package:pdfx/pdfx.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart' as pdfWidgets;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import 'directory_path.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({
    Key? key,
  }) : super(key: key);

  @override
  _BookScreenState createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PdfViewerController _pgController;
  late PdfViewerController _oldBookController;
  late PdfViewerController _eBookController;
  TextEditingController _searchController = TextEditingController();
  TextEditingController _pageController =
      TextEditingController(); // For page input
  bool isOldBookDownloading = true;
  bool isEBookDownloading = true;

  // String? oldBookPath;
  // String? eBookPath;
  // final String oldBookUrl =
  //     'https://eofficess.com/eofficeManual.pdf';
  // final String eBookUrl = 'https://eofficess.com/eofficeManual.pdf';

  String oldBookUrl = '';

  bool _isSearching = false;
  bool _isLoadingSearch = false;
  Timer? _debounce;
  PdfTextSearchResult? _searchResult;
  bool _isLoading = false;
  String? selectedCategory;
  String? _userId;
  bool _isUserIdLoading = true;
  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    setOldBookUrl();
    _tabController = TabController(length: 2, vsync: this);
    _oldBookController = PdfViewerController();
    _pgController = PdfViewerController();
    _eBookController = PdfViewerController();
    _searchController.addListener(_onSearchChanged);
    _fetchUserId();
    _fetchCategories();
  }

  Future<void> _fetchUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('id'); // Fetch and set the user ID
      _isUserIdLoading = false; // Mark loading as complete
    });
  }

  // Done #####################
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final searchText = _searchController.text;
      if (searchText.isNotEmpty) {
        setState(() {
          //
          _isLoadingSearch = true; // Start loading for search
        });
        _searchText(searchText, _tabController.index == 0);
      } else {
        setState(() {
          _searchResult = null;
          _isLoadingSearch = false; // Stop loading if input is empty
        });
      }
    });
  }

  // Done #####################
  void _searchText(String searchText, bool isOldBook) async {
    setState(() {
      _isLoadingSearch = true; // Start loading for search
    });
    await Future.delayed(Duration(seconds: 1)); // Simulate search delay
    PdfTextSearchResult? result;
    if (isOldBook) {
      result = _oldBookController.searchText(searchText);
    } else {
      result = _eBookController.searchText(searchText);
    }
    setState(() {
      _searchResult = result;
      _searchResult?.addListener(() => setState(() {}));
      _isLoadingSearch = false; // Stop loading after search completes
    });
  }

  // Done #####################
  void _goToPage(String pageText) {
    if (pageText.isNotEmpty) {
      int pageIndex = int.tryParse(pageText) ?? 1;
      if (_tabController.index == 0) {
        _oldBookController.jumpToPage(pageIndex);
      } else {
        _eBookController.jumpToPage(pageIndex);
      }
    }
  }

  // Done #####################
  void _nextPage() {
    if (_tabController.index == 0) {
      _oldBookController.nextPage();
    } else {
      _eBookController.nextPage();
    }
  }

  // Done #####################
  void _previousPage() {
    if (_tabController.index == 0) {
      _oldBookController.previousPage();
    } else {
      _eBookController.previousPage();
    }
  }

  // Done #####################
  void _addToChecklist(int currentPage) async {
    File? pageFile = await downloadSpecificPageAsFile(currentPage);
    if (pageFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChecklistForm(
            bookType: _tabController.index == 0 ? "Old Book" : "eBook",
            currentPage: currentPage,
            pageFile: pageFile,
          ),
        ),
      );
    }
  }


  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchCategories() async {
    try {
      String? token = await getAuthToken();
      if (token == null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
        throw Exception('User is not logged in');
      }
      final response = await http.post(
        Uri.parse('https://eofficess.com/api/document-list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          final List<dynamic> documentList = jsonResponse['data'];
          setState(() {
            categories = documentList
                .map<String>((doc) => doc['doc_name'] as String)
                .toList();
          });
        }else if(response.statusCode==401){
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
        } else {
          throw Exception('Failed to load document list');
        }
      } else {
        throw Exception('Failed to load document list');
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  void _showCategoryDialog(int currentPage) async {
    if (categories.isEmpty) {
      return;
    }
    File? pagePath = await downloadSpecificPageAsFile(currentPage);
    // .then((value) => value?.path);

    if (pagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get the page PDF')),
      );
      return;
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                title: const Text('Select Category'),
                content: Container(
                  width: 400,
                  constraints: BoxConstraints(maxHeight: 500),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: DropdownButton<String>(
                            hint: Text("Select Category"),
                            value: selectedCategory,
                            style: TextStyle(color: Colors.black),
                            underline: SizedBox(),
                            isExpanded: true,
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            items: categories.map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedCategory =
                                    newValue; // Set selected category in dialog state
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 10),
                        Container(
                          height: 300, // Fixed height for the PDF viewer
                          child: SfPdfViewer.file(
                            File(pagePath.path),
                            controller: _pgController,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('Add'),
                    onPressed: () {
                      if (selectedCategory != null) {
                        _uploadSelectedPage(pagePath, selectedCategory!);
                        Navigator.of(context).pop();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please select a category')),
                        );
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  Future<void> _uploadSelectedPage(File page, String category) async {
    if (page == null || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Please select a page and category before submitting')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('id');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ID not found')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    var dio = Dio();
    print("Page: $page");
    File file = page;
    String fileName = file.path.split('/').last;
    String path = file.path;

    FormData formData = FormData.fromMap({
      "user_id": userId,
      "document-name[]": [category],
      "document-upload[]": [
        await MultipartFile.fromFile(
          path,
          filename: fileName,
        ),
      ]
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
            const SnackBar(content: Text('File uploaded successfully')),
          );
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

  // Done #####################
  Future<File?> downloadSpecificPageAsFile(int pageNumber) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final pagePath = '${directory.path}/page_$pageNumber.pdf';
      // Open the original PDF file
      final pdfDocument = await PdfDocument.openFile(bookPath!);
      // Check if the page number is valid
      if (pageNumber < 1 || pageNumber > pdfDocument.pagesCount) {
        print('Invalid page number: $pageNumber');
        return null;
      }

      // Load the specific page
      final page = await pdfDocument.getPage(pageNumber);
      final pageImage = await page.render(
        width: page.width,
        height: page.height,
      );
      // Null check for pageImage.bytes
      if (pageImage?.bytes == null) {
        print("Failed to render the page image.");
        return null;
      }
      final pdf = pw.Document();
      // Convert the page image to a widget and add it to a new PDF document
      pdf.addPage(
        pw.Page(
          build: (context) {
            return pw.Image(
              pw.MemoryImage(pageImage!.bytes),
              // Ensure bytes is non-null using '!'
              fit: pw.BoxFit.contain,
            );
          },
        ),
      );
      // Save the PDF file
      final pdfFile = File(pagePath);
      await pdfFile.writeAsBytes(await pdf.save());
      // Verify the file creation
      if (await pdfFile.exists()) {
        print("File saved successfully at: $pagePath");
        return pdfFile;
      } else {
        print("Failed to save file at: $pagePath");
        return null;
      }
    } catch (e) {
      print('Error downloading the specific page: $e');
      return null;
    }
  }

  void _sharePage(BuildContext context, int currentPage) async {
    File? pdfFile = await downloadSpecificPageAsFile(currentPage);
    if (pdfFile != null && await pdfFile.exists()) {
      try {
        final xFile = XFile(pdfFile.path);
        await Share.shareXFiles([xFile], text: 'Check out this PDF page!');
        print("Sharing PDF at: ${pdfFile.path}"); // Debug print for sharing
      } catch (e) {
        print('Error sharing the file: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share the PDF.')),
        );
      }
    } else {
      print('File does not exist: ${pdfFile?.path}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share the page or file does not exist.'),
        ),
      );
    }
  }

  // Done #####################
// Inside _BookScreenState

//R________________________________________________________________
  void _sharePdf() async {
    String? pdfPath = bookPath;

    if (pdfPath == null || !(await File(pdfPath).exists())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No file available or file does not exist.')),
      );
      return;
    }

    final file = File(pdfPath);

    if (_tabController.index == 0) {
      // Old Book Screen
      // Handle the entire PDF sharing for Old Book screen using the page sharing logic
      final reconstructedPdf = await _generateEntirePdf(file);
      if (reconstructedPdf != null && await reconstructedPdf.exists()) {
        final xFile = XFile(reconstructedPdf.path);
        await Share.shareXFiles([xFile], text: 'Check out this entire PDF!');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate or share the PDF.')),
        );
      }
    } else {
      // For other screens, share the file directly
      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'Check out this PDF!');
    }
  }

// Generate the entire PDF for sharing (reusing existing logic)
  Future<File?> _generateEntirePdf(File originalFile) async {
    try {
      final pdfDocument = await PdfDocument.openFile(originalFile.path);
      // Reconstruct the entire PDF by processing all pages
      final pdf = pw.Document();
      for (int i = 1; i <= pdfDocument.pagesCount; i++) {
        final page = await pdfDocument.getPage(i);
        final renderedPage = await page.render(
          width: page.width,
          height: page.height,
        );
        page.close(); // Release resources for the page

        if (renderedPage?.bytes != null) {
          pdf.addPage(
            pw.Page(
              build: (context) {
                return pw.Image(
                  pw.MemoryImage(renderedPage!.bytes),
                  fit: pw.BoxFit.contain,
                );
              },
            ),
          );
        }
      }

      // Save the reconstructed PDF to a temporary directory
      final outputDir = await getTemporaryDirectory();
      final outputFilePath = '${outputDir.path}/Old_book.pdf';
      final outputFile = File(outputFilePath);
      await outputFile.writeAsBytes(await pdf.save());
      return outputFile;
    } catch (e) {
      print('Error generating entire PDF: $e');
      return null;
    }
  }

//R________________________________________________________________x

  String? bookPath;

  void setFilePath(String path) {
    setState(() {
      bookPath = path;
    });

    print("FILEPATH: $bookPath");
  }

  Future<void> setOldBookUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('id');
    final url =
        Uri.parse("https://eofficess.com/api/getOldBook?user_id=$userId");

    try {
      String? token = await getAuthToken();
      if (token == null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
        throw Exception('User is not logged in');
      }
      final response = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          }
          );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final value = OldBookModel.fromJson(data);
          oldBookUrl = value.data!.oldBook!;
        } else {
          Fluttertoast.showToast(msg: "Error while downloading book");
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error : $e");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _oldBookController.dispose();
    _eBookController.dispose();
    _searchController.dispose();
    _pageController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF4769B2),
        iconTheme: IconThemeData(color: Colors.white),
        title: _isSearching
            ? Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        fillColor: Colors.white,
                        hintText: 'Search in PDF',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.white),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  //use set state to update the search result
                  Text(
                    '${_searchResult?.currentInstanceIndex ?? 0}/${_searchResult?.totalInstanceCount ?? 0}',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  //show total number of search items
                  if (_isLoadingSearch)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    ),
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      _searchResult?.previousInstance();
                    }, // Disable if no previous result
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_forward, color: Colors.white),
                    onPressed: () {
                      _searchResult?.nextInstance();
                    }, // Disaisable if no next result
                  ),
                ],
              )
            : const Text("Book Screen",
                style: TextStyle(color: Colors.white, fontSize: 20)),
        bottom: TabBar(
          physics: NeverScrollableScrollPhysics(),
          unselectedLabelColor: Colors.white,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          indicatorPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 5),
          controller: _tabController,
          tabs: const [
            Tab(text: 'Old Book'),
            Tab(text: 'eBook'),
          ],
        ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          if (_isSearching)
            IconButton(
              icon: Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchResult = null;
                  _searchController.clear();
                });
              },
            ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              int currentPage = _tabController.index == 0
                  ? _oldBookController.pageNumber
                  : _eBookController.pageNumber;

              if (value == 'Add to Checklist') {
                _addToChecklist(currentPage);
              } else if (value == 'Add to Document') {
                _showCategoryDialog(currentPage);
              } else if (value == 'Share PDF') {
                _sharePdf();
              } else if (value == 'Share Page') {
                _sharePage(context, currentPage);
              } else if (value == 'Download PDF') {
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceAround,
                //   children: [
                //     ElevatedButton(
                //       onPressed: () {
                //         // _downloadPdf(oldBookUrl, 'old_book.pdf', isOldBook: true);
                //       },
                //       child: Text('Download Old Book'),
                //     ),
                //     ElevatedButton(
                //       onPressed: () {
                //         // _downloadPdf(eBookUrl, 'e_book.pdf', isOldBook: false);
                //       },
                //       child: Text('Download eBook'),
                //     ),
                //   ],
                // );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'Add to Checklist',
                child: Text('Add to Checklist'),
              ),
              PopupMenuItem(
                value: 'Add to Document',
                child: Text('Add to Document'),
              ),
              PopupMenuItem(
                value: 'Share PDF',
                child: Text('Share Entire PDF'),
              ),
              PopupMenuItem(
                value: 'Share Page',
                child: Text('Share Current Page'),
              ),
              // PopupMenuItem(
              //   value: 'Download PDF',
              //   child: Text('Download PDF'),
              // ),
            ],
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CustomContainer(
            fileUrl: 'https://eofficess.com/images/$oldBookUrl',
            bookController: _oldBookController,
            goToPage: _goToPage,
            nextPage: _nextPage,
            pageController: _pageController,
            previousPage: _previousPage,
            searchResultIndex: _searchResult?.currentInstanceIndex ?? 0,
            //TODO: Fix This searchResult
            searchResults: [],
            callBack: setFilePath,
          ),
          _isUserIdLoading
              ? Center(
                  child:
                      CircularProgressIndicator()) // Show loader while fetching user ID
              : _userId == null || _userId!.isEmpty
                  ? Center(
                      child:
                          Text('User ID not found')) // Handle missing user ID
                  : CustomContainer(
                      fileUrl:
                          'https://eofficess.com/api/generate-merge-pdf/$_userId',
                      bookController: _eBookController,
                      goToPage: _goToPage,
                      nextPage: _nextPage,
                      pageController: _pageController,
                      previousPage: _previousPage,
                      searchResultIndex:
                          _searchResult?.currentInstanceIndex ?? 0,
                      //TODO: Fix this searchResult
                      searchResults: [],
                      callBack: setFilePath,
                    ),
        ],
      ),
    );
  }
}

class SearchResultCard extends StatelessWidget {
  final List<String> searchResults;
  final int currentIndex;
  final VoidCallback onNextPressed;
  final VoidCallback onPreviousPressed;

  const SearchResultCard({
    Key? key,
    required this.searchResults,
    required this.currentIndex,
    required this.onNextPressed,
    required this.onPreviousPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.red[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Search Results (${searchResults.length})',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              searchResults[currentIndex],
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: onPreviousPressed,
                ),
                Text(
                  '${currentIndex + 1}/${searchResults.length}',
                  style: TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: onNextPressed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CustomContainer extends StatefulWidget {
  final String fileUrl;
  final List<String> searchResults;
  late int searchResultIndex;
  final PdfViewerController bookController;
  final TextEditingController pageController;
  final VoidCallback previousPage;
  final ValueChanged<String> goToPage;
  final VoidCallback nextPage;
  final Function callBack;

  CustomContainer({
    super.key,
    required this.fileUrl,
    required this.searchResults,
    required this.searchResultIndex,
    required this.bookController,
    required this.pageController,
    required this.previousPage,
    required this.goToPage,
    required this.nextPage,
    required this.callBack,
  });

  @override
  State<CustomContainer> createState() => _CustomContainerState();
}

class _CustomContainerState extends State<CustomContainer>
    with AutomaticKeepAliveClientMixin {
  bool dowloading = false;
  bool fileExists = false;
  double progress = 0;
  String fileName = "";
  late String filePath;
  late CancelToken cancelToken;
  var getPathFile = DirectoryPath();

  @override
  bool get wantKeepAlive => true; // This keeps the widget's state alive

  // Add method to get downloads directory
  Future<String> getDownloadPath() async {
    if (Platform.isAndroid) {
      // For Android, save to the Downloads directory
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory.path;
    } else {
      // For iOS and other platforms, use the documents directory
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }
  }

  // Add method to request storage permission
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Request notification permission for Android 13+
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
      
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        final result = await Permission.manageExternalStorage.request();
        return result.isGranted;
      }
      return status.isGranted;
    }
    return true;
  }

  // Modify startDownload method
  Future<void> startDownload({bool isLatestDownload = false}) async {
    if (dowloading) return;

    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage permission is required to download files')),
      );
      return;
    }

    cancelToken = CancelToken();
    var downloadPath = await getDownloadPath();
    fileName = 'eoffice book.pdf';
    filePath = '$downloadPath/$fileName';

    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }

    setState(() {
      dowloading = true;
      progress = 0;
    });

    try {
      await Dio().download(
        widget.fileUrl, 
        filePath,
        onReceiveProgress: (count, total) {
          setState(() {
            progress = (count / total);
          });
        },
        cancelToken: cancelToken
      );

      setState(() {
        dowloading = false;
        fileExists = true;
      });

      widget.callBack(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('eoffice book downloaded to Downloads folder'),
          action: SnackBarAction(
            label: 'OPEN',
            onPressed: () async {
              final file = File(filePath);
              if (await file.exists()) {
                OpenFile.open(filePath);
              }
            },
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Download error: $e');
      setState(() {
        dowloading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: ${e.toString()}'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  cancelDownload() {
    cancelToken.cancel();
    setState(() {
      dowloading = false;
    });
  }

  checkFileExit() async {
    var storePath = await getPathFile.getPath();
    filePath = '$storePath/$fileName';
    bool fileExistCheck = await File(filePath).exists();
    setState(() {
      fileExists = fileExistCheck;
    });

    if (fileExists) {
      widget.callBack(filePath); // Ensure this line is present
    }
  }

  // Modify openfile method
  Future<void> openfile() async {
    final file = File(filePath);
    if (await file.exists()) {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${result.message}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File not found')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      fileName = 'eoffice book.pdf';
    });
    print("FILEURL: ${widget.fileUrl}");
    checkFileExit();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Ensure keep-alive is triggered
    return Stack(
      children: [
        // Main content
        fileExists
            ? Column(
                children: [
                  if (widget.searchResults.isNotEmpty)
                    SearchResultCard(
                        searchResults: widget.searchResults,
                        currentIndex: widget.searchResultIndex,
                        onNextPressed: () {
                          setState(() {
                            widget.searchResultIndex++;
                            if (widget.searchResultIndex >=
                                widget.searchResults.length) {
                              widget.searchResultIndex = 0;
                            }
                          });
                        },
                        onPreviousPressed: () {
                          setState(() {
                            widget.searchResultIndex--;
                            if (widget.searchResultIndex < 0) {
                              widget.searchResultIndex =
                                  widget.searchResults.length - 1;
                            }
                          });
                        }),
                  Expanded(
                    child: Center(
                      child: SfPdfViewer.file(
                        File(filePath),
                        controller: widget.bookController,
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back),
                          // onPressed: widget.previousPage,
                          onPressed: () {
                            print(
                                "pageController: ${widget.pageController.text}");
                            widget.previousPage();
                          },
                        ),
                        Container(
                          height: 35,
                          width: 80,
                          child: TextField(
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                            controller: widget.pageController,
                            decoration: const InputDecoration(
                              hintText: "Go to",
                              hintStyle: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onSubmitted: widget.goToPage,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_forward),
                          onPressed: widget.nextPage,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : InkWell(
                onTap: () => fileExists && dowloading == false
                    ? openfile()
                    : startDownload(),
                child: Center(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Download the book for preview"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!fileExists)
                          IconButton(
                              onPressed: () {
                                fileExists && dowloading == false
                                    ? openfile()
                                    : startDownload();
                              },
                              icon: dowloading
                                  ? Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          value: progress,
                                          strokeWidth: 5,
                                          backgroundColor: Colors.grey,
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                  Color>(Colors.blue),
                                        ),
                                        Text(
                                          "${(progress * 100).toStringAsFixed(0)}%",
                                          style: TextStyle(fontSize: 12),
                                        )
                                      ],
                                    )
                                  : const Icon(
                                      Icons.download,
                                      size: 30,
                                    )),
                        if (dowloading)
                          IconButton(
                              onPressed: () {
                                fileExists && dowloading == false
                                    ? openfile()
                                    : cancelDownload();
                              },
                              icon: fileExists && dowloading == false
                                  ? const Icon(
                                      Icons.window,
                                      color: Colors.green,
                                    )
                                  : const Icon(Icons.close)),
                      ],
                    )
                  ],
                )),
              ),

        // Update the positioned download button
        Positioned(
          bottom: 80,
          right: 20,
          child: Visibility(
            visible: fileExists,
            child: GestureDetector(
              onTap: () => startDownload(isLatestDownload: true),
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: dowloading
                    ? SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        Icons.download,
                        size: 30,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
