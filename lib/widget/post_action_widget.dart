import 'package:axion/screen/main/chat/chat_detail_page.dart';
import 'package:axion/screen/main/comment/comment.dart';
import 'package:axion/services/database.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

class PostActionsWidget extends StatelessWidget {
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

  const PostActionsWidget({
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () {
              _database.toggleLike(postId, likes);
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
                  builder: (context) => ViewComment(postId: postId),
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
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (context) =>
                          const Center(child: CircularProgressIndicator()),
                );

                final friendDoc =
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(post['uid'])
                        .get();

                if (!friendDoc.exists) {
                  throw Exception('Friend profile not found');
                }
                if (currentUserName == null) {
                  throw Exception('Your profile not loaded');
                }

                final chatId = await _database.createChatDocument(
                  currentUserId: currentUserId,
                  currentUserName: currentUserName!,
                  currentUserPhoto: currentUserImage,
                  friendId: post['uid'],
                  friendName: friendDoc['fullName'] ?? 'Unknown',
                  friendPhoto: friendDoc['image'],
                );

                if (context.mounted) Navigator.of(context).pop();

                if (chatId == null) {
                  throw Exception('Failed to create chat');
                }

                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ChatDetailPage(
                            chatId: chatId,
                            currentUserId: currentUserId,
                            friendId: post['uid'],
                            friendName: friendDoc['fullName'] ?? 'Unknown',
                            friendImage: friendDoc['image'],
                          ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) Navigator.of(context).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to start chat: ${e.toString()}'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: const Column(
              children: [
                Icon(Icons.chat_rounded, color: Colors.grey),
                Text('Chat', style: TextStyle(color: Colors.black)),
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
