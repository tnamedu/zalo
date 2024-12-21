import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPreview {
  final String chatId; // ID của document Firestore
  final String lastMessage; // Tin nhắn cuối cùng
  final DateTime? lastTimestamp; // Thời gian tin nhắn cuối cùng
  final List<String> users; // Danh sách người dùng trong cuộc trò chuyện

  ChatPreview({
    required this.chatId,
    required this.lastMessage,
    this.lastTimestamp,
    required this.users,
  });

  /// Tạo một đối tượng ChatPreview từ dữ liệu Firestore
  factory ChatPreview.fromMap(String id, Map<String, dynamic> data) {
    return ChatPreview(
      chatId: id, // Sử dụng ID của document làm chatId
      lastMessage: data['lastMessage'] ?? '', // Lấy lastMessage hoặc gán chuỗi rỗng
      lastTimestamp: (data['lastTimestamp'] as Timestamp?)?.toDate(), // Chuyển đổi Timestamp sang DateTime
      users: List<String>.from(data['users'] ?? []), // Chuyển đổi users thành List<String>
    );
  }

  /// Chuyển đổi ChatPreview thành Map để lưu vào Firestore (nếu cần)
  Map<String, dynamic> toMap() {
    return {
      'lastMessage': lastMessage,
      'lastTimestamp': lastTimestamp,
      'users': users,
    };
  }
}
