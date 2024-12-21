import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zalo_social_clone/screen/comments_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart'; // Hiển thị thời gian

class PostWidget extends StatefulWidget {
  final String postId;
  final String userId;
  final String content;
  final String? imageUrl;
  final int likes;
  final Timestamp timestamp;
  final Function? onDelete; // Thêm tham số onDelete vào constructor

  PostWidget({
    required this.postId,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.likes,
    required this.timestamp,
    this.onDelete, // Khai báo tham số onDelete trong constructor
  });

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  late bool isLiked;
  late int likeCount;
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  late String userName;

  @override
  void initState() {
    super.initState();
    isLiked = false;
    likeCount = widget.likes;
    _checkIfLiked();
    _fetchUserName();
  }

  void _checkIfLiked() async {
    DocumentSnapshot postDoc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .get();

    if (postDoc.exists) {
      List likedBy = postDoc['likedBy'] ?? [];
      setState(() {
        isLiked = likedBy.contains(currentUserId);
      });
    }
  }

  void _fetchUserName() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    if (userDoc.exists) {
      setState(() {
        userName = userDoc['name'] ?? 'Người dùng';
      });
    }
  }

  void _toggleLike() async {
    if (currentUserId == null) return;

    DocumentReference postRef =
    FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    setState(() {
      if (isLiked) {
        likeCount -= 1;
        isLiked = false;
      } else {
        likeCount += 1;
        isLiked = true;
      }
    });

    if (isLiked) {
      await postRef.update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([currentUserId]),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([currentUserId]),
      });
    }
  }

  void _deletePost(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bài đăng đã được xóa')),
      );
      if (widget.onDelete != null) {
        widget.onDelete!(); // Gọi hàm onDelete nếu nó được truyền vào
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể xóa bài đăng: $e')),
      );
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xóa bài đăng'),
          content: Text('Bạn có chắc chắn muốn xóa bài đăng này không?'),
          actions: [
            TextButton(
              child: Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Xóa'),
              onPressed: () {
                Navigator.of(context).pop();
                _deletePost(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _sharePost() {
    String postContent = widget.content;
    String? imageUrl = widget.imageUrl;

    String shareText = postContent;
    if (imageUrl != null) {
      shareText += '\n\n$imageUrl';
    }

    Share.share(shareText, subject: 'Chia sẻ bài đăng');
  }

  @override
  Widget build(BuildContext context) {
    String formattedTime =
    DateFormat('HH:mm').format(widget.timestamp.toDate()); // Hiển thị giờ

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(userName), // Hiển thị tên người dùng
            subtitle: Text('Đã đăng lúc $formattedTime'), // Hiển thị giờ đăng
            trailing: (currentUserId == widget.userId)
                ? IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _showDeleteConfirmationDialog(context);
              },
            )
                : null,
          ),
          Text(
            widget.content, // Hiển thị nội dung bài đăng
            style: TextStyle(fontSize: 20.0),
          ),
          if (widget.imageUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Image.network(
                widget.imageUrl!,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: isLiked ? Colors.blue : Colors.grey,
                  ),
                  onPressed: _toggleLike,
                ),
                Text('$likeCount lượt thích'),
                SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.comment),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CommentsScreen(postId: widget.postId),
                      ),
                    );
                  },
                ),
                Text('Bình luận'),
                SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: _sharePost,
                ),
                Text('Chia sẻ'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
