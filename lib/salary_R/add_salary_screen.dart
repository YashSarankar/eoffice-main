import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'salary_list_screen.dart';
import 'services/salary_data_service.dart';
import 'models/slap_amount.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddSalaryScreen extends StatefulWidget {
  const AddSalaryScreen({super.key});

  @override
  _AddSalaryScreenState createState() => _AddSalaryScreenState();
}

class _AddSalaryScreenState extends State<AddSalaryScreen> {
  final SalaryDataService _salaryDataService = SalaryDataService();
  List<SlapAmount> slapAmounts = [];
  List<GradeAmount> gradeAmounts = [];

  SlapAmount? selectedSlapAmount;
  GradeAmount? selectedGradeAmount;
  String? referenceDocumentName;
  String? referenceDocumentPath;

  @override
  void initState() {
    super.initState();
    slapAmounts = _salaryDataService.getSlapAmounts();
    print("Slap amounts loaded: $slapAmounts");
  }

  Future<void> pickReferenceDocument() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        referenceDocumentName = result.files.single.name;
        referenceDocumentPath = result.files.single.path;
      });
      print(
          "Selected document: $referenceDocumentName at $referenceDocumentPath");
    } else {
      print("No document selected.");
    }
  }

  Future<void> submitData() async {
    if (selectedSlapAmount == null ||
        selectedGradeAmount == null ||
        referenceDocumentPath == null) {
      print("Submission failed: Missing required fields.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    // Debugging - Checking all the selected values
    print("Preparing to submit data...");
    print("Selected Slap Amount: ${selectedSlapAmount!.value}");
    print("Selected Grade Amount: ${selectedGradeAmount!.value}");
    print(
        "Reference Document: $referenceDocumentName at $referenceDocumentPath");

    try {
      // Fetching User ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('id');
      if (userId == null) {
        print("Error: User ID not found.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID not found.')),
        );
        return;
      }
      print("User ID loaded: $userId");

      final url = Uri.parse('https://eofficess.com/api/store-salary');
      final request = http.MultipartRequest('POST', url);

      // Adding fields to the request
      request.fields['user_id'] = userId;
      request.fields['slap_amount'] = selectedSlapAmount!.value;
      request.fields['grade_amount'] = selectedGradeAmount!.value;
      request.fields['direct_added_amount'] =
          selectedGradeAmount!.directAddSalary;
      request.fields['label'] = selectedGradeAmount!.level;
      request.fields['merge_amount'] = selectedGradeAmount!.mergedAmount;
      request.fields['direct_total_salary'] =
          selectedGradeAmount!.directAddTotalSalary;
      request.fields['salary_amount'] = selectedGradeAmount!.value;

      // Adding the file if selected
      if (referenceDocumentPath != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'reference_document',
          referenceDocumentPath!,
        ));
        print("File added to request: $referenceDocumentName");
      }

      // Sending the request
      print("Sending request to: $url");
      final response = await request.send();

      // Check the response status code
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Data submitted successfully!");

        // To see the response body, you need to capture it:
        final responseData = await http.Response.fromStream(response);
        print('Response body: ${responseData.body}');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data submitted successfully!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SalaryListScreen()),
        );
      } else {
        print("Submission failed with status code: ${response.statusCode}");

        // Capture and log the response body in case of an error
        final responseData = await http.Response.fromStream(response);
        print('Error body: ${responseData.body}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to submit data. Code: ${response.statusCode}')),
        );
      }
    } catch (e) {
      // Catching any error during the request
      print("Error during submission: $e");

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white, // Set the back arrow color to white
        ),
        title: const Text('Add Salary',
            style: TextStyle(color: Colors.white, fontSize: 20)),
        backgroundColor: const Color(0xFF4769B2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<SlapAmount>(
              decoration:
                  const InputDecoration(labelText: 'Select Slap Amount'),
              value: selectedSlapAmount,
              items: slapAmounts.map((slap) {
                return DropdownMenuItem(value: slap, child: Text(slap.value));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSlapAmount = value;
                  gradeAmounts = value?.gradeAmounts ?? [];
                  selectedGradeAmount = null;
                });
                print("Selected Slap Amount: ${value?.value}");
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<GradeAmount>(
              decoration:
                  const InputDecoration(labelText: 'Select Grade Amount'),
              value: selectedGradeAmount,
              items: gradeAmounts.map((grade) {
                return DropdownMenuItem(value: grade, child: Text(grade.value));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedGradeAmount = value;
                });
                print("Selected Grade Amount: ${value?.value}");
              },
            ),
            const SizedBox(height: 10),
            if (selectedGradeAmount != null) ...[
              TextFormField(
                initialValue: selectedGradeAmount!.directAddSalary,
                decoration:
                    const InputDecoration(labelText: 'Direct Add Salary'),
                readOnly: true,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: selectedGradeAmount!.mergedAmount,
                decoration: const InputDecoration(labelText: 'Merged Amount'),
                readOnly: true,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: selectedGradeAmount!.directAddTotalSalary,
                decoration:
                    const InputDecoration(labelText: 'Direct Add Total Salary'),
                readOnly: true,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: selectedGradeAmount!.level,
                decoration: const InputDecoration(labelText: 'Level'),
                readOnly: true,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration:
                    const InputDecoration(labelText: 'Select Salary Amount'),
                items: selectedGradeAmount!.salaryAmountOptions.map((option) {
                  return DropdownMenuItem(value: option, child: Text(option));
                }).toList(),
                onChanged: (value) {
                  print("Selected Salary Amount: $value");
                },
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: pickReferenceDocument,
              icon: const Icon(Icons.attach_file,
                  color: Colors.white), // Add an icon
              label: const Text(
                'Pick Reference Document',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4769B2), // Button color
                foregroundColor: Colors.white, // Text and icon color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12), // Add padding
                elevation: 5, // Add shadow effect
                shadowColor: Colors.grey.shade400,
              ),
            ),
            if (referenceDocumentName != null) ...[
              const SizedBox(height: 10),
              Text(
                'Selected Document: $referenceDocumentName',
                style: const TextStyle(fontSize: 16),
              ),
            ],
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF4769B2), // Changes to green if verified
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(color: Colors.white), // Corrected syntax
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
