import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:zalo_social_clone/services/chat_service.dart';
import 'chat_bubble.dart';

class MessagesDetailScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  MessagesDetailScreen({required this.receiverId, required this.receiverName});

  @override
  _MessagesDetailScreenState createState() => _MessagesDetailScreenState();
}

class _MessagesDetailScreenState extends State<MessagesDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Chọn ảnh từ thư viện
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không có ảnh nào được chọn.")),
      );
      return;
    }

    // Tải ảnh lên Firebase Storage
    try {
      final storageRef = FirebaseStorage.instance.ref().child('chat_images/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = storageRef.putFile(File(pickedFile.path));
      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      // Gửi tin nhắn ảnh
      _sendMessageWithImage(imageUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi tải ảnh: $e")),
      );
    }
  }

  // Gửi tin nhắn văn bản hoặc ảnh
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    try {
      _chatService.sendMessage(
        currentUserId,
        widget.receiverId,
        _messageController.text.trim(), imageUrl: '',
      );
      _messageController.clear();

      // Cuộn xuống cuối danh sách tin nhắn sau khi gửi
      Future.delayed(Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          0.0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      print("Error sending message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không thể gửi tin nhắn. Vui lòng thử lại.")),
      );
    }
  }

  // Gửi tin nhắn có ảnh
  void _sendMessageWithImage(String imageUrl) {
    try {
      _chatService.sendMessage(
        currentUserId,
        widget.receiverId,
        '',
        imageUrl: imageUrl, // Gửi URL ảnh
      );

      // Cuộn xuống sau khi gửi
      Future.delayed(Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          0.0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không thể gửi ảnh. Vui lòng thử lại.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.receiverName),
        backgroundColor: Colors.cyanAccent,
      ),
      body: Column(
        children: [
          // Hiển thị danh sách tin nhắn
          Expanded(
            child: StreamBuilder(
              stream: _chatService.getMessages(currentUserId, widget.receiverId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("Chưa có tin nhắn nào."));
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ChatBubble(
                      message: message.message,
                      isSent: message.senderId == currentUserId,
                      imageUrl: message.imageUrl, avatarUrl: '', // Thêm URL ảnh nếu có
                    );
                  },
                );
              },
            ),
          ),
          // Ô nhập tin nhắn và gửi ảnh
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.image),
                    onPressed: _pickImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Nhắn tin',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.black),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
