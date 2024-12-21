import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zalo_social_clone/widget/comment_widget.dart';

class CommentsScreen extends StatelessWidget {
  final String postId;

  CommentsScreen({required this.postId});

  final TextEditingController _commentController = TextEditingController();
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // Hàm để thêm bình luận vào Firestore
  void _addComment() {
    if (_commentController.text.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
        'userId': currentUserId,
        'content': _commentController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bình luận')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    var commentData = comments[index];
                    var userId = commentData['userId'];

                    // Lấy thông tin người dùng từ Firestore
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (!userSnapshot.hasData) {
                          return ListTile(title: Text('Không tìm thấy người dùng'));
                        }

                        var user = userSnapshot.data!;
                        var userName = user['name'] ?? 'Người dùng';

                        return CommentWidget(
                          userName: userName,  // Hiển thị tên người dùng
                          content: commentData['content'],
                          timestamp: (commentData['timestamp'] as Timestamp).toDate(),
                          onDelete: (currentUserId == userId || currentUserId == postId)
                              ? () => _deleteComment(commentData.id)
                              : null,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(hintText: 'Thêm bình luận...'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hàm để xóa bình luận
  void _deleteComment(String commentId) {
    FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }
}
