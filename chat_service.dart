import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zalo_social_clone/models/chat_model.dart';
import 'package:zalo_social_clone/models/chat.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tạo chatId duy nhất dựa trên UID của 2 người dùng
  String getChatId(String user1, String user2) {
    return (user1.compareTo(user2) < 0) ? '$user1-$user2' : '$user2-$user1';
  }

  /// Gửi tin nhắn và cập nhật thông tin cuộc trò chuyện
  Future<void> sendMessage(
      String senderId, String receiverId, String message, {required String imageUrl}) async {
    try {
      String chatId = getChatId(senderId, receiverId);

      Message newMessage = Message(
        senderId: senderId,
        receiverId: receiverId,
        message: message,
        timestamp: DateTime.now(),
      );

      // Thêm tin nhắn vào subcollection "messages"
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(newMessage.toMap());

      // Cập nhật thông tin cuộc trò chuyện
      await _firestore.collection('chats').doc(chatId).set({
        'lastMessage': message,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'users': [senderId, receiverId],
      }, SetOptions(merge: true));

      print("Message sent successfully");
    } catch (e) {
      print("Error sending message: $e");
      rethrow;
    }
  }

  /// Lấy danh sách tin nhắn trong một cuộc trò chuyện
  Stream<List<Message>> getMessages(String senderId, String receiverId,
      {int limit = 20}) {
    try {
      String chatId = getChatId(senderId, receiverId);

      return _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) =>
          snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList());
    } catch (e) {
      print("Error fetching messages: $e");
      rethrow;
    }
  }

  /// Lấy danh sách cuộc trò chuyện của user hiện tại
  Stream<List<ChatPreview>> getUserChats(String currentUserId) {
    try {
      return _firestore
          .collection('chats')
          .where('users', arrayContains: currentUserId)
          .orderBy('lastTimestamp', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;

        return ChatPreview(
          chatId: doc.id,
          lastMessage: data['lastMessage'] ?? '',
          lastTimestamp:
          (data['lastTimestamp'] as Timestamp?)?.toDate(),
          users: List<String>.from(data['users'] ?? []),
        );
      }).toList());
    } catch (e) {
      print("Error fetching user chats: $e");
      rethrow;
    }
  }

  /// Xóa tin nhắn cụ thể (chỉ cho phép người gửi xóa)
  Future<void> deleteMessage(
      String senderId, String receiverId, String messageId) async {
    try {
      String chatId = getChatId(senderId, receiverId);

      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);

      final messageSnapshot = await messageRef.get();

      if (messageSnapshot.exists &&
          messageSnapshot.data()?['senderId'] == senderId) {
        await messageRef.delete();
        print("Message deleted successfully");
      } else {
        print("Permission denied: Cannot delete the message.");
      }
    } catch (e) {
      print("Error deleting message: $e");
      rethrow;
    }
  }

  /// Tạo cuộc trò chuyện mới nếu chưa tồn tại
  Future<void> createChatIfNotExists(String user1, String user2) async {
    try {
      String chatId = getChatId(user1, user2);

      var chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        await _firestore.collection('chats').doc(chatId).set({
          'users': [user1, user2],
          'lastMessage': '',
          'lastTimestamp': FieldValue.serverTimestamp(),
        });
        print("Chat created successfully");
      }
    } catch (e) {
      print("Error creating chat: $e");
      rethrow;
    }
  }
}
