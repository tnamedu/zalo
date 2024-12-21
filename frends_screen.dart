import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart'; // Đảm bảo bạn đã tạo ProfileScreen

class FriendsScreen extends StatelessWidget {
  final String currentUserId;

  FriendsScreen({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('Bạn bè'),
        backgroundColor: Colors.cyanAccent,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .snapshots(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          // Trạng thái khi đang tải dữ liệu người dùng
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Kiểm tra lỗi hoặc không có dữ liệu người dùng
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Không có dữ liệu người dùng"));
          }

          Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
          List<String> friends = List<String>.from(userData['friends'] ?? []);

          // Kiểm tra nếu không có bạn bè
          if (friends.isEmpty) {
            return Center(child: Text("Chưa có bạn bè nào"));
          }

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              String friendId = friends[index];

              // Sử dụng FutureBuilder để lấy dữ liệu của từng bạn bè theo UID
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(friendId).get(),
                builder: (context, friendSnapshot) {
                  if (!friendSnapshot.hasData) {
                    return ListTile(
                      title: Text("Đang tải..."),
                    );
                  }

                  if (!friendSnapshot.data!.exists) {
                    return ListTile(
                      title: Text("Không tìm thấy dữ liệu người dùng"),
                    );
                  }

                  var friendData = friendSnapshot.data!.data() as Map<String, dynamic>;
                  String friendName = friendData['name'] ?? 'Không có tên';
                  String friendPhotoURL = friendData['photoURL'] ?? 'https://via.placeholder.com/150';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(friendPhotoURL),
                    ),
                    title: Text(friendName), // Hiển thị tên bạn bè
                    onTap: () {
                      // Chuyển hướng đến màn hình hồ sơ của người bạn
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            uid: friendId, // Truyền ID của người bạn
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
