import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ChatRoom.dart'; // Import màn hình ChatRoom
import 'package:zalo_social_clone/models/chat_model.dart'; // Import ChatPreview

class MessagesScreen extends StatefulWidget {
  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String? currentUserId;
  Map<String, Map<String, dynamic>> userCache = {};

  @override
  void initState() {
    super.initState();
    _initializeCurrentUser();
  }

  // Lấy user hiện tại
  void _initializeCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
      _preloadUserCache();
    } else {
      print("Người dùng chưa đăng nhập.");
    }
  }

  // Tải thông tin người dùng và lưu vào cache
  void _preloadUserCache() async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      for (var doc in usersSnapshot.docs) {
        userCache[doc.id] = {
          'username': doc.data()['username'] ?? 'Baoan',
          'photoURL': doc.data()['photoURL'] ?? '',
        };
      }
      setState(() {});
    } catch (e) {
      print("Lỗi khi tải thông tin người dùng: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return Scaffold(
        body: Center(child: Text("Bạn cần đăng nhập để xem tin nhắn.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Tin nhắn"),
        centerTitle: true,
        backgroundColor: Colors.cyanAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _showFriendsList,
          ),
        ],
      ),
      body: StreamBuilder<List<ChatPreview>>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: currentUserId)
            .snapshots()
            .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ChatPreview.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          }).toList();
        }),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Đã xảy ra lỗi khi tải tin nhắn."));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Không có tin nhắn nào."));
          }

          final chats = snapshot.data!;
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatPreview = chats[index];
              return _buildChatTile(chatPreview);
            },
          );
        },
      ),
    );
  }

  Widget _buildChatTile(ChatPreview chatPreview) {
    String otherUserId = chatPreview.users.firstWhere((id) => id != currentUserId);

    return Dismissible(
      key: Key(chatPreview.chatId),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) async {
        final chatData = await FirebaseFirestore.instance.collection('chats').doc(chatPreview.chatId).get();
        await FirebaseFirestore.instance.collection('chats').doc(chatPreview.chatId).delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Cuộc trò chuyện đã bị xóa."),
            action: SnackBarAction(
              label: 'Hoàn tác',
              onPressed: () async {
                await FirebaseFirestore.instance.collection('chats').doc(chatPreview.chatId).set(chatData.data()!);
              },
            ),
          ),
        );
      },
      background: Container(
        color: Colors.cyanAccent,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Icon(Icons.delete, color: Colors.white),
          ),
        ),
      ),
      child: _buildUserTile(otherUserId, chatPreview.lastMessage, chatPreview.lastTimestamp, chatPreview.chatId),
    );
  }

  Widget _buildUserTile(String userId, String lastMessage, DateTime? lastTimestamp, String chatId) {
    if (userCache.containsKey(userId)) {
      return _buildUserTileContent(userCache[userId]!, userId, lastMessage, lastTimestamp, chatId);
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(title: Text("Đang tải..."));
        }

        if (!snapshot.hasData || !(snapshot.data?.exists ?? false)) {
          return ListTile(title: Text("Người dùng không tồn tại"));
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        userCache[userId] = {
          'username': userData['username'] ?? 'BaoAn',
          'photoURL': userData['photoURL'] ?? '',
        };

        return _buildUserTileContent(userCache[userId]!, userId, lastMessage, lastTimestamp, chatId);
      },
    );
  }

  Widget _buildUserTileContent(Map<String, dynamic> userData, String userId, String lastMessage, DateTime? lastTimestamp, String chatId) {
    String receiverName = userData['username'];
    String avatarUrl = userData['photoURL'];

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
        backgroundColor: Colors.grey,
        child: avatarUrl.isEmpty ? Icon(Icons.person, color: Colors.white) : null,
      ),
      title: Text(receiverName),
      subtitle: Text(lastMessage.isNotEmpty ? lastMessage : "Chưa có tin nhắn nào"),
      trailing: Text(
        _formatTimestamp(lastTimestamp),
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagesDetailScreen(

              receiverId: userId,
              receiverName: receiverName,
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 60) {
      return "${difference.inMinutes} phút trước";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} giờ trước";
    } else {
      return "${timestamp.day}/${timestamp.month}/${timestamp.year}";
    }
  }

  void _showFriendsList() async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      final friends = List<String>.from(userDoc['friends'] ?? []);

      if (friends.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bạn chưa có bạn bè để nhắn tin.")),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        builder: (context) {
          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friendId = friends[index];
              return _buildFriendTile(friendId);
            },
          );
        },
      );
    } catch (e) {
      print("Lỗi khi lấy danh sách bạn bè: $e");
    }
  }

  Widget _buildFriendTile(String friendId) {
    if (userCache.containsKey(friendId)) {
      return _buildFriendTileContent(userCache[friendId]!, friendId);
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(friendId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(title: Text("Đang tải..."));
        }

        if (!snapshot.hasData || !(snapshot.data?.exists ?? false)) {
          return ListTile(title: Text("Người dùng không tồn tại"));
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        userCache[friendId] = {
          'username': userData['username'] ?? 'Baoan',
          'photoURL': userData['photoURL'] ?? '',
        };

        return _buildFriendTileContent(userCache[friendId]!, friendId);
      },
    );
  }

  Widget _buildFriendTileContent(Map<String, dynamic> userData, String friendId) {
    String friendName = userData['username'];
    String avatarUrl = userData['photoURL'];

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
        backgroundColor: Colors.grey,
        child: avatarUrl.isEmpty ? Icon(Icons.person, color: Colors.white) : null,
      ),
      title: Text(friendName),
      onTap: () {
        Navigator.pop(context); // Đóng danh sách bạn bè
        _startNewChat(friendId, friendName);
      },
    );
  }

  void _startNewChat(String friendId, String friendName) async {
    final chatQuery = await FirebaseFirestore.instance
        .collection('chats')
        .where('users', arrayContains: currentUserId)
        .get();

    String? existingChatId;
    for (var doc in chatQuery.docs) {
      final users = List<String>.from(doc['users']);
      if (users.contains(friendId)) {
        existingChatId = doc.id;
        break;
      }
    }

    if (existingChatId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagesDetailScreen(

            receiverId: friendId,
            receiverName: friendName,
          ),
        ),
      );
    } else {

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagesDetailScreen(

            receiverId: friendId,
            receiverName: friendName,
          ),
        ),
      );
    }
  }
}
