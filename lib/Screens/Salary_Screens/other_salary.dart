// File: screens/salary_analysis_screen.dart

import 'package:flutter/material.dart';
import '../../salary_R/models/slap_amount.dart';
import '../../salary_R/salary_list_screen.dart';
import '../../salary_R/services/salary_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalaryAnalysisScreen extends StatefulWidget {
  @override
  _SalaryAnalysisScreenState createState() => _SalaryAnalysisScreenState();
}

class _SalaryAnalysisScreenState extends State<SalaryAnalysisScreen> {
  String? joiningStartSalary;
  final int totalYears = 12; // Total number of years to show
  int _currentStep = 0; // Default to the first year
  double initialSalary = 0.0; // Initial salary will be set dynamically

  int _currentYear = DateTime.now().year;
  List<String> salarySeries = [];

  @override
  void initState() {
    super.initState();
    _updateSalarySeries();
    _loadJoiningSalary();
  }

  Future<void> _loadJoiningSalary() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      joiningStartSalary = prefs.getString('joining_start_salary') ?? 'N/A';
      print("Loaded joining_start_salary: $joiningStartSalary"); // Debug print
      initialSalary = double.tryParse(joiningStartSalary ?? '0') ?? 0.0;
      print("Parsed initialSalary: $initialSalary"); // Debug print
    });
    _updateSalarySeries(); // Update salary series after loading initial salary
  }

  void _updateSalarySeries() {
    // Get the salary options from the data service
    final SalaryDataService salaryDataService = SalaryDataService();
    final List<SlapAmount> slabs = salaryDataService.getSlapAmounts();

    print(
        "Starting to update salary series with initialSalary: $initialSalary"); // Debug print

    // Find the matching slab and grade where the salary options contain the initial salary
    for (var slab in slabs) {
      for (var grade in slab.gradeAmounts) {
        if (grade.salaryAmountOptions.contains("₹${initialSalary.toInt()}")) {
          // Match found: extract the series starting from the initial salary
          final int startIndex =
              grade.salaryAmountOptions.indexOf("₹${initialSalary.toInt()}");
          salarySeries = grade.salaryAmountOptions
              .sublist(startIndex, startIndex + totalYears)
              .toList();
          print("Salary series updated: $salarySeries"); // Debug print
          return;
        }
      }
    }

    // If no match found, fallback to empty series
    salarySeries = List.generate(totalYears, (_) => '--');
    print(
        "No match found, salarySeries set to empty placeholders: $salarySeries"); // Debug print
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4769B2),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Salary Analysis',
            style: TextStyle(color: Colors.white, fontSize: 20)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Stepper(
                physics: const ClampingScrollPhysics(),
                currentStep: _currentStep,
                onStepTapped: (step) {
                  setState(() {
                    _currentStep = step;
                  });
                },
                controlsBuilder: (context, _) {
                  // Removing the continue and cancel buttons
                  return const SizedBox.shrink();
                },
                steps: List.generate(
                  totalYears, // Generate steps for each year
                  (index) {
                    final year = _currentYear + index;
                    final salary = index < salarySeries.length
                        ? salarySeries[index]
                        : '--';

                    print(
                        "Step $index: Year $year, Salary $salary"); // Debug print

                    return Step(
                      title: Text('$year'),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Salary: $salary',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          if (salary == '--')
                            const Text(
                              'Details coming soon...',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                      isActive: _currentStep == index,
                      state: _currentStep == index
                          ? StepState.complete
                          : _currentStep > index
                              ? StepState.complete
                              : StepState.indexed,
                    );
                  },
                ),
              ),
            ),
          ),

          // Button at the bottom
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SalaryListScreen()));
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                backgroundColor: const Color(0xFF4769B2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'View More',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
