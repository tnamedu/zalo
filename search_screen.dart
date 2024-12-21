import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchScreen extends StatefulWidget {
  final String currentUserId; // ID của người dùng hiện tại

  SearchScreen({required this.currentUserId});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  bool _isLoading = false;

  // Hàm tìm kiếm người dùng
  Future<void> _searchUser(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _searchResults = [];
    });

    try {
      // Tìm kiếm theo tên
      final QuerySnapshot resultByName = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      if (resultByName.docs.isNotEmpty) {
        setState(() {
          _searchResults = resultByName.docs;
        });
      } else {
        // Tìm kiếm theo UID
        final DocumentSnapshot resultByUID = await FirebaseFirestore.instance
            .collection('users')
            .doc(query)
            .get();

        if (resultByUID.exists) {
          setState(() {
            _searchResults = [resultByUID];
          });
        }
      }
    } catch (e) {
      print("Error during search: $e");
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
        title: Text('Tìm kiếm bạn bè'),
        backgroundColor: Colors.cyanAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Ô tìm kiếm
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Nhập tên hoặc UID người dùng',
                  hintText: 'Tìm kiếm...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.cyanAccent, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search, color: Colors.cyanAccent),
                    onPressed: () => _searchUser(_searchController.text),
                  ),
                ),
              ),
            ),

            // Hiển thị kết quả tìm kiếm
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                  ? Center(child: Text('Không tìm thấy người dùng nào'))
                  : ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  final userData = user.data() as Map<String, dynamic>?;

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 16.0),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(
                          userData != null &&
                              userData.containsKey('photoURL') &&
                              userData['photoURL'] != null
                              ? userData['photoURL']
                              : 'https://via.placeholder.com/150',
                        ),
                      ),
                      title: Text(
                        userData?['name'] ?? 'Không có tên',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('UID: ${user.id}',
                          style: TextStyle(color: Colors.grey)),
                      trailing: IconButton(
                        icon: Icon(Icons.chat, color: Colors.cyanAccent),
                        onPressed: () {
                          // Điều hướng đến màn hình chat
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                currentUserId: widget.currentUserId,
                                otherUserId: user.id,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  final String currentUserId;
  final String otherUserId;

  ChatScreen({required this.currentUserId, required this.otherUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat với $otherUserId"),
      ),
      body: Center(
        child: Text('Màn hình chat với người dùng $otherUserId'),
      ),
    );
  }
}
