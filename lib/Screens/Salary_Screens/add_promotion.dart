import 'package:eoffice/api_services.dart';
import 'package:file_picker/file_picker.dart'; // For file picking
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // For image picking
import 'package:intl/intl.dart'; // For date formattng

class AddPromotionForm extends StatefulWidget {
  @override
  _AddPromotionFormState createState() => _AddPromotionFormState();
}

class _AddPromotionFormState extends State<AddPromotionForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  TextEditingController _incrementNameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _additionalSalaryController = TextEditingController();
  TextEditingController _incrementDateController = TextEditingController();
  TextEditingController _additionalAmountController = TextEditingController();

  String? _selectedDesignation;
  String? _selectedIncrementType;
  String? _selectedSalaryCalculationType;
  String? _selectedFilePath; // For additional document
  String? _userSignature; // For signature upload

  // Sample dropdown values
  List<String> _designations = ['Manager', 'Developer', 'Team Lead', 'HR'];
  List<String> _incrementTypes = ['Additional Salary', 'Position Salary'];
  List<String> _salaryCalculationTypes = ['Fixed', 'Percentage'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Add Promotion',
            style: TextStyle(color: Colors.white, fontSize: 20)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        titleSpacing: 0,
        backgroundColor: Color(0xFF4769B2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Designation dropdown
              DropdownButtonFormField<String>(
                value: _selectedDesignation,
                decoration: _inputDecoration('Designation'),
                items: _designations.map((designation) {
                  return DropdownMenuItem(
                    value: designation,
                    child: Text(designation),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDesignation = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a designation' : null,
              ),

              SizedBox(height: 16),

              // Salary input field
              TextFormField(
                controller: _additionalSalaryController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Salary'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter salary';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Increment type dropdown
              DropdownButtonFormField<String>(
                value: _selectedIncrementType,
                decoration: _inputDecoration('Increment Type'),
                items: _incrementTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedIncrementType = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select an increment type' : null,
              ),

              SizedBox(height: 16),

              // Increment name input
              TextFormField(
                controller: _incrementNameController,
                decoration: _inputDecoration('Increment Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter increment name';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Description input
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration('Description'),
                maxLines: 3,
              ),

              SizedBox(height: 16),

              // Increment date picker
              TextFormField(
                controller: _incrementDateController,
                decoration: _inputDecoration('Increment Date').copyWith(
                  suffixIcon: IconButton(
                    icon:
                        Icon(Icons.calendar_today, color: Colors.blueGrey[800]),
                    onPressed: () => _pickIncrementDate(context),
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a date';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Salary calculation type dropdown
              DropdownButtonFormField<String>(
                value: _selectedSalaryCalculationType,
                decoration: _inputDecoration('Salary Calculation Type'),
                items: _salaryCalculationTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSalaryCalculationType = value;
                  });
                },
                validator: (value) => value == null
                    ? 'Please select a salary calculation type'
                    : null,
              ),

              SizedBox(height: 16),

              // Additional amount input field
              TextFormField(
                controller: _additionalAmountController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Additional Amount'),
              ),

              SizedBox(height: 16),

              // Additional document upload
              Card(
                elevation: 2,
                color: Colors.white,
                child: ListTile(
                  title: Text(_selectedFilePath == null
                      ? 'Upload Document'
                      : 'Document uploaded'),
                  subtitle: Text(_selectedFilePath ?? 'pick document'),
                  trailing:
                      Icon(Icons.upload_file, color: Colors.blueGrey[800]),
                  onTap: _pickFile,
                ),
              ),

              SizedBox(height: 16),

              // User digital signature upload
              Card(
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                color: Colors.white,
                child: ListTile(
                  title: Text(_userSignature == null
                      ? 'Upload Digital Signature'
                      : 'Signature uploaded'),
                  subtitle: Text(_userSignature ?? 'pick signature'),
                  trailing:
                      Icon(Icons.upload_file, color: Colors.blueGrey[800]),
                  onTap: _pickSignature,
                ),
              ),

              SizedBox(height: 32),

              // Submit button
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Collect form data
                    String designation = _selectedDesignation!;
                    String additionalSalary = _additionalSalaryController.text;
                    String incrementType = _selectedIncrementType!;
                    String incrementName = _incrementNameController.text;
                    String description = _descriptionController.text;
                    String incrementDate = _incrementDateController.text;
                    String salaryCalculationType =
                        _selectedSalaryCalculationType!;
                    String additionalAmount = _additionalAmountController.text;

                    // Create an instance of the API service
                    ApiService apiServices = ApiService();

                    // Call the submitPromotion function
                    bool success = await apiServices.submitPromotion(
                      designation: designation,
                      additionalSalary: additionalSalary,
                      incrementType: incrementType,
                      incrementName: incrementName,
                      description: description,
                      incrementDate: incrementDate,
                      salaryCalculationType: salaryCalculationType,
                      additionalAmount: additionalAmount,
                      filePath: _selectedFilePath, // Optional file path
                      userSignature: _userSignature, // Optional signature
                    );

                    // Handle the response
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Form submitted successfully!')));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'Failed to submit the form. Please try again.')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4769B2),
                  minimumSize: Size(double.infinity, 40),
                ),
                child: Text('Submit',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to pick increment date
  Future<void> _pickIncrementDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _incrementDateController.text =
            DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  // Function to pick additional document
  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        _selectedFilePath = result.files.single.name; // File name
      });
    }
  }

  // Function to pick digital signature
  void _pickSignature() async {
    XFile? result = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (result != null) {
      setState(() {
        _userSignature = result.name; // Image file name
      });
    }
  }

  // Helper method for input decoration
  InputDecoration _inputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: Colors.blueGrey[800]),
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
