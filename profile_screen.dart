import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zalo_social_clone/models/user_profile.dart';
import 'package:zalo_social_clone/screen/login_screen.dart';
import 'package:zalo_social_clone/screen/create_post_screen.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'comments_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String uid;

  ProfileScreen({required this.uid});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void _navigateToCreatePost(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreatePostScreen()),
    );
  }

  Future<void> _updateProfilePicture(BuildContext context, String uid) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không có ảnh nào được chọn.")),
      );
      return;
    }

    try {
      // Upload ảnh lên Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child(
          'profile_pictures/$uid');
      final uploadTask = storageRef.putFile(File(pickedFile.path));
      final snapshot = await uploadTask;
      final photoURL = await snapshot.ref.getDownloadURL();

      // Cập nhật URL ảnh đại diện trong Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'photoURL': photoURL,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cập nhật ảnh đại diện thành công!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi cập nhật ảnh đại diện: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: FirebaseAuth.instance.currentUser?.uid !=
            uid,
        // Ẩn nút back khi xem hồ sơ của chính mình
        title: Text("Hồ Sơ"),
        centerTitle: true,
        backgroundColor: Colors.cyanAccent,
        leading: FirebaseAuth.instance.currentUser?.uid !=
            uid // Kiểm tra nếu là chính chủ thì không hiển thị nút back
            ? IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Quay lại màn hình trước
          },
          tooltip: 'Quay lại',
        )
            : null,
        actions: [
          if (FirebaseAuth.instance.currentUser?.uid == uid)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () => _logout(context),
              tooltip: 'Đăng xuất',
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Đã xảy ra lỗi khi tải hồ sơ."));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Không tìm thấy người dùng"));
          }

          UserProfile profile = UserProfile.fromMap(
              snapshot.data!.data() as Map<String, dynamic>);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _updateProfilePicture(context, uid),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(
                        profile.photoURL ?? 'https://via.placeholder.com/150',
                      ),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 18,
                          child: Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    profile.name ?? 'Không có tên',
                    style: TextStyle(fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  SizedBox(height: 10),
                  Text(
                    profile.email ?? 'Không có email',
                    style: TextStyle(fontSize: 1, color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatsColumn("Bạn bè", profile.friendCount ?? 0),
                      SizedBox(width: 30),
                      _buildStatsColumn(
                          "Người theo dõi", profile.followerCount ?? 0),
                    ],
                  ),
                  SizedBox(height: 30),
                  // Hiển thị nút tạo bài viết chỉ khi xem hồ sơ của người dùng đang đăng nhập
                  if (FirebaseAuth.instance.currentUser?.uid == uid)
                    ElevatedButton(
                      onPressed: () => _navigateToCreatePost(context),
                      child: Text("Tạo bài viết"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                    ),
                  SizedBox(height: 30),
                  _buildSectionTitle("Bài đăng"),
                  SizedBox(height: 10),
                  _buildUserPosts(uid),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsColumn(String title, int count) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
        SizedBox(height: 5),
        Text(
          "$count",
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildUserPosts(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_posts')
          .doc(userId)
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Đã xảy ra lỗi khi tải bài đăng."));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("Người dùng chưa có bài đăng nào."));
        }

        final posts = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final content = post['content'] ?? 'Không có nội dung';
            final imageUrl = post['imageUrl'] ?? null; // Ảnh đính kèm (nếu có)
            final timestamp = (post['timestamp'] as Timestamp).toDate();
            final likes = post['likes'] ?? 0;

            // Format ngày tháng
            final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(
                timestamp);

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null)
                    Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ListTile(
                    title: Text(content),
                    subtitle: Text("Ngày đăng: $formattedDate"),
                    trailing: (post['userId'] ==
                        FirebaseAuth.instance.currentUser?.uid)
                        ? IconButton(
                      icon: Icon(Icons.delete),
                      color: Colors.cyanAccent,
                      onPressed: () async {
                        // Xóa bài viết khỏi user_posts và posts
                        await FirebaseFirestore.instance
                            .collection('user_posts')
                            .doc(userId)
                            .collection('posts')
                            .doc(post.id)
                            .delete();

                        await FirebaseFirestore.instance
                            .collection('posts')
                            .doc(post.id)
                            .delete();
                      },
                    )
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Nút Like
            IconButton(
            icon: Icon(
            Icons.thumb_up,
            color: ((post.data() as Map<String, dynamic>).containsKey('likesBy') &&
            (post['likesBy'] is List &&
            post['likesBy']?.contains(FirebaseAuth.instance.currentUser?.uid) == true))
            ? Colors.blue
                : Colors.grey,
            ),
            onPressed: () async {
            final currentUser = FirebaseAuth.instance.currentUser?.uid;
            if (currentUser != null) {
            final postData = post.data() as Map<String, dynamic>;
            if (postData.containsKey('likesBy') &&
            (post['likesBy'] is List &&
            post['likesBy']?.contains(currentUser) == true)) {
            // Unlike
            await FirebaseFirestore.instance
                .collection('user_posts')
                .doc(userId)
                .collection('posts')
                .doc(post.id)
                .update({
            'likes': FieldValue.increment(-1),
            'likesBy': FieldValue.arrayRemove([currentUser]),
            });
            } else {
            // Like
            await FirebaseFirestore.instance
                .collection('user_posts')
                .doc(userId)
                .collection('posts')
                .doc(post.id)
                .update({
            'likes': FieldValue.increment(1),
            'likesBy': FieldValue.arrayUnion([currentUser]),
            });
            }
            }
            },
            ),
            Text('$likes lượt thích'),
                        // Nút Bình luận
                        IconButton(
                          icon: Icon(Icons.comment),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CommentsScreen(postId: post.id),
                              ),
                            );
                          },
                        ),
                        // Nút Chia sẻ
                        IconButton(
                          icon: Icon(Icons.share),
                          onPressed: () {
                            final shareContent = "Bài viết: $content\nNgày đăng: $formattedDate";
                            Share.share(shareContent);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
