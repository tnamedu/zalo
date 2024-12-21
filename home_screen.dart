import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zalo_social_clone/models/post_model.dart';
import 'package:zalo_social_clone/widget/post_widget.dart';
import 'create_post_screen.dart'; // Màn hình tạo bài viết
import 'user_profile_screen.dart'; // Màn hình hồ sơ người dùng

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  bool _isSearching = false;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> searchUser(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: query)
          .get();

      if (result.docs.isEmpty) {
        DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(query).get();
        if (userDoc.exists) {
          setState(() {
            _searchResults = [userDoc];
          });
        }
      } else {
        setState(() {
          _searchResults = result.docs;
        });
      }
    } catch (e) {
      print("Error searching user: $e");
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Trang chủ'),
        centerTitle: true,
        backgroundColor: Colors.cyanAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.create),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreatePostScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Tìm kiếm người dùng',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    searchUser(_searchController.text.trim());
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: _isSearching
                ? Center(child: CircularProgressIndicator())
                : _searchResults.isNotEmpty
                ? _buildSearchResults()
                : _buildPostFeed(),
          ),
        ],
      ),
    );
  }

  Widget _buildPostFeed() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs;

        if (posts.isEmpty) {
          return Center(child: Text("Không có bài đăng nào!"));
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            var postData = posts[index];
            PostModel post = PostModel.fromMap(postData);

            return PostWidget(
              postId: post.postId,
              userId: post.userId,
              content: post.content,
              imageUrl: post.imageUrl,
              likes: post.likes,
              timestamp: post.timestamp,
              onDelete: () async {
                await FirebaseFirestore.instance
                    .collection('posts')
                    .doc(post.postId)
                    .delete();

                await FirebaseFirestore.instance
                    .collection('user_posts')
                    .doc(post.userId)
                    .collection('posts')
                    .doc(post.postId)
                    .delete();
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        var user = _searchResults[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(
              user['photoURL'] ?? 'https://via.placeholder.com/150',
            ),
          ),
          title: Text(user['name']),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(
                  user: user,
                  currentUserId: currentUserId,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
