import 'dart:io';

import 'package:axion/screen/main/pages/account_page.dart';
import 'package:axion/screen/main/pages/chat_page.dart';
import 'package:axion/screen/main/pages/community_page.dart';
import 'package:axion/screen/main/pages/home_page.dart';
import 'package:axion/screen/main/pages/live_stream.dart';
import 'package:axion/screen/main/pages/search_page.dart';
import 'package:axion/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;
  String? _liveStreamUserName; // State variable to hold the fetched username
  bool _isLoadingUserName = true; // To show loading while fetching username

  @override
  void initState() {
    super.initState();
    _fetchUserName(); // Call the method to fetch username
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (userDoc.exists) {
          setState(() {
            // Assuming 'fullName' is the field storing the user's name
            _liveStreamUserName = userDoc.data()?['fullName'];
          });
        }
      } catch (e) {
        print("Error fetching user name: $e");
        // Handle error, maybe set a default or show an error message
      } finally {
        setState(() {
          _isLoadingUserName =
              false; // Set loading to false regardless of success or failure
        });
      }
    } else {
      setState(() {
        _isLoadingUserName = false; // User is not logged in
      });
    }
  }

  // Use a getter for _screens so it's re-evaluated when _liveStreamUserName changes
  List<Widget> get _screens {
    // Provide a default or loading indicator for userName if it's not yet fetched
    // You might want to handle the loading state within LiveStreamPage itself for better UX
    String userNameForLiveStream = _liveStreamUserName ?? 'Guest User';

    return [
      HomePage(), // Replace with your screen widgets
      SearchResultScreen(),
      CommunityPage(),
      ChatPage(),
      // Pass the fetched username to LiveStreamPage
      LiveStreamPage(
        userName: userNameForLiveStream,
        liveID: 'live_${FirebaseAuth.instance.currentUser!.uid}',
        userID: FirebaseAuth.instance.currentUser!.uid,
        isHost: true,
      ),
      AccountPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await _showExitDialog(context);
        return shouldPop ?? false;
      },
      child: Scaffold(
        // Show a loading indicator until the username is fetched,
        // especially if LiveStreamPage critically depends on it.
        // Or, LiveStreamPage itself can handle the 'Guest User' case.
        body:
            _isLoadingUserName &&
                    _currentIndex ==
                        4 // Only show loading if on Live tab and username is loading
                ? const Center(child: CircularProgressIndicator())
                : _screens[_currentIndex],
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
              label: "Live",
              icon:
                  _currentIndex == 4
                      ? Icon(Icons.live_tv, size: 25)
                      : Icon(Icons.live_tv, size: 25),
            ),
            BottomNavigationBarItem(
              label: "Account",
              icon:
                  _currentIndex == 5
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
