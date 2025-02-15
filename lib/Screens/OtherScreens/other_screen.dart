import 'package:eoffice/Screens/Leaves_Screens/leave_summary.dart';
import 'package:eoffice/Screens/OtherScreens/achivement_view.dart';
import 'package:eoffice/Screens/OtherScreens/affidavit_view.dart';
import 'package:eoffice/Screens/OtherScreens/auditForm.dart';
import 'package:eoffice/Screens/OtherScreens/checklist_screen.dart';
import 'package:eoffice/Screens/OtherScreens/document_screen.dart';
import 'package:eoffice/Screens/OtherScreens/nomination_screen.dart';
import 'package:eoffice/Screens/Profile_Screens/userprofile_screen.dart';
import 'package:eoffice/Screens/Salary_Screens/other_salary.dart';
import 'package:eoffice/user_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtherScreen extends StatefulWidget {
  const OtherScreen({super.key});

  @override
  State<OtherScreen> createState() => _OtherScreenState();
}

class _OtherScreenState extends State<OtherScreen> {
  String firstName = '';
  String lastName = '';
  String qualification = '';
  String profileImage = '';
  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      qualification = prefs.getString('design_id') ?? '';
      firstName = prefs.getString('first_name') ?? '';
      lastName = prefs.getString('last_name') ?? '';
      profileImage = prefs.getString('profile_pic') ??
          'https://eofficess.com/profilephoto/default.jpg'; // Default image URL
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => UserProfileView()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF4769B2).withOpacity(0.2),
                          offset: Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.transparent,
                          radius: 24,
                          backgroundImage: NetworkImage(
                              'https://eofficess.com/profilephoto/$profileImage'), // Prepend the path to the file name
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                qualification.isNotEmpty
                                    ? qualification.toUpperCase()
                                    : 'Qualification Not Provided',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '$firstName $lastName',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            color: Colors.grey[600], size: 20),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30),
                GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: _gridItems.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final item = _gridItems[index];
                    return _buildGridItem(
                      context,
                      title: item['title'],
                      assetPath: item['assetPath'],
                      onTap: item['onTap'],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context,
      {required String title,
      required String assetPath,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.transparent,
            backgroundImage: AssetImage(assetPath),
            radius: 24,
            child: Align(
              alignment: Alignment.center,
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                width: 48,
                height: 48,
              ),
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _gridItems => [
        {
          'title': 'Leave\nSummary',
          'assetPath': 'assets/images/leaves.jpg',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LeaveSummaryScreen()),
            );
          },
        },
        {
          'title': 'Nomination\nForm',
          'assetPath': 'assets/images/nomineee.jpg',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NominationScreen()),
            );
          },
        },
        {
          'title': 'Add\nDocuments',
          'assetPath': 'assets/images/folders.jpg',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DocumentUploadScreen(
                        category: '',
                      )),
            );
          },
        },
        {
          'title': 'Salary\nAnalysis',
          'assetPath': 'assets/images/salary.jpg',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SalaryAnalysisScreen()),
            );
          },
        },
        {
          'title': 'Checklist\nDetails',
          'assetPath': 'assets/images/check-list.jpg',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChecklistScreen()),
            );
          },
        },
        {
          'title': 'User\nDetails',
          'assetPath': 'assets/images/list.jpg',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserDetailView()),
            );
          },
        },
        {
          'title': 'Affidavit\nForm',
          'assetPath': 'assets/images/scholarship.png',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AffidavitView()),
            );
          },
        },
        {
          'title': 'Achievement\nForm',
          'assetPath': 'assets/images/achievement.png',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AchievementView()),
            );
          },
        },
        {
          'title': 'Audit\nForm',
          'assetPath': 'assets/images/audit.png',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AuditForm()),
            );
          },
        },
        {
          'title': 'Transfer & Joining\nForm',
          'assetPath': 'assets/images/transfer.png',
          'onTap': () {},
        },
        {
          'title': 'Pension\nForm',
          'assetPath': 'assets/images/pension.png',
          'onTap': () {},
        },
      ];
}
