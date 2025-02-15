import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:eoffice/Auth/login_screen.dart';
import 'package:eoffice/Models/receipt_model.dart';
import 'package:eoffice/Screens/Profile_Screens/userprofile_screen.dart';
import 'package:eoffice/Screens/receipt_table.dart';
import 'package:eoffice/salary_R/models/slap_amount.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Models/receipt_by_status.dart';
import '../api_services.dart';
import '../salary_R/services/salary_data_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<bool> isSelected = [true, false, false];
  int selectedIndex = 0;
  String firstName = '';
  String lastName = '';
  String _formattedDate = '';

  GetReceiptResponse? getReceiptResponse;
  late bool loading;
  String? error;

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
    setState(() {
      loading = true;
    });
    await getReceiptData();
    setState(() {
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    loading = false;
    initialize();
    _loadUserData();
    _setDate();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('first_name') ?? '';
      lastName = prefs.getString('last_name') ?? '';
    });
  }

  void updateData(int index) {
    setState(() {
      for (int i = 0; i < isSelected.length; i++) {
        isSelected[i] = i == index;
      }
      selectedIndex = index;
    });
  }

  Widget getSelectedWidget() {
    switch (selectedIndex) {
      case 0:
        return Widget1(); // First widget
      case 1:
        return Widget2(); // Second widget
      case 2:
        return Widget3(
          receipts: getReceiptResponse?.receipt ?? [],
        ); // Third widget
      default:
        return Widget1(); // Default to Widget1
    }
  }

  final List<Map<String, dynamic>> statusUpdates = [
    {
      'status': 'Leave Request Approved',
      'date': '2024-08-30',
      'image': 'assets/images/mark.jpg', // Store path as string
    },
    {
      'status': 'Salary Processed',
      'date': '2024-08-29',
      'image': 'assets/images/salary.jpg', // Store path as string
    },
    {
      'status': 'Leave Request Rejected',
      'date': '2024-08-28',
      'image': 'assets/images/rejected.jpg', // Store path as string
    },
    // Add more status updates as needed
  ];

  void _setDate() {
    // Get the current date
    DateTime now = DateTime.now();
    // Format the day to show only the first three letters (Mon, Tue, etc.)
    String day = DateFormat('E').format(now);
    // Format the date as per your need (e.g., 21-Sep-2024)
    String date = DateFormat('dd MMM yyyy').format(now);
    // Set the formatted date
    setState(() {
      _formattedDate = '$day, $date';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF4769B2),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: Container(
            color: Colors.grey[300],
            height: 1,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserProfileView()),
                );
              },
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Color(0xFF4769B2)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $firstName $lastName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _formattedDate,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: const [
          // IconButton(
          //   onPressed: () {
          //     Navigator.pushNamed(context, '/notification');
          //   },
          //   icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
          // ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Carousel Slider for Latest Statuses
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 100, // Height of the carousel items
                  autoPlay: true,
                  viewportFraction: 1.0, // Ensure items take full width
                  enlargeCenterPage: true, // Slightly enlarge the centered page
                ),
                items: statusUpdates.map((update) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Image.asset(
                            update['image'], // Use image path as string
                            width: 40,
                            height: 40,
                          ),
                          title: Text(
                            update['status'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            'Date: ${update['date']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          tileColor: Colors.white,
                          // Uniform background color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: Colors.grey[
                                    300]! // Add a light border for definition
                                ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10), // Add some spacing at the top
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (index) {
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: selectedIndex == index
                                ? Colors.white
                                : Colors.black,
                            backgroundColor: selectedIndex == index
                                ? const Color(0xFF4769B2)
                                : Colors.grey[300],
                            // Text color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize:
                                const Size(30, 40), // Adjust width as needed
                          ),
                          onPressed: () => updateData(index),
                          child: Text(
                            index == 0
                                ? 'Leaves'
                                : index == 1
                                    ? 'Salary'
                                    : 'Receipt',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(
                      height: 10), // Spacing between buttons and content
                  Expanded(
                    child: getSelectedWidget(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Widget1 extends StatefulWidget {
  @override
  _Widget1State createState() => _Widget1State();
}

class _Widget1State extends State<Widget1> with SingleTickerProviderStateMixin {
  List<ChartSampleData> chartData = [];
  late AnimationController _controller;
  Animation<double>? _approvedAnimation;
  Animation<double>? _pendingAnimation;
  Animation<double>? _rejectedAnimation;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    fetchData();
  }

  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> fetchData() async {
    try {
      String? token = await getAuthToken();
      if (token == null) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => UserAppLoginScreen()));
        throw Exception('User is not logged in');
      }
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String userId = prefs.getString('id') ?? '';

      final response = await http.post(
        Uri.parse('https://eofficess.com/api/get-leave-count?user_id=$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success']) {
          final data = jsonResponse['data'];
          chartData = data.entries.map<ChartSampleData>((entry) {
            final monthYear = entry.key;
            final month = DateFormat('MMMM').format(DateTime(
                int.parse(monthYear.split('-')[1]),
                int.parse(monthYear.split('-')[0])));
            final values = entry.value;
            return ChartSampleData(
              x: month,
              approved: values['Approved'] ?? 0.0,
              pending: values['Pending'] ?? 0.0,
              rejected: values['Rejected'] ?? 0.0,
            );
          }).toList();
        }
      }else if(response.statusCode==401){
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));

      } else {
        throw Exception(
          'Failed to load data: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Error occurred: $e');
    } finally {
      setState(() {
        isLoading = false; // Stop loading data
        _initializeAnimations(); // Initialize animations here
      });
    }
  }

  void _initializeAnimations() {
    if (chartData.isNotEmpty) {
      // Calculate totals
      final totalApproved =
          chartData.map((data) => data.approved).reduce((a, b) => a + b);
      final totalPending =
          chartData.map((data) => data.pending).reduce((a, b) => a + b);
      final totalRejected =
          chartData.map((data) => data.rejected).reduce((a, b) => a + b);
      final total = totalApproved + totalPending + totalRejected;

      // Calculate percentages
      final double approvedPercentage = total > 0 ? totalApproved / total : 0;
      final double pendingPercentage = total > 0 ? totalPending / total : 0;
      final double rejectedPercentage = total > 0 ? totalRejected / total : 0;

      // Animate percentages
      _approvedAnimation = Tween<double>(begin: 0, end: approvedPercentage)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
      _pendingAnimation = Tween<double>(begin: 0, end: pendingPercentage)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
      _rejectedAnimation = Tween<double>(begin: 0, end: rejectedPercentage)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

      _controller.forward(); // Start the animation
    }
  }

  @override
  void dispose() {
    // _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Leave Statistics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAnimatedCircularIndicator(
                  'Approved', Colors.green, _approvedAnimation),
              _buildAnimatedCircularIndicator(
                  'Pending', Colors.blue, _pendingAnimation),
              _buildAnimatedCircularIndicator(
                  'Rejected', Colors.red, _rejectedAnimation),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 50, top: 10),
            child: BarChart(
              BarChartData(
                barGroups: barChartGroups(chartData),
                // Use static bar chart data
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 10,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < chartData.length) {
                          return SideTitleWidget(
                            meta: meta,
                            child: Center(
                              child: chartData[index].approved == 0.0 &&
                                      chartData[index].pending == 0.0 &&
                                      chartData[index].rejected == 0.0
                                  ? null
                                  : Text(
                                      chartData[index]
                                          .x, // Use the month name from x
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                            ),
                          );
                        } else {
                          return const SizedBox();
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: true),
              ),
              swapAnimationDuration: const Duration(seconds: 0),
            ),
          ),
        ),
        // const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAnimatedCircularIndicator(
      String title, Color color, Animation<double>? animation) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80, // Size of the circular indicator
              height: 80,
              child: animation != null
                  ? AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return CircularProgressIndicator(
                          value: animation.value ?? 0.0,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          strokeWidth: 8, // Thicker circle
                        );
                      },
                    )
                  : CircularProgressIndicator(
                      value: null,
                      // Show a circular indicator if no animation is ready
                      backgroundColor: Colors.grey[300],
                      strokeWidth: 8,
                    ),
            ),
            if (animation !=
                null) // Only show percentage if the animation is available
              AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Text(
                    '${(animation.value * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color, // Change text color to match the status
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> barChartGroups(List<ChartSampleData> data) {
    return data.asMap().entries.map((entry) {
      int index = entry.key;
      ChartSampleData sampleData = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: sampleData.approved.toDouble(),
            color: Colors.green,
            width: 15,
          ),
          BarChartRodData(
            toY: sampleData.pending.toDouble(),
            color: Colors.blue,
            width: 15,
          ),
          BarChartRodData(
            toY: sampleData.rejected.toDouble(),
            color: Colors.red,
            width: 15,
          ),
        ],
      );
    }).toList();
  }
}

//----------------------------------------------------------------
class Widget2 extends StatefulWidget {
  @override
  State<Widget2> createState() => _Widget2State();
}

class _Widget2State extends State<Widget2> {
  String joiningStartSalary = '0';
  Map<String, dynamic> salaryData = {
    'salarySeries': [],
    'startYear': DateTime.now().year,
  };


  @override
  void initState() {
    super.initState();
    _loadSalaryData();
  }

  Future<void> _loadSalaryData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      joiningStartSalary = prefs.getString('joining_start_salary') ?? '0';
    });

    final salaryDataMap = await _fetchSalaryData();
    setState(() {
      salaryData = salaryDataMap;
    });
  }

  Future<Map<String, dynamic>> _fetchSalaryData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? joiningSalary =
        prefs.getString('joining_start_salary') ?? 'N/A';

    final String sanitizedSalary =
        (joiningSalary ?? '0').replaceAll('₹', '').replaceAll(',', '');
    final double initialSalary = double.tryParse(sanitizedSalary) ?? 0.0;

    final SalaryDataService salaryDataService = SalaryDataService();
    final List<SlapAmount> slabs = salaryDataService.getSlapAmounts();

    final List<String> salarySeries = [];
    final int totalYears = 12;
    final int startYear = DateTime.now().year;

    for (var slab in slabs) {
      for (var grade in slab.gradeAmounts) {
        if (grade.salaryAmountOptions.contains("₹${initialSalary.toInt()}")) {
          final int startIndex =
              grade.salaryAmountOptions.indexOf("₹${initialSalary.toInt()}");
          salarySeries.addAll(
            grade.salaryAmountOptions
                .sublist(startIndex, startIndex + totalYears),
          );
          break;
        }
      }
    }

    return {
      'salarySeries': salarySeries,
      'startYear': startYear,
    };
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> salarySeries = salaryData['salarySeries'];
    final int startYear = salaryData['startYear'];

    return SingleChildScrollView(
      child: Column(
        children: [
          // Current Salary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.green.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  title: const Text(
                    'Current Salary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    '₹$joiningStartSalary',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Salary Breakdown - Line Chart
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Salary Breakdown',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 300,
                    child: salarySeries.isNotEmpty
                        ? SingleChildScrollView(
                            clipBehavior: Clip.none,
                            scrollDirection: Axis.horizontal,
                            // Enable horizontal scrolling
                            child: SalaryLineChart(
                              salarySeries: salarySeries.cast<String>(),
                              startYear: startYear,
                            ),
                          )
                        : const Center(
                            child: Text(
                              'Loading Salary Data...',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

class SalaryLineChart extends StatelessWidget {
  final List<String> salarySeries;
  final int startYear;

  const SalaryLineChart({
    Key? key,
    required this.salarySeries,
    required this.startYear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final salaryDataPoints = salarySeries.asMap().entries.map((entry) {
      final index = entry.key;
      final salary = double.tryParse(
          entry.value.replaceAll('₹', '').replaceAll(',', '')) ??
          0.0;

      return FlSpot(index.toDouble(), salary);
    }).toList();

    // Track the last displayed year
    int lastDisplayedYear = startYear - 1;

    return Container(
      width: salaryDataPoints.length * 60.0,
      // Set the width based on the number of data points
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '₹${(value ~/ 1000).toString()}K',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  // Calculate the year for the current value
                  int year = startYear + value.toInt();

                  // Only show the year if it's different from the last displayed year
                  if (year != lastDisplayedYear) {
                    // Update the last displayed year to the current one
                    lastDisplayedYear = year;
                    print('Showing year $year'); // Debugging output
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        "$year-${(year+1).toString().substring(2)}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  } else {
                    // Return an empty container to avoid duplicate years
                    return Container();
                  }
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: salaryDataPoints,
              isCurved: true,
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.lightBlueAccent],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  // Make the first dot (current salary) green
                  if (index == 0) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: Colors.green,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  }
                  // Default styling for other dots
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.blue,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.3),
                    Colors.lightBlueAccent.withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          minY: 0,
          maxY: salaryDataPoints.isNotEmpty
              ? salaryDataPoints
              .map((spot) => spot.y)
              .reduce((a, b) => a > b ? a : b) *
              1.2
              : 0,
        ),
      ),
    );
  }
}

//----------------------------------------------------------------x

// Widget 3 - Different content
class Widget3 extends StatefulWidget {
  final List<Receipt> receipts;

  const Widget3({super.key, required this.receipts});

  @override
  _Widget3State createState() => _Widget3State();
}

class _Widget3State extends State<Widget3> {
  GetReceiptResponse? getReceiptResponse;
  ReceiptByStatus? _receiptData;
  final ApiService _apiService = ApiService();
  late bool loading;
  String? error;

  Map<String, dynamic> monthlySummary = {};

  Future<void> _fetchData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('id') ?? '0'; // Default to 0 if not found
      // Fetch monthly receipt data using the new API
      final data = await _apiService.getReceiptMonthlyCount(context, userId);
      if (data['success'] == true) {
        setState(() {
          monthlySummary = data['Monthly_summary'];
        });
      } else {
        throw Exception('Failed to fetch monthly summary');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
      });
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

  Future<void> getReceiptData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('id');
      getReceiptResponse = await _apiService.getReceipt(userId!, context);
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  void initialize() async {
    setState(() {
      loading = true;
    });
    await getReceiptData();
    await _fetchData();
    setState(() {
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    loading = false;
    initialize();
  }

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Receipt> receipts = widget.receipts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Totals Section
        SingleChildScrollView(
          clipBehavior: Clip.none,
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        "Transaction Summary",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                        const SizedBox(width: 10),
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
                                        color: Colors.yellow[700]),
                                  ),
                                  Text(
                                    "Pending\nReceipts",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.yellow[700],
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
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
                                      "${getReceiptResponse?.rejectedReceipts ?? 0}", // If null, show 0
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
                            )),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Toggle Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: () {},
                child: const Text('Monthly Breakdown'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF4769B2),
                  minimumSize: const Size(120, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Content Based on Toggle
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: IndexedStack(
              index: _currentIndex,
              children: [
                // Monthly Breakdown
                ListView.builder(
                  clipBehavior: Clip.none,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: monthlySummary.keys.length,
                  itemBuilder: (context, index) {
                    final monthYear = monthlySummary.keys.elementAt(index);
                    final data = monthlySummary[monthYear]!;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  const Text(
                                    'Approved',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                        fontSize: 14),
                                  ),
                                  Text(data['approved'].toString(),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    'Pending',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.yellow[700],
                                        fontSize: 14),
                                  ),
                                  Text(data['pending'].toString(),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  const Text(
                                    'Rejected',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(data['rejected'].toString(),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 70),
      ],
    );
  }
}

class ChartSampleData {
  final String x;
  final int approved;
  final int pending;
  final int rejected;

  ChartSampleData({
    required this.x,
    required this.approved,
    required this.pending,
    required this.rejected,
  });
}

Widget _buildCircularIndicator(String title, Color color, double percentage) {
  return Column(
    children: [
      Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              color: color,
              strokeWidth: 8,
            ),
          ),
          Text(
            '${(percentage * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        title,
        style:
            TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
      ),
    ],
  );
}

List<BarChartGroupData> barChartGroups(List<ChartSampleData> chartData) {
  return chartData.asMap().entries.map((entry) {
    final index = entry.key;
    final data = entry.value;
    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: data.approved.toDouble(),
          color: Colors.green,
          width: 20,
        ),
        BarChartRodData(
          toY: data.pending.toDouble(),
          color: Colors.blue,
          width: 20,
        ),
        BarChartRodData(
          toY: data.rejected.toDouble(),
          color: Colors.red,
          width: 20,
        ),
      ],
      showingTooltipIndicators: [0],
    );
  }).toList();
}
