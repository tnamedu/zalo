class Message {
  final String senderId;
  final String receiverId;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;

  Message({
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.imageUrl,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static Message fromMap(Map<String, dynamic> map) {
    return Message(
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      content: map['content'],
      imageUrl: map['imageUrl'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
