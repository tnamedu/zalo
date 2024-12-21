import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String userId;
  final String content;
  final String imageUrl;
  final int likes;
  final Timestamp timestamp;

  PostModel({
    required this.postId,
    required this.userId,
    required this.content,
    required this.imageUrl,
    required this.likes,
    required this.timestamp,
  });

  // Chuyển đổi từ Map sang PostModel
  factory PostModel.fromMap(DocumentSnapshot data) {
    return PostModel(
      postId: data.id,
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      likes: data['likes'] ?? 0,
      timestamp: data['timestamp'] ?? Timestamp.now(),  // Giữ nguyên Timestamp
    );
  }

  // Chuyển đổi PostModel sang Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'content': content,
      'imageUrl': imageUrl,
      'likes': likes,
      'timestamp': timestamp,  // Lưu nguyên Timestamp vào Firestore
    };
  }
}
