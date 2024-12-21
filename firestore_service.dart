import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Lưu thông tin người dùng vào Firestore
  Future<void> saveUserToFirestore(User user) async {
    try {
      DocumentSnapshot userDoc = await _db.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        await _db.collection('users').doc(user.uid).set({
          'name': user.displayName ?? 'No Name',
          'email': user.email,
          'photoURL': user.photoURL,
          'friendCount': 0,
          'followerCount': 0,
          'friends': [],
          'followers': [],
          'following': [],
        });
      }
    } catch (e) {
      print("Error saving user to Firestore: $e");
    }
  }

  /// Thêm bạn bè
  Future<void> addFriend(String userId, String friendId) async {
    try {
      WriteBatch batch = _db.batch();

      // Thêm bạn vào danh sách của người dùng hiện tại
      batch.update(_db.collection('users').doc(userId), {
        'friends': FieldValue.arrayUnion([friendId]),
        'friendCount': FieldValue.increment(1),
      });

      // Thêm người dùng hiện tại vào danh sách bạn của người kia
      batch.update(_db.collection('users').doc(friendId), {
        'friends': FieldValue.arrayUnion([userId]),
        'friendCount': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      print("Error adding friend: $e");
    }
  }

  /// Theo dõi người dùng
  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      WriteBatch batch = _db.batch();

      // Cập nhật danh sách người đang theo dõi
      batch.update(_db.collection('users').doc(currentUserId), {
        'following': FieldValue.arrayUnion([targetUserId]),
      });

      // Cập nhật danh sách người theo dõi của mục tiêu
      batch.update(_db.collection('users').doc(targetUserId), {
        'followers': FieldValue.arrayUnion([currentUserId]),
        'followerCount': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      print("Error following user: $e");
    }
  }

  /// Hủy theo dõi người dùng
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      WriteBatch batch = _db.batch();

      // Xóa khỏi danh sách người đang theo dõi
      batch.update(_db.collection('users').doc(currentUserId), {
        'following': FieldValue.arrayRemove([targetUserId]),
      });

      // Xóa khỏi danh sách người theo dõi của mục tiêu
      batch.update(_db.collection('users').doc(targetUserId), {
        'followers': FieldValue.arrayRemove([currentUserId]),
        'followerCount': FieldValue.increment(-1),
      });

      await batch.commit();
    } catch (e) {
      print("Error unfollowing user: $e");
    }
  }

  /// Kiểm tra xem hai người có là bạn bè không
  Future<bool> isFriend(String userId, String friendId) async {
    try {
      DocumentSnapshot userDoc = await _db.collection('users').doc(userId).get();
      List friends = userDoc['friends'] ?? [];
      return friends.contains(friendId);
    } catch (e) {
      print("Error checking friendship: $e");
      return false;
    }
  }

  /// Kiểm tra xem người dùng có đang theo dõi mục tiêu không
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      DocumentSnapshot userDoc = await _db.collection('users').doc(currentUserId).get();
      List following = userDoc['following'] ?? [];
      return following.contains(targetUserId);
    } catch (e) {
      print("Error checking following status: $e");
      return false;
    }
  }
}
