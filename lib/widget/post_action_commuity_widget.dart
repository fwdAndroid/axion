import 'package:axion/screen/communities/view_community_comment.dart';
import 'package:axion/services/database.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class PostActionsWidgetCommuity extends StatelessWidget {
  final String postId;
  final int likeCount;
  final bool isLiked;
  final List likes;
  final String mediaUrl;
  final String currentUserId;
  final String? currentUserName;
  final String? currentUserImage;
  final Map<String, dynamic> post;
  final Database _database;
  PostActionsWidgetCommuity({
    super.key,
    required this.postId,
    required this.likeCount,
    required this.isLiked,
    required this.likes,
    required this.mediaUrl,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserImage,
    required this.post,
    required Database database,
  }) : _database = database;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              _database.toggleLikeCommunity(postId, likes);
            },
            child: Column(
              children: [
                Icon(
                  isLiked ? Icons.thumb_up : Icons.thumb_up,
                  color: isLiked ? Colors.green : Colors.grey,
                ),
                Text(
                  'Like ($likeCount)',
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewCommunityComment(postId: postId),
                ),
              );
            },
            child: const Column(
              children: [
                Icon(Icons.chat_bubble, color: Colors.grey),
                Text('Comment', style: TextStyle(color: Colors.black)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              String shareText =
                  "${post['titleName'] ?? 'Untitled Post'}\n\n${post['description'] ?? 'No description'}\n";
              if (mediaUrl.isNotEmpty) {
                shareText += "\nCheck out this media: $mediaUrl";
              }

              await Share.share(
                shareText,
                subject: post['titleName'] ?? "Social Post",
              );
            },
            child: const Column(
              children: [
                Icon(Icons.share, color: Colors.grey),
                Text('Share', style: TextStyle(color: Colors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
