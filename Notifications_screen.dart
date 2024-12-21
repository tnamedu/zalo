import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatelessWidget {
  final String currentUserId;

  NotificationsScreen({required this.currentUserId});

  Future<void> respondToFriendRequest(String requestId, bool accept) async {
    try {
      DocumentSnapshot request = await FirebaseFirestore.instance
          .collection('friend_requests')
          .doc(requestId)
          .get();

      if (accept) {
        String fromUserId = request['from'];

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({
          'friends': FieldValue.arrayUnion([fromUserId]),
          'friendCount': FieldValue.increment(1),
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(fromUserId)
            .update({
          'friends': FieldValue.arrayUnion([currentUserId]),
          'friendCount': FieldValue.increment(1),
        });
      }

      await FirebaseFirestore.instance
          .collection('friend_requests')
          .doc(requestId)
          .delete();
    } catch (e) {
      print("Error in respondToFriendRequest: $e");
    }
  }

  Future<String> getUserName(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return userDoc['name'] ?? 'Unknown User';
    } catch (e) {
      print("Error in getUserName: $e");
      return 'Unknown User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Thông báo'),
        centerTitle: true,
        backgroundColor: Colors.cyanAccent,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('friend_requests')
            .where('to', isEqualTo: currentUserId)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("Error in StreamBuilder: ${snapshot.error}");
            return Center(child: Text("Đã xảy ra lỗi khi tải dữ liệu"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Không có yêu cầu kết bạn nào"));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return FutureBuilder(
                future: getUserName(doc['from']),
                builder: (context, AsyncSnapshot<String> userNameSnapshot) {
                  if (userNameSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return ListTile(
                      title: Text("Đang tải tên người dùng..."),
                    );
                  }

                  if (userNameSnapshot.hasError) {
                    print("Error in FutureBuilder: ${userNameSnapshot.error}");
                    return ListTile(
                      title: Text("Lỗi khi tải tên người dùng"),
                    );
                  }

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.cyanAccent,
                                child: Text(
                                  userNameSnapshot.data![0].toUpperCase(),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Yêu cầu kết bạn từ ${userNameSnapshot.data}',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () => respondToFriendRequest(doc.id, true),
                                child: Text('Chấp nhận'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.black,
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                ),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () => respondToFriendRequest(doc.id, false),
                                child: Text('Xóa'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
