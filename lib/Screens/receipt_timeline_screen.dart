import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eoffice/Models/receipt_model.dart';
import 'package:eoffice/Screens/main_screen.dart';
import 'package:eoffice/Screens/receipt_table.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../Models/receipt_by_status.dart';
import '../api_services.dart';
import '../salary_R/services/notification_service.dart';

class ReceiptTimeLineScreen extends StatefulWidget {
  const ReceiptTimeLineScreen({super.key});

  @override
  State<ReceiptTimeLineScreen> createState() => _ReceiptTimeLineScreenState();
}

class _ReceiptTimeLineScreenState extends State<ReceiptTimeLineScreen> {
  int _selectedIndex = 0;

  GetReceiptResponse? getReceiptResponse;
  ReceiptByStatus? _receiptData;
  final ApiService _apiService = ApiService();
  late bool loading;
  String? error;

  Future<void> _fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('id') ?? '0'; // Default to 0 if not found
    print('User ID: $userId');
    final data =
        await _apiService.fetchReceiptsByStatus(context, int.parse(userId));
    if (mounted) {
      setState(
        () {
          _receiptData = data;
        },
      );
    }
  }

  void _navigateToDetailScreen(String status, List<ReceiptTable> receipts) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptDetailScreen(
          status: status,
          receipts: receipts,
        ),
      ),
    );
  }

  Future getReceiptData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('id');
      ApiService apiServices = ApiService();
      getReceiptResponse = await apiServices.getReceipt(userId!, context);
    } catch (e) {
      error = e.toString();
    }
  }

  void initialize() async {
    await getReceiptData();
    await _fetchData();
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Receipts Timeline',
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
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Transaction Summary",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Card 1
                      GestureDetector(
                        onTap: () {
                          _navigateToDetailScreen(
                              'Approved', _receiptData!.approvedReceipts);
                        },
                        child: Card(
                          color: Colors.green[50],
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Column(
                              children: [
                                Text(
                                  "${getReceiptResponse?.approvedReceipts ?? 0}",
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green),
                                ),
                                const Text(
                                  "Approved\nReceipts",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.green, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Card 2
                      GestureDetector(
                        onTap: () {
                          _navigateToDetailScreen(
                              'Pending', _receiptData!.pendingReceipts);
                        },
                        child: Card(
                          color: Colors.yellow[50],
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Column(
                              children: [
                                Text(
                                  "${getReceiptResponse?.pendingReceipts ?? 0}",
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors
                                          .yellow[700] // Change color here
                                      ),
                                ),
                                Text(
                                  "Pending\nReceipts",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.yellow[700], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Card 3
                      GestureDetector(
                        onTap: () {
                          _navigateToDetailScreen(
                              'Rejected', _receiptData!.rejectedReceipts);
                        },
                        child: Card(
                          color: Colors.red[50],
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Column(
                              children: [
                                Text(
                                  "${getReceiptResponse?.rejectedReceipts ?? 0}",
                                  style: const TextStyle(
                                      fontSize: 22,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Text(
                                  "Rejected\nReceipts",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedIndex = 0;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedIndex == 0
                                  ? const Color(0xFF4769B2)
                                  : Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              minimumSize: const Size(150, 40),
                            ),
                            child: Text("Monthly Breakdown",
                                style: _selectedIndex == 0
                                    ? const TextStyle(color: Colors.white)
                                    : const TextStyle(color: Colors.black)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedIndex = 1;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedIndex == 1
                                  ? const Color(0xFF4769B2)
                                  : Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text("Last 10 Receipts",
                                style: _selectedIndex == 1
                                    ? const TextStyle(color: Colors.white)
                                    : const TextStyle(color: Colors.black)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedIndex = 2;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedIndex == 2
                                  ? const Color(0xFF4769B2)
                                  : Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text("All Receipts",
                                style: _selectedIndex == 2
                                    ? const TextStyle(color: Colors.white)
                                    : const TextStyle(color: Colors.black)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_selectedIndex == 0)
                    MonthlyBreakdownWidget(
                      receipts: getReceiptResponse?.receipt ?? [],
                    ),
                  if (_selectedIndex == 1)
                    LastTenReceiptsWidget(
                      receipts: getReceiptResponse?.receipt ?? [],
                    ),
                  if (_selectedIndex == 2)
                    AllReceiptsWidget(
                        receipts: getReceiptResponse?.receipt ?? []),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MonthlyBreakdownWidget extends StatefulWidget {
  final List<Receipt> receipts;

  const MonthlyBreakdownWidget({
    super.key,
    required this.receipts,
  });

  @override
  State<MonthlyBreakdownWidget> createState() => _MonthlyBreakdownWidgetState();
}

class _MonthlyBreakdownWidgetState extends State<MonthlyBreakdownWidget> {
  Map<String, Map<String, int>> monthlyData = {};

  Future<void> _fetchMonthlyData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('id');
      final response =
          await ApiService().getReceiptMonthlyCount(context, userId!);

      if (response['success']) {
        final monthlySummary = response['Monthly_summary'];

        // Map the response data to the monthlyData variable
        monthlySummary.forEach((monthYear, statusCounts) {
          monthlyData[monthYear] = {
            'approved': statusCounts['approved'] ?? 0,
            'pending': statusCounts['pending'] ?? 0,
            'rejected': statusCounts['rejected'] ?? 0,
          };
        });
        setState(() {}); // Trigger UI update after the data is fetched
      }
    } catch (e) {
      // Handle error if needed
      print('Error fetching monthly data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchMonthlyData();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: monthlyData.keys.length,
      itemBuilder: (context, index) {
        final monthYear = monthlyData.keys.elementAt(index);
        final data = monthlyData[monthYear]!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Card(
            color: Colors.white,
            child: ListTile(
              title: Text(
                monthYear,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        'Approved',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 14),
                      ),
                      Text(data['approved'].toString(),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        'Pending',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.yellow[700],
                            fontSize: 14),
                      ),
                      Text(data['pending'].toString(),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        'Rejected',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 14),
                      ),
                      Text(data['rejected'].toString(),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Separate widget for Last 10 Receipts
class LastTenReceiptsWidget extends StatefulWidget {
  final List<Receipt> receipts;

  const LastTenReceiptsWidget({super.key, required this.receipts});

  @override
  _LastTenReceiptsWidgetState createState() => _LastTenReceiptsWidgetState();
}

class _LastTenReceiptsWidgetState extends State<LastTenReceiptsWidget> {
  late List<Receipt> _filteredReceipts;
  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    // Initialize filtered receipts with the latest receipts
    _filteredReceipts = _getLatestReceipts(widget.receipts);
    searchController = TextEditingController();
  }

//________________________________________________________________

  void _showAction(String name, String status, String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Name: $name',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              // Text('Status: $status', style: const TextStyle(fontSize: 14)),
              // const SizedBox(height: 8),
              Text('Id: $id', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),

              // PDF Viewer
              SizedBox(
                height: 300,
                child: SfPdfViewer.network(
                  'https://eofficess.com/api/user-receipt-pdf/$id', // Dynamic URL
                ),
              ),

              // Action Buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () async {
                      // Request permission to write to storage
                      var status = await Permission.storage.request();
                      if (status.isGranted) {
                        final downloadUrl =
                            'https://eofficess.com/api/user-receipt-pdf/$id';
                        await downloadFile(context, downloadUrl, id);
                      } else {
                        // Handle permission denied
                        print("Permission Denied");
                      }
                    },
                    child: const Text('Download',
                        style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: () async {
                      final filePath = await _getFilePath(id);
                      if (filePath != null) {
                        File file = File(filePath);
                        if (await file.exists()) {
                          final xFile = XFile(file.path);
                          await Share.shareXFiles([xFile],
                              text: 'Check out this PDF: $name');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'File not found. Please download it first.')),
                          );
                        }
                      }
                    },
                    child: const Text('Share',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Close", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Future<void> downloadFile(BuildContext context, String url, String id) async {
    try {
      // Define the path to the Downloads directory
      final downloadsDirectory = Directory('/storage/emulated/0/Download');

      // Ensure the directory exists
      if (!downloadsDirectory.existsSync()) {
        downloadsDirectory.createSync(recursive: true);
      }

      // Define the file path
      String savePath = '${downloadsDirectory.path}/$id.pdf';

      // Download the file
      Dio dio = Dio();
      await dio.download(url, savePath);

      // Trigger a notification after successful download
      await NotificationService.showNotification(
        title: 'Download Complete',
        body: 'The file has been successfully downloaded to $savePath.',
      );

      // Show a SnackBar after successful download
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download successful!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.fixed,
        ),
      );

      print("File downloaded to $savePath");
    } catch (e) {
      print("Error downloading file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to download the file.')),
      );
    }
  }

  Future<String?> _getFilePath(String id) async {
    var dir = await getExternalStorageDirectory();
    return '${dir!.path}/$id.pdf';
  }

//________________________________________________________________x

  List<Receipt> _getLatestReceipts(List<Receipt> receipts) {
    // Sort receipts by created_at date in descending order
    final sortedReceipts = receipts
      ..sort(
        (a, b) => DateTime.parse(b.createdAt!).compareTo(
          DateTime.parse(a.createdAt!),
        ),
      );
    return sortedReceipts.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredReceipts.length,
                itemBuilder: (context, index) {
                  final receipt = _filteredReceipts[index];
                  final date = _formatDate(receipt.createdAt!);

                  return Card(
                    color: Colors.white,
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ExpansionTile(
                      clipBehavior: Clip.antiAlias,
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      expandedAlignment: Alignment.topLeft,
                      backgroundColor: Colors.white,
                      collapsedBackgroundColor: Colors.white,
                      minTileHeight: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      title: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getStatusColor(receipt.receiptStatus!),
                            ),
                          ),
                          Text(
                            'Receipt ${receipt.receiptNo}',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Card(
                              color: Colors.grey[200],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 2, vertical: 4),
                                child: Text(
                                  receipt.receiptChecklistId!,
                                  style: const TextStyle(
                                      fontSize: 6, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      children: [
                        // Use SingleChildScrollView to ensure the content is scrollable if necessary
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SingleChildScrollView(
                            // Wrap the content in a SingleChildScrollView
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TimelineTile(
                                  alignment: TimelineAlign.start,
                                  indicatorStyle: const IndicatorStyle(
                                    width: 20,
                                    height: 30,
                                    color: Colors.grey,
                                  ),
                                  endChild: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        date,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildDetailRow(
                                          'Subject:', receipt.subject ?? ""),
                                      const SizedBox(height: 8),
                                      _buildDetailRow('Description:',
                                          receipt.description ?? ""),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                  hasIndicator: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Button to download the receipt
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                // Handle download action
                                _showAction(
                                  receipt.subject ?? 'Unknown',
                                  receipt.receiptStatus ?? 'Unknown',
                                  receipt.id.toString(),
                                );
                              },
                              child: const Text('Download Receipt',
                                  style: TextStyle(color: Color(0xFF4769B2))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateTimeString) {
    final DateTime dateTime = DateTime.parse(dateTimeString);
    final DateFormat formatter =
        DateFormat('yyyy-MM-dd'); // Customize date format here
    return formatter.format(dateTime);
  }

  Widget _buildDetailRow(String title, String detail) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title ',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        Expanded(
          child: Text(
            detail,
            style: const TextStyle(fontSize: 12),
            maxLines: null,
            // Allows the text to wrap to multiple lines if needed
            overflow: TextOverflow.ellipsis, // Prevents overflow with ellipsis
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.yellow;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {
            // Ensure state is updated here
            _filteredReceipts = widget.receipts.where((receipt) {
              final receiptNo = receipt.receiptNo.toString().toLowerCase();
              return receiptNo.contains(value.toLowerCase());
            }).toList();
            // Reapply the latest 10 receipts filter after search
            _filteredReceipts = _getLatestReceipts(_filteredReceipts);
          });
        },
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          // Add clear search functionality
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      searchController.clear();
                      _filteredReceipts = _getLatestReceipts(widget.receipts);
                    });
                  },
                )
              : null,
          labelText: 'Search Receipts',
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class AllReceiptsWidget extends StatefulWidget {
  final List<Receipt> receipts;

  const AllReceiptsWidget({super.key, required this.receipts});

  @override
  _AllReceiptsWidgetState createState() => _AllReceiptsWidgetState();
}

class _AllReceiptsWidgetState extends State<AllReceiptsWidget> {
  late List<Receipt> _filteredReceipts;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _filteredReceipts = widget.receipts;
  }

  void _filterByDate() {
    setState(() {
      if (_startDate != null && _endDate != null) {
        _filteredReceipts = widget.receipts.where((receipt) {
          final DateTime receiptDate = DateTime.parse(receipt.createdAt!);
          return receiptDate.isAfter(_startDate!) &&
              receiptDate.isBefore(_endDate!.add(const Duration(days: 1)));
        }).toList();
      } else {
        _filteredReceipts = widget.receipts;
      }
    });
  }

//________________________________________________________________
  void _showAction(String name, String status, String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Name: $name',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              // Text('Status: $status', style: const TextStyle(fontSize: 14)),
              // const SizedBox(height: 8),
              Text('Id: $id', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),

              // PDF Viewer
              SizedBox(
                height: 300,
                child: SfPdfViewer.network(
                  'https://eofficess.com/api/user-receipt-pdf/$id', // Dynamic URL
                ),
              ),

              // Action Buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () async {
                      // Request permission to write to storage
                      var status = await Permission.storage.request();
                      if (status.isGranted) {
                        final downloadUrl =
                            'https://eofficess.com/api/user-receipt-pdf/$id';
                        await downloadFile(context, downloadUrl, id);
                      } else {
                        // Handle permission denied
                        print("Permission Denied");
                      }
                    },
                    child: const Text('Download',
                        style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: () async {
                      final filePath = await _getFilePath(id);
                      if (filePath != null) {
                        File file = File(filePath);
                        if (await file.exists()) {
                          final xFile = XFile(file.path);
                          await Share.shareXFiles([xFile],
                              text: 'Check out this PDF: $name');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'File not found. Please download it first.')),
                          );
                        }
                      }
                    },
                    child: const Text('Share',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Close", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Future<void> downloadFile(BuildContext context, String url, String id) async {
    try {
      // Define the path to the Downloads directory
      final downloadsDirectory = Directory('/storage/emulated/0/Download');

      // Ensure the directory exists
      if (!downloadsDirectory.existsSync()) {
        downloadsDirectory.createSync(recursive: true);
      }

      // Define the file path
      String savePath = '${downloadsDirectory.path}/$id.pdf';

      // Download the file
      Dio dio = Dio();
      await dio.download(url, savePath);

      // Trigger a notification after successful download
      await NotificationService.showNotification(
        title: 'Download Complete',
        body: 'The file has been successfully downloaded to $savePath.',
      );

      // Show a SnackBar after successful download
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download successful!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.fixed,
        ),
      );

      print("File downloaded to $savePath");
    } catch (e) {
      print("Error downloading file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to download the file.')),
      );
    }
  }

  Future<String?> _getFilePath(String id) async {
    var dir = await getExternalStorageDirectory();
    return '${dir!.path}/$id.pdf';
  }

//________________________________________________________________x

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = selectedDate;
        } else {
          _endDate = selectedDate;
        }
        _filterByDate();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      clipBehavior: Clip.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: _startDate == null
                          ? Colors.grey[300]
                          : const Color(0xFF4769B2),
                    ),
                    onPressed: () => _selectDate(context, true),
                    child: Text(
                      style: TextStyle(
                          color:
                              _startDate == null ? Colors.black : Colors.white),
                      _startDate == null
                          ? 'Start Date'
                          : 'Start Date: ${DateFormat('yyyy-MM-dd').format(_startDate!)}',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: _endDate == null
                          ? Colors.grey[300]
                          : const Color(0xFF4769B2),
                    ),
                    onPressed: () => _selectDate(context, false),
                    child: Text(
                      style: TextStyle(
                          color:
                              _endDate == null ? Colors.black : Colors.white),
                      _endDate == null
                          ? 'End Date'
                          : 'End Date: ${DateFormat('yyyy-MM-dd').format(_endDate!)}',
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                // Disable scrolling here
                itemCount: _filteredReceipts.length,
                itemBuilder: (context, index) {
                  final receipt = _filteredReceipts[index];
                  final date = _formatDate(receipt.createdAt!);

                  return Card(
                    color: Colors.white,
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ExpansionTile(
                      clipBehavior: Clip.antiAlias,
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      expandedAlignment: Alignment.topLeft,
                      backgroundColor: Colors.white,
                      collapsedBackgroundColor: Colors.white,
                      minTileHeight: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      title: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getStatusColor(receipt.receiptStatus!),
                            ),
                          ),
                          Text(
                            'Receipt ${receipt.receiptNo}',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Card(
                              color: Colors.grey[200],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                  vertical: 4,
                                ),
                                child: Text(
                                  receipt.receiptChecklistId!,
                                  style: const TextStyle(
                                      fontSize: 6, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TimelineTile(
                                alignment: TimelineAlign.start,
                                indicatorStyle: const IndicatorStyle(
                                  width: 20,
                                  height: 30,
                                  color: Colors.grey,
                                ),
                                endChild: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      date,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDetailRow(
                                        'Subject:', receipt.subject!),
                                    const SizedBox(height: 8),
                                    _buildDetailRow(
                                        'Description:', receipt.description!),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                                hasIndicator: true,
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                // Handle download action
                                _showAction(
                                  receipt.subject ?? 'Unknown',
                                  receipt.receiptStatus ?? 'Unknown',
                                  receipt.id.toString(),
                                );
                              },
                              child: const Text('Download Receipt',
                                  style: TextStyle(color: Color(0xFF4769B2))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateTimeString) {
    final DateTime dateTime = DateTime.parse(dateTimeString);
    final DateFormat formatter =
        DateFormat('yyyy-MM-dd'); // Customize date format here
    return formatter.format(dateTime);
  }

  Widget _buildDetailRow(String title, String detail) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(detail),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.yellow;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
