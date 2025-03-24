import 'dart:io';

import 'package:axion/screen/main/pages/account_page.dart';
import 'package:axion/screen/main/pages/chat_page.dart';
import 'package:axion/screen/main/pages/community_page.dart';
import 'package:axion/screen/main/pages/home_page.dart';
import 'package:axion/screen/main/pages/search_page.dart';
import 'package:axion/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomePage(), // Replace with your screen widgets
    SearchResultScreen(),
    CommunityPage(),
    ChatPage(),
    AccountPage(),
  ];
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await _showExitDialog(context);
        return shouldPop ?? false;
      },
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          selectedLabelStyle: TextStyle(color: mainColor),
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon:
                  _currentIndex == 0
                      ? Icon(Icons.home_outlined, size: 25, color: mainColor)
                      : Icon(
                        Icons.home_outlined,
                        color: secondaryColor,
                        size: 25,
                      ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon:
                  _currentIndex == 1
                      ? Icon(Icons.search, size: 25, color: mainColor)
                      : Icon(Icons.search, color: secondaryColor, size: 25),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              label: "Community",
              icon:
                  _currentIndex == 2
                      ? Image.asset("assets/communityColor.png", height: 25)
                      : Image.asset("assets/community.png", height: 25),
            ),

            BottomNavigationBarItem(
              label: "Chats",
              icon:
                  _currentIndex == 3
                      ? Image.asset("assets/chatColor.png", height: 25)
                      : Image.asset("assets/chat.png", height: 25),
            ),
            BottomNavigationBarItem(
              label: "Account",
              icon:
                  _currentIndex == 4
                      ? Icon(Icons.person, size: 25, color: mainColor)
                      : Icon(Icons.person),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Exit App'),
            content: Text('Do you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No'),
              ),
              TextButton(
                onPressed: () {
                  if (Platform.isAndroid) {
                    SystemNavigator.pop(); // For Android
                  } else if (Platform.isIOS) {
                    exit(0); // For iOS
                  }
                },
                child: Text('Yes'),
              ),
            ],
          ),
    );
  }
}
