import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ViewCommunityComment extends StatefulWidget {
  final String postId;
  const ViewCommunityComment({super.key, required this.postId});

  @override
  State<ViewCommunityComment> createState() => _ViewCommunityCommentState();
}

class _ViewCommunityCommentState extends State<ViewCommunityComment> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _showEmojiPicker = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final String commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    final String commentId = const Uuid().v4();
    final String userId = _auth.currentUser!.uid;
    final DateTime now = DateTime.now();

    try {
      // Add comment to the post's comments array
      await _firestore.collection('communitiesPost').doc(widget.postId).update({
        'comment': FieldValue.arrayUnion([
          {
            'id': commentId,
            'userId': userId,
            'text': commentText,
            'createdAt': now,
            'likes': [],
          },
        ]),
      });

      _commentController.clear();
      setState(() {
        _showEmojiPicker = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add comment: $e')));
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      // First get the current comments
      final doc =
          await _firestore
              .collection('communitiesPost')
              .doc(widget.postId)
              .get();
      final List<dynamic> comments = doc.data()?['comment'] ?? [];

      // Find the comment to remove
      final commentToRemove = comments.firstWhere(
        (comment) => comment['id'] == commentId,
      );

      // Remove the comment from the array
      await _firestore.collection('communitiesPost').doc(widget.postId).update({
        'comment': FieldValue.arrayRemove([commentToRemove]),
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete comment: $e')));
    }
  }

  Future<void> _toggleLike(String commentId, String userId) async {
    try {
      final doc =
          await _firestore
              .collection('communitiesPost')
              .doc(widget.postId)
              .get();
      final List<dynamic> comments = doc.data()?['comment'] ?? [];

      // Find the comment
      final comment = comments.firstWhere((c) => c['id'] == commentId);

      final List<dynamic> likes = List.from(comment['likes'] ?? []);

      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }

      // Create a new comment with updated likes
      final updatedComment = {...comment, 'likes': likes};

      // Update the comment in the array
      await _firestore.collection('communitiesPost').doc(widget.postId).update({
        'comment': FieldValue.arrayRemove([comment]),
      });
      await _firestore.collection('communitiesPost').doc(widget.postId).update({
        'comment': FieldValue.arrayUnion([updatedComment]),
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to like comment: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Comments")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream:
                  _firestore
                      .collection('communitiesPost')
                      .doc(widget.postId)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Post not found'));
                }

                final postData = snapshot.data!.data() as Map<String, dynamic>;
                final comments = postData['comment'] as List<dynamic>? ?? [];

                if (comments.isEmpty) {
                  return const Center(child: Text('No comments yet'));
                }

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return CommentTile(
                      comment: comment,
                      currentUserId: _auth.currentUser?.uid,
                      onDelete: () => _deleteComment(comment['id']),
                      onLike:
                          () => _toggleLike(
                            comment['id'],
                            _auth.currentUser!.uid,
                          ),
                    );
                  },
                );
              },
            ),
          ),
          _buildCommentInput(),
          if (_showEmojiPicker)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _commentController.text =
                      _commentController.text + emoji.emoji;
                },
                config: const Config(height: 32.0),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.emoji_emotions),
            onPressed: () {
              setState(() {
                _showEmojiPicker = !_showEmojiPicker;
              });
            },
          ),
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Write a comment...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.send), onPressed: _addComment),
        ],
      ),
    );
  }
}

class CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;
  final String? currentUserId;
  final VoidCallback onDelete;
  final VoidCallback onLike;

  const CommentTile({
    super.key,
    required this.comment,
    this.currentUserId,
    required this.onDelete,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = comment['userId'] == currentUserId;
    final likes = List<String>.from(comment['likes'] ?? []);
    final isLiked = likes.contains(currentUserId);

    return ListTile(
      title: Text(comment['text']),
      subtitle: Text(
        '${comment['userId']} • ${_formatDate(comment['createdAt']?.toDate())}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : null,
            ),
            onPressed: onLike,
          ),
          if (likes.isNotEmpty) Text('${likes.length}'),
          if (isCurrentUser)
            IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.hour}:${date.minute} • ${date.day}/${date.month}/${date.year}';
  }
}
