import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isSent;
  final String avatarUrl; // URL hình đại diện

  ChatBubble({
    required this.message,
    required this.isSent,
    required this.avatarUrl, required imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isSent)
          CircleAvatar(
            radius: 20,
            backgroundImage: avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : AssetImage('assets/zalo.png') as ImageProvider,
          ),
        if (!isSent) SizedBox(width: 8),
        Flexible(
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSent ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: isSent ? Radius.circular(16) : Radius.circular(0),
                bottomRight: isSent ? Radius.circular(0) : Radius.circular(16),
              ),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: isSent ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
        if (isSent) SizedBox(width: 8),
        if (isSent)
          CircleAvatar(
            radius: 20,
            backgroundImage: avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : AssetImage('assets/default_avatar.png') as ImageProvider,
          ),
      ],
    );
  }
}
