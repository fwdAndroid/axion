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
  final TextEditingController _replyController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _showEmojiPicker = false;
  String? _replyingToCommentId;
  String? _replyingToUsername;
  bool _isReplying = false;

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final String commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    final String commentId = const Uuid().v4();
    final String userId = _auth.currentUser!.uid;
    final String username = _auth.currentUser!.displayName ?? 'Anonymous';
    final DateTime now = DateTime.now();

    try {
      final docRef = _firestore
          .collection('communitiesPost')
          .doc(widget.postId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post not found')));
        return;
      }

      if (!docSnapshot.data()!.containsKey('comment')) {
        await docRef.set({'comment': []}, SetOptions(merge: true));
      }

      await docRef.update({
        'comment': FieldValue.arrayUnion([
          {
            'id': commentId,
            'userId': userId,
            'username': username,
            'text': commentText,
            'createdAt': now,
            'likes': [],
            'replies': [],
            'isReply': false,
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

  Future<void> _addReply() async {
    final String replyText = _replyController.text.trim();
    if (replyText.isEmpty || _replyingToCommentId == null) return;

    final String replyId = const Uuid().v4();
    final String userId = _auth.currentUser!.uid;
    final String username = _auth.currentUser!.displayName ?? 'Anonymous';
    final DateTime now = DateTime.now();

    try {
      final docRef = _firestore
          .collection('communitiesPost')
          .doc(widget.postId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post not found')));
        return;
      }

      final List<dynamic> comments = docSnapshot.data()?['comment'] ?? [];
      final commentIndex = comments.indexWhere(
        (c) => c['id'] == _replyingToCommentId,
      );

      if (commentIndex == -1) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comment not found')));
        return;
      }

      final updatedComment = Map<String, dynamic>.from(comments[commentIndex]);
      final List<dynamic> replies = List.from(updatedComment['replies'] ?? []);

      replies.add({
        'id': replyId,
        'userId': userId,
        'username': username,
        'text': replyText,
        'createdAt': now,
        'likes': [],
        'isReply': true,
        'parentCommentId': _replyingToCommentId,
        'replyingTo': _replyingToUsername,
      });

      updatedComment['replies'] = replies;

      // Update the comment with new replies
      await docRef.update({
        'comment': FieldValue.arrayRemove([comments[commentIndex]]),
      });
      await docRef.update({
        'comment': FieldValue.arrayUnion([updatedComment]),
      });

      _replyController.clear();
      setState(() {
        _isReplying = false;
        _replyingToCommentId = null;
        _replyingToUsername = null;
        _showEmojiPicker = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add reply: $e')));
    }
  }

  void _startReply(String commentId, String username) {
    setState(() {
      _isReplying = true;
      _replyingToCommentId = commentId;
      _replyingToUsername = username;
    });
    FocusScope.of(context).requestFocus(FocusNode());
    Future.delayed(const Duration(milliseconds: 300), () {
      FocusScope.of(context).requestFocus(FocusNode());
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  void _cancelReply() {
    setState(() {
      _isReplying = false;
      _replyingToCommentId = null;
      _replyingToUsername = null;
      _replyController.clear();
    });
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
                  return const Center(child: Text('Post not found or deleted'));
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
                    final replies = comment['replies'] as List<dynamic>? ?? [];
                    return Column(
                      children: [
                        CommentTile(
                          comment: comment,
                          currentUserId: _auth.currentUser?.uid,
                          onDelete: () => _deleteComment(comment['id']),
                          onLike:
                              () => _toggleLike(
                                comment['id'],
                                _auth.currentUser!.uid,
                                false,
                              ),
                          onReply:
                              () => _startReply(
                                comment['id'],
                                comment['username'],
                              ),
                          isReply: false,
                        ),
                        if (replies.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Column(
                              children:
                                  replies
                                      .map(
                                        (reply) => CommentTile(
                                          comment: reply,
                                          currentUserId: _auth.currentUser?.uid,
                                          onDelete:
                                              () => _deleteReply(
                                                comment['id'],
                                                reply['id'],
                                              ),
                                          onLike:
                                              () => _toggleLike(
                                                reply['id'],
                                                _auth.currentUser!.uid,
                                                true,
                                                comment['id'],
                                              ),
                                          onReply:
                                              () => _startReply(
                                                comment['id'],
                                                reply['username'],
                                              ),
                                          isReply: true,
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (_isReplying) _buildReplyInput(),
          _buildCommentInput(),
          if (_showEmojiPicker)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  if (_isReplying) {
                    _replyController.text = _replyController.text + emoji.emoji;
                  } else {
                    _commentController.text =
                        _commentController.text + emoji.emoji;
                  }
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

  Widget _buildReplyInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Replying to $_replyingToUsername',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Spacer(),
              TextButton(onPressed: _cancelReply, child: const Text('Cancel')),
            ],
          ),
          Row(
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
                  controller: _replyController,
                  decoration: const InputDecoration(
                    hintText: 'Write a reply...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: _addReply),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      final docRef = _firestore
          .collection('communitiesPost')
          .doc(widget.postId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post not found')));
        return;
      }

      final List<dynamic> comments = docSnapshot.data()?['comment'] ?? [];

      // Find the comment to remove
      final commentToRemove = comments.firstWhere(
        (comment) => comment['id'] == commentId,
      );

      // Remove the comment from the array
      await docRef.update({
        'comment': FieldValue.arrayRemove([commentToRemove]),
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete comment: $e')));
    }
  }

  Future<void> _deleteReply(String parentCommentId, String replyId) async {
    try {
      final docRef = _firestore
          .collection('communitiesPost')
          .doc(widget.postId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post not found')));
        return;
      }

      final List<dynamic> comments = docSnapshot.data()?['comment'] ?? [];
      final commentIndex = comments.indexWhere(
        (c) => c['id'] == parentCommentId,
      );

      if (commentIndex == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parent comment not found')),
        );
        return;
      }

      final updatedComment = Map<String, dynamic>.from(comments[commentIndex]);
      final List<dynamic> replies = List.from(updatedComment['replies'] ?? []);
      final replyIndex = replies.indexWhere((r) => r['id'] == replyId);

      if (replyIndex == -1) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reply not found')));
        return;
      }

      replies.removeAt(replyIndex);
      updatedComment['replies'] = replies;

      // Update the comment with removed reply
      await docRef.update({
        'comment': FieldValue.arrayRemove([comments[commentIndex]]),
      });
      await docRef.update({
        'comment': FieldValue.arrayUnion([updatedComment]),
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete reply: $e')));
    }
  }

  Future<void> _toggleLike(
    String commentId,
    String userId,
    bool isReply, [
    String? parentCommentId,
  ]) async {
    try {
      final docRef = _firestore
          .collection('communitiesPost')
          .doc(widget.postId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post not found')));
        return;
      }

      final List<dynamic> comments = docSnapshot.data()?['comments'] ?? [];

      if (isReply && parentCommentId != null) {
        // Handle reply like
        final commentIndex = comments.indexWhere(
          (c) => c['id'] == parentCommentId,
        );
        if (commentIndex == -1) return;

        final updatedComment = Map<String, dynamic>.from(
          comments[commentIndex],
        );
        final List<dynamic> replies = List.from(
          updatedComment['replies'] ?? [],
        );
        final replyIndex = replies.indexWhere((r) => r['id'] == commentId);
        if (replyIndex == -1) return;

        final reply = replies[replyIndex];
        final List<dynamic> likes = List.from(reply['likes'] ?? []);

        if (likes.contains(userId)) {
          likes.remove(userId);
        } else {
          likes.add(userId);
        }

        replies[replyIndex] = {...reply, 'likes': likes};

        updatedComment['replies'] = replies;

        // Update the comment with updated reply
        await docRef.update({
          'comment': FieldValue.arrayRemove([comments[commentIndex]]),
        });
        await docRef.update({
          'comment': FieldValue.arrayUnion([updatedComment]),
        });
      } else {
        // Handle comment like
        final commentIndex = comments.indexWhere((c) => c['id'] == commentId);
        if (commentIndex == -1) return;

        final comment = comments[commentIndex];
        final List<dynamic> likes = List.from(comment['likes'] ?? []);

        if (likes.contains(userId)) {
          likes.remove(userId);
        } else {
          likes.add(userId);
        }

        final updatedComment = {...comment, 'likes': likes};

        // Update the comment in the array
        await docRef.update({
          'comment': FieldValue.arrayRemove([comments[commentIndex]]),
        });
        await docRef.update({
          'comment': FieldValue.arrayUnion([updatedComment]),
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to like: $e')));
    }
  }
}

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
