import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'comments_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final DocumentSnapshot user;
  final String currentUserId;

  UserProfileScreen({required this.user, required this.currentUserId});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool isFollowing = false;
  bool isFriend = false;
  bool isRequestPending = false;

  @override
  void initState() {
    super.initState();
    _initializeStatus();
  }

  Future<void> _initializeStatus() async {
    try {
      isFollowing = await checkIfFollowing();
      isFriend = await checkFriendshipStatus();
      isRequestPending = await checkIfRequestPending();
      setState(() {});
    } catch (e) {
      debugPrint("Lỗi khi tải trạng thái: $e");
    }
  }

  Future<bool> checkIfFollowing() async {
    try {
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .get();
      List following = currentUserDoc['following'] ?? [];
      return following.contains(widget.user.id);
    } catch (e) {
      debugPrint("Lỗi kiểm tra trạng thái theo dõi: $e");
      return false;
    }
  }

  Future<bool> checkFriendshipStatus() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .get();
      List friends = userDoc['friends'] ?? [];
      return friends.contains(widget.currentUserId);
    } catch (e) {
      debugPrint("Lỗi kiểm tra trạng thái bạn bè: $e");
      return false;
    }
  }

  Future<bool> checkIfRequestPending() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('from', isEqualTo: widget.currentUserId)
          .where('to', isEqualTo: widget.user.id)
          .where('status', isEqualTo: 'pending')
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint("Lỗi kiểm tra trạng thái yêu cầu kết bạn: $e");
      return false;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)));
  }

  Future<void> toggleFollow() async {
    try {
      if (isFollowing) {
        await FirebaseFirestore.instance.collection('users').doc(
            widget.currentUserId).update({
          'following': FieldValue.arrayRemove([widget.user.id]),
        });
        await FirebaseFirestore.instance.collection('users')
            .doc(widget.user.id)
            .update({
          'followers': FieldValue.arrayRemove([widget.currentUserId]),
          'followerCount': FieldValue.increment(-1),
        });
        _showSnackBar("Đã hủy theo dõi");
      } else {
        await FirebaseFirestore.instance.collection('users').doc(
            widget.currentUserId).update({
          'following': FieldValue.arrayUnion([widget.user.id]),
        });
        await FirebaseFirestore.instance.collection('users')
            .doc(widget.user.id)
            .update({
          'followers': FieldValue.arrayUnion([widget.currentUserId]),
          'followerCount': FieldValue.increment(1),
        });
        _showSnackBar("Đã theo dõi");
      }
      setState(() {
        isFollowing = !isFollowing;
      });
    } catch (e) {
      _showSnackBar("Lỗi khi cập nhật trạng thái theo dõi");
    }
  }

  Future<void> toggleFriendRequest() async {
    try {
      if (isRequestPending) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('friend_requests')
            .where('from', isEqualTo: widget.currentUserId)
            .where('to', isEqualTo: widget.user.id)
            .where('status', isEqualTo: 'pending')
            .get();

        for (var doc in querySnapshot.docs) {
          await FirebaseFirestore.instance.collection('friend_requests').doc(
              doc.id).delete();
        }
        _showSnackBar("Đã hủy lời mời kết bạn");
      } else if (isFriend) {
        await FirebaseFirestore.instance.collection('users').doc(
            widget.currentUserId).update({
          'friends': FieldValue.arrayRemove([widget.user.id]),
        });
        await FirebaseFirestore.instance.collection('users')
            .doc(widget.user.id)
            .update({
          'friends': FieldValue.arrayRemove([widget.currentUserId]),
        });
        _showSnackBar("Đã hủy kết bạn");
      } else {
        await FirebaseFirestore.instance.collection('friend_requests').add({
          'from': widget.currentUserId,
          'to': widget.user.id,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });
        _showSnackBar("Yêu cầu kết bạn đã được gửi");
      }
      setState(() {
        isRequestPending = !isRequestPending;
        if (isFriend) isFriend = false;
      });
    } catch (e) {
      _showSnackBar("Lỗi khi cập nhật trạng thái kết bạn");
    }
  }

  Future<void> toggleLike(String postId) async {
    try {
      DocumentSnapshot postDoc = await FirebaseFirestore.instance
          .collection('user_posts')
          .doc(widget.user.id)
          .collection('posts')
          .doc(postId)
          .get();

      List likes = postDoc['likes'] ?? [];
      bool isLiked = likes.contains(widget.currentUserId);

      if (isLiked) {
        await FirebaseFirestore.instance
            .collection('user_posts')
            .doc(widget.user.id)
            .collection('posts')
            .doc(postId)
            .update({
          'likes': FieldValue.arrayRemove([widget.currentUserId]),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('user_posts')
            .doc(widget.user.id)
            .collection('posts')
            .doc(postId)
            .update({
          'likes': FieldValue.arrayUnion([widget.currentUserId]),
        });
      }
    } catch (e) {
      _showSnackBar("Lỗi khi thực hiện hành động Like");
    }
  }

  String _formatDate(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user['name'] ?? 'Người dùng'),
        backgroundColor: Colors.cyanAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 70,
              backgroundImage: NetworkImage(
                widget.user['photoURL'] ?? 'https://via.placeholder.com/150',
              ),
            ),
            SizedBox(height: 12),
            Text(
              widget.user['name'] ?? 'Không rõ',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(
                  widget.user.id).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                final data = snapshot.data;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildInfoText(
                        'Người theo dõi: ${data?['followerCount'] ?? 0}'),
                    SizedBox(width: 20),
                    _buildInfoText('Bạn bè: ${data?['friendCount'] ?? 0}'),
                  ],
                );
              },
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: toggleFollow,
                  child: Text(isFollowing ? 'Hủy theo dõi' : 'Theo dõi'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: toggleFriendRequest,
                  child: Text(
                    isRequestPending
                        ? 'Hủy lời mời kết bạn'
                        : (isFriend ? 'Hủy kết bạn' : 'Kết bạn'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            _buildPostsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_posts')
          .doc(widget.user.id)
          .collection('posts')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("Chưa có bài viết"));
        }

        final posts = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final postId = post.id;

            return Card(
              elevation: 5,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(
                            widget.user['photoURL'] ?? 'https://via.placeholder.com/150',
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          widget.user['name'] ?? 'Người dùng',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      post['content'] ?? 'Không có nội dung',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    // Hiển thị ảnh bài đăng nếu có
                    post['imageUrl'] != null
                        ? Image.network(post['imageUrl'])
                        : Container(),
                    SizedBox(height: 8),
                    Text(
                      _formatDate(post['timestamp']),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => toggleLike(postId),
                          icon: Icon(
                            Icons.thumb_up,
                            color: Colors.grey,
                          ),
                        ),
                        Text('Like'),
                        Spacer(),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CommentsScreen(postId: post.id),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.comment,
                            color: Colors.black,
                          ),
                        ),
                        Text('Bình luận'),
                        Spacer(),
                        IconButton(
                          onPressed: () {
                            // Chức năng chia sẻ chưa được thực hiện
                          },
                          icon: Icon(
                            Icons.share,
                            color: Colors.black,
                          ),
                        ),
                        Text('Chia sẻ'),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoText(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 18, color: Colors.black),
    );
  }
}
