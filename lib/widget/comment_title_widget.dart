import 'dart:ui';

import 'package:flutter/material.dart';

class CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;
  final String? currentUserId;
  final VoidCallback onDelete;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final bool isReply;

  const CommentTile({
    super.key,
    required this.comment,
    this.currentUserId,
    required this.onDelete,
    required this.onLike,
    required this.onReply,
    required this.isReply,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = comment['userId'] == currentUserId;
    final likes = List<String>.from(comment['likes'] ?? []);
    final isLiked = likes.contains(currentUserId);
    final username = comment['username'] ?? 'Anonymous';
    final replyingTo = comment['replyingTo'];

    return Container(
      decoration: BoxDecoration(
        border:
            isReply
                ? Border(left: BorderSide(color: Colors.grey[300]!, width: 2.0))
                : null,
      ),
      child: ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isReply && replyingTo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  'Replying to $replyingTo',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            Text(comment['text']),
          ],
        ),
        subtitle: Text(
          '$username • ${_formatDate(comment['createdAt']?.toDate())}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : null,
                size: 20,
              ),
              onPressed: onLike,
            ),
            if (likes.isNotEmpty)
              Text('${likes.length}', style: const TextStyle(fontSize: 12)),
            IconButton(
              icon: const Icon(Icons.reply, size: 20),
              onPressed: onReply,
            ),
            if (isCurrentUser)
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')} • ${date.day}/${date.month}/${date.year}';
  }
}
