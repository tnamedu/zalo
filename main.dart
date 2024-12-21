import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:zalo_social_clone/screen/home_screen.dart';
import 'package:zalo_social_clone/screen/login_screen.dart';
import 'package:zalo_social_clone/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Khởi tạo Firebase
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App Name',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,  // Tắt banner debug
      home: AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    // Kiểm tra người dùng đã đăng nhập hay chưa
    return FutureBuilder(
      future: _authService.currentUser == null ? Future.value(false) : Future.value(true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == false) {
          // Nếu chưa đăng nhập, chuyển hướng đến màn hình Login
          return LoginScreen();
        } else {
          // Nếu đã đăng nhập, chuyển hướng đến màn hình Home
          return HomeScreen();
        }
      },
    );
  }
}
