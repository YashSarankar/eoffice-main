import 'dart:convert';

import 'package:eoffice/Auth/login_screen.dart';
import 'package:eoffice/Screens/Leaves_Screens/apply_leaves.dart';
import 'package:eoffice/Screens/Leaves_Screens/leave_dashboard.dart';
import 'package:eoffice/Screens/Leaves_Screens/total_leaves_request.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaveSummaryScreen extends StatefulWidget {
  const LeaveSummaryScreen({Key? key}) : super(key: key);

  @override
  State<LeaveSummaryScreen> createState() => _LeaveSummaryScreenState();
}

class _LeaveSummaryScreenState extends State<LeaveSummaryScreen> {
  double approvedPercentage = 0;
  double pendingPercentage = 0;
  double rejectedPercentage = 0;

  @override
  void initState() {
    super.initState();
    // fetchLeaveData();
  }

  // Future<void> fetchLeaveData() async {
  //  final prefs = await SharedPreferences.getInstance();
  //   final userId = prefs.getString('id');
  //   final response = await http.post(Uri.parse('https://eofficess.com/api/get-leave-count?user_id=$userId'));
  //
  //   if (response.statusCode == 200||response.statusCode == 201) {
  //     final Map<String, dynamic> data = json.decode(response.body);
  //     if (data['success']) {
  //       final leaveData = data['data'];
  //
  //       String firstKey = leaveData.keys.first;
  //       final statusData = leaveData[firstKey];
  //
  //       setState(() {
  //         approvedPercentage = statusData['Approved_Percentage'] / 100;
  //         pendingPercentage = statusData['Pending_Percentage'] / 100;
  //         rejectedPercentage = statusData['Rejected_Percentage'] / 100;
  //         isLoading = false;
  //       });
  //     }
  //   } else {
  //     // Handle error
  //     setState(() {
  //       isLoading = false; // Stop loading on error
  //     });
  //   }
  // }

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
        backgroundColor: const Color(0xFF4769B2),
        title: const Text('Leaves',
            style: TextStyle(color: Colors.white, fontSize: 20)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                child: Widget1(),
                // BarChart(
                //   BarChartData(
                //     barGroups: barChartGroups(), // Pass the month names and data here
                //     borderData: FlBorderData(show: false),
                //     titlesData: FlTitlesData(
                //       rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                //       topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                //       show: true,
                //       bottomTitles: AxisTitles(
                //         sideTitles: SideTitles(
                //           showTitles: true,
                //           reservedSize: 50,
                //           getTitlesWidget: (value, meta) {
                //             // Show the month name on the x-axis
                //             switch (value.toInt()) {
                //               case 0:
                //                 return SideTitleWidget(
                //                   axisSide: meta.axisSide,
                //                   child: Text('Pending', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                //                 );
                //               case 1:
                //                 return SideTitleWidget(
                //                   axisSide: meta.axisSide,
                //                   child: Text('Oct', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                //                 );
                //             // Add more cases for additional months if needed
                //               default:
                //                 return const SizedBox();
                //             }
                //           },
                //         ),
                //       ),
                //       leftTitles: AxisTitles(
                //         sideTitles: SideTitles(
                //           showTitles: true,
                //           reservedSize: 50,
                //           getTitlesWidget: (value, meta) {
                //             return SideTitleWidget(
                //               axisSide: meta.axisSide,
                //               child: Text(
                //                 value.toString(),
                //                 style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                //               ),
                //             );
                //           },
                //         ),
                //       ),
                //     ),
                //     gridData: FlGridData(show: true),
                //   ),
                // ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.grey[200],
          selectedItemColor: const Color(0xFF4769B2),
          unselectedItemColor: Colors.black,
          type: BottomNavigationBarType.fixed,
          unselectedLabelStyle:
              const TextStyle(color: Colors.black, fontSize: 12),
          selectedLabelStyle:
              const TextStyle(color: Color(0xFF4769B2), fontSize: 14),
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Date',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.square_arrow_down),
              label: 'Apply',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.download),
              label: 'Download',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'All List',
            ),
          ],
          onTap: (index) async {
            if (index == 0) {
              // Show date range picker when "Date" is selected
              final DateTimeRange? pickedDateRange = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );

              if (pickedDateRange != null) {
                final fromDate = pickedDateRange.start;
                final toDate = pickedDateRange.end;

                // Show a snackbar or dialog to notify users about the selected date range
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Selected Date Range: From ${fromDate.toLocal().toString().split(' ')[0]} To ${toDate.toLocal().toString().split(' ')[0]}'),
                  ),
                );
              }
            } else if (index == 1) {
              // Navigate to Leave Dashboard when "Apply" is selected
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LeaveManagementForm()),
              );
            } else if (index == 2) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TotalLeaveRequests()));
            } else if (index == 3) {
              // Navigate to Leave Dashboard when "All List" is selected
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LeaveDashboard()),
              );
            }
          },
        ),
      ),
    );
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
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  List<BarChartGroupData> barChartGroups() {
    return [
      BarChartGroupData(
        x: 0, // September
        barRods: [
          BarChartRodData(
            toY: approvedPercentage * 100, // Approved percentage
            color: Colors.green,
            width: 20,
          ),
          BarChartRodData(
            toY: pendingPercentage * 100, // Pending percentage
            color: Colors.blue,
            width: 20,
          ),
          BarChartRodData(
            toY: rejectedPercentage * 100, // Rejected percentage
            color: Colors.red,
            width: 20,
          ),
        ],
      ),
    ];
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
  int availableLeave = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    fetchData();
    _loadAvailableLeave();
  }

  //_loadAvailableLeave R
  Future<void> _loadAvailableLeave() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      availableLeave = prefs.getInt('available_leave') ??
          0; // Fetch the value, default to 0 if not found
    });
  }
  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> fetchData() async {
    try {
      String? token = await getAuthToken();
      if (token == null) {
        throw Exception('User is not logged in');
      }
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String userId =
          prefs.getString('id') ?? ''; // Default user ID if not found

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
            final monthYear = entry.key; // "9-2024" format
            final month = DateFormat('MMMM').format(DateTime(
                int.parse(monthYear.split('-')[1]),
                int.parse(monthYear.split('-')[0]))); // Get full month name
            final values = entry.value;
            return ChartSampleData(
              x: month, // Use the month name
              approved: values['Approved'] ?? 0.0,
              pending: values['Pending'] ?? 0.0,
              rejected: values['Rejected'] ?? 0.0,
            );
          }).toList();
        }
      }else if(response.statusCode==401){
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserAppLoginScreen()));
      } else {
        throw Exception('Failed to load data: ${response.reasonPhrase}');
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Available Leave's",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent, width: 2),
              ),
              child: Row(
                children: [
                  // Icon(Icons.calendar_today, color: Colors.blueAccent),
                  const SizedBox(width: 3),
                  Text(
                    DateFormat("MMMM yyyy").format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.beach_access, color: Colors.green),
                  const SizedBox(width: 3),
                  Text(
                    "$availableLeave Leave",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                      reservedSize: 40,
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
        const SizedBox(height: 20),
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
                          value: animation.value,
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
