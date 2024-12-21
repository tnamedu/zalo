import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zalo_social_clone/models/post_model.dart';
import 'dart:io';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  // Hàm chọn ảnh từ thư viện
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Hàm tải ảnh lên Firebase Storage
  Future<String?> _uploadImageToStorage() async {
    if (_selectedImage == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('post_images')
          .child('${DateTime
          .now()
          .millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(_selectedImage!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Lỗi tải ảnh lên Storage: $e');
      return null;
    }
  }

  // Hàm đăng bài
  Future<void> _createPost() async {
    final String content = _contentController.text.trim();

    if (content.isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập nội dung hoặc chọn ảnh.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (currentUserId.isEmpty) {
        throw Exception("Người dùng chưa đăng nhập.");
      }

      // Tải ảnh lên Storage nếu có
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImageToStorage();
      }

      // Tạo ID duy nhất cho bài đăng
      final postId = FirebaseFirestore.instance
          .collection('posts')
          .doc()
          .id;

      // Tạo đối tượng PostModel
      PostModel post = PostModel(
        postId: postId,
        userId: currentUserId,
        content: content,
        imageUrl: imageUrl ?? '',
        likes: 0,
        timestamp: Timestamp.now(),
      );

      // Lưu bài đăng vào bộ sưu tập "posts" (hiển thị trên Home)
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(post.postId)
          .set(post.toMap());

      // Lưu bài đăng vào bộ sưu tập "user_posts/{userId}/posts" (hiển thị trên Profile)
      await FirebaseFirestore.instance
          .collection('user_posts')
          .doc(currentUserId)
          .collection('posts')
          .doc(post.postId)
          .set(post.toMap());

      // Quay lại màn hình Home sau khi đăng bài
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng bài thành công!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã có lỗi xảy ra: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tạo bài viết',
          style: TextStyle(color: Colors.black), // Đặt màu chữ cho AppBar
        ),
        backgroundColor: Colors.cyanAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Nội dung bài đăng',
                labelStyle: TextStyle(color: Colors.black), // Màu chữ cho label
                border: OutlineInputBorder(),
              ),
              style: TextStyle(color: Colors.black), // Màu chữ trong TextField
            ),
            SizedBox(height: 10),
            _selectedImage != null
                ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Image.file(
                _selectedImage!,
                height: 200,
                fit: BoxFit.cover,
              ),
            )
                : ElevatedButton(
              onPressed: _pickImage,
              child: Text(
                'Chọn ảnh',
                style: TextStyle(color: Colors.black), // Màu chữ trên nút
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 24),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _createPost,
              child: Text(
                'Đăng bài',
                style: TextStyle(color: Colors.black), // Màu chữ trên nút
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
