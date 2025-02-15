import 'package:eoffice/Screens/Books/book_screen.dart';
import 'package:eoffice/Screens/add_receipt.dart';
import 'package:eoffice/Screens/home_screen.dart';
import 'package:eoffice/Screens/receipt_timeline_screen.dart';
import 'package:flutter/material.dart';

import 'OtherScreens/other_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: <Widget>[
          Positioned(
            child: Column(
              children: [
                Expanded(child: _getChildren()[_currentIndex]),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BottomNavigationBar(
                      currentIndex: _currentIndex,
                      backgroundColor: Colors.grey[200],
                      type: BottomNavigationBarType.fixed,
                      items: <BottomNavigationBarItem>[
                        BottomNavigationBarItem(
                          icon: Image.asset(
                            'assets/images/home.jpg',
                            width: 24,
                            height: 24,
                            color:
                                _currentIndex == 0 ? Color(0xFF4769B2) : Colors.black,
                          ),
                          label: 'HOME',
                        ),
                        BottomNavigationBarItem(
                          icon: Image.asset(
                            'assets/images/b1.jpg',
                            width: 24,
                            height: 24,
                            color:
                                _currentIndex == 1 ? Color(0xFF4769B2) : Colors.black,
                          ),
                          label: 'BOOK',
                        ),
                        BottomNavigationBarItem(
                          icon: SizedBox.shrink(), // Placeholder for the center icon
                          label: '', // Empty label for the center item
                        ),
                        BottomNavigationBarItem(
                          icon: Image.asset(
                            'assets/images/invoices.jpg',
                            width: 24,
                            height: 24,
                            color:
                                _currentIndex == 3 ? Color(0xFF4769B2) : Colors.black,
                          ),
                          label: 'RECEIPT',
                        ),
                        BottomNavigationBarItem(
                          icon: Image.asset(
                            'assets/images/more.jpg',
                            width: 24,
                            height: 24,
                            color:
                                _currentIndex == 4 ? Color(0xFF4769B2) : Colors.black,
                          ),
                          label: 'MORE',
                        ),
                      ],
                      onTap: (index) {
                        setState(() {
                          if (index == 2) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ReceiptTimeLineScreen()));
                            // Handle the center button tap if needed
                          } else {
                            _currentIndex = index;
                          }
                        });
                      },
                      unselectedLabelStyle:
                          TextStyle(color: Colors.black, fontSize: 12),
                      selectedLabelStyle:
                          TextStyle(color: Color(0xFF4769B2), fontSize: 14),
                      selectedItemColor: Color(0xFF4769B2),
                      unselectedItemColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floating Action Button for the center
          Positioned(
            bottom: 20,
            left: MediaQuery.of(context).size.width / 2 - 30,
            child: FloatingActionButton(
              backgroundColor: Color(0xFF4769B2),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ReceiptFormScreen()));
              },
              child: Icon(Icons.add, color: Colors.white),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getChildren() {
    return [
      HomeScreen(),
      // BookScreen(pdfUrl: 'http://www.pdf995.com/samples/pdf.pdf',),
      // BookScreen2(),
      BookScreen(),
      HomeScreen(),
      ReceiptTimeLineScreen(),
      OtherScreen(),
    ];
  }
}
