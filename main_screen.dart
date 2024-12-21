import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'frends_screen.dart';
import 'Notifications_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mess_screen.dart';  // Import MessagesScreen

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String? uid;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
      return;
    }

    // Set up the pages for the bottom navigation
    _pages = [
      HomeScreen(),
      FriendsScreen(currentUserId: uid!),
      NotificationsScreen(currentUserId: uid!),
      ProfileScreen(uid: uid!),
      MessagesScreen(),  // Add MessagesScreen here
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Function to get the count of pending notifications
  Stream<int> getNotificationCount() {
    return FirebaseFirestore.instance
        .collection('friend_requests')
        .where('to', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return SizedBox.shrink();
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: getNotificationCount(),
        builder: (context, snapshot) {
          int notificationCount = snapshot.data ?? 0;

          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Trang Chủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Bạn Bè',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    Icon(Icons.notifications),
                    if (notificationCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$notificationCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Thông Báo',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Hồ sơ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: 'Tin nhắn',  // Label for Chat
              ),
            ],
            selectedItemColor: Colors.cyanAccent,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedIconTheme: IconThemeData(size: 24),
            unselectedIconTheme: IconThemeData(size: 24),
          );
        },
      ),
    );
  }
}
