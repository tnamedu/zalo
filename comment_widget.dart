import 'package:flutter/material.dart';

class CommentWidget extends StatelessWidget {
  final String userName;
  final String content;
  final DateTime timestamp;
  final VoidCallback? onDelete;

  CommentWidget({
    required this.userName,
    required this.content,
    required this.timestamp,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Text(
            userName,
            style: TextStyle(fontWeight: FontWeight.bold),  // In đậm tên người dùng
          ),
          SizedBox(width: 8),
          Text(
            '(${_formatDate(timestamp)})',  // Hiển thị ngày giờ bình luận
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      subtitle: Text(
        content,
        style: TextStyle(fontSize: 18),  // Tăng kích thước chữ nội dung bình luận
      ),
      trailing: onDelete != null
          ? IconButton(
        icon: Icon(Icons.delete, color: Colors.red),
        onPressed: onDelete,
      )
          : null,
    );
  }

  // Hàm định dạng ngày giờ bình luận
  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }
}
