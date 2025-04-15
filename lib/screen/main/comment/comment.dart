import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ViewComment extends StatefulWidget {
  final String postId;

  const ViewComment({super.key, required this.postId});

  @override
  State<ViewComment> createState() => _ViewCommentState();
}

class _ViewCommentState extends State<ViewComment> {
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String? currentUserName;
  String? currentUserImage;
  final _commentController = TextEditingController();
  final _replyController = TextEditingController();
  String? _editingCommentId;
  String? _replyingToCommentId;
  final _commentFocusNode = FocusNode();
  final _replyFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserDetails();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    _commentFocusNode.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentUserDetails() async {
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();
    if (userDoc.exists) {
      setState(() {
        currentUserName = userDoc['fullName'];
        currentUserImage = userDoc['image'];
      });
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final commentRef =
            FirebaseFirestore.instance
                .collection('posts')
                .doc(widget.postId)
                .collection('comments')
                .doc();

        transaction.set(commentRef, {
          'text': text,
          'userId': currentUserId,
          'userName': currentUserName,
          'userImage': currentUserImage,
          'timestamp': FieldValue.serverTimestamp(),
          'likes': [],
          'dislikes': [],
          'repliesCount': 0,
          'edited': false,
        });

        final postRef = FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId);
        transaction.update(postRef, {'commentCount': FieldValue.increment(1)});
      });

      _commentController.clear();
      _commentFocusNode.unfocus();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add comment: $e')));
    }
  }

  Future<void> _updateComment(String commentId) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .update({'text': text, 'edited': true});

      _commentController.clear();
      _commentFocusNode.unfocus();
      setState(() {
        _editingCommentId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update comment: $e')));
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final commentRef = FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(commentId);
        transaction.delete(commentRef);

        final postRef = FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId);
        transaction.update(postRef, {'commentCount': FieldValue.increment(-1)});
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete comment: $e')));
    }
  }

  Future<void> _addReply(String parentCommentId) async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final replyRef =
            FirebaseFirestore.instance
                .collection('posts')
                .doc(widget.postId)
                .collection('comments')
                .doc(parentCommentId)
                .collection('replies')
                .doc();

        transaction.set(replyRef, {
          'text': text,
          'userId': currentUserId,
          'userName': currentUserName,
          'userImage': currentUserImage,
          'timestamp': FieldValue.serverTimestamp(),
          'likes': [],
          'dislikes': [],
        });

        final commentRef = FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(parentCommentId);
        transaction.update(commentRef, {
          'repliesCount': FieldValue.increment(1),
        });
      });

      _replyController.clear();
      _replyFocusNode.unfocus();
      setState(() {
        _replyingToCommentId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add reply: $e')));
    }
  }

  Future<void> _toggleLike(
    String commentId,
    List<dynamic> currentLikes, {
    bool isReply = false,
    String? parentCommentId,
  }) async {
    try {
      DocumentReference commentRef;

      if (isReply && parentCommentId != null) {
        commentRef = FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(parentCommentId)
            .collection('replies')
            .doc(commentId);
      } else {
        commentRef = FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(commentId);
      }

      if (currentLikes.contains(currentUserId)) {
        await commentRef.update({
          'likes': FieldValue.arrayRemove([currentUserId]),
        });
      } else {
        await commentRef.update({
          'likes': FieldValue.arrayUnion([currentUserId]),
          'dislikes': FieldValue.arrayRemove([currentUserId]),
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to like comment: $e')));
    }
  }

  Future<void> _toggleDislike(
    String commentId,
    List<dynamic> currentDislikes, {
    bool isReply = false,
    String? parentCommentId,
  }) async {
    try {
      DocumentReference commentRef;

      if (isReply && parentCommentId != null) {
        commentRef = FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(parentCommentId)
            .collection('replies')
            .doc(commentId);
      } else {
        commentRef = FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(commentId);
      }

      if (currentDislikes.contains(currentUserId)) {
        await commentRef.update({
          'dislikes': FieldValue.arrayRemove([currentUserId]),
        });
      } else {
        await commentRef.update({
          'dislikes': FieldValue.arrayUnion([currentUserId]),
          'likes': FieldValue.arrayRemove([currentUserId]),
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to dislike comment: $e')));
    }
  }

  void _startEditingComment(String commentId, String text) {
    setState(() {
      _editingCommentId = commentId;
      _commentController.text = text;
      _commentFocusNode.requestFocus();
    });
  }

  void _startReplyingToComment(String commentId) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyController.clear();
      _replyFocusNode.requestFocus();
    });
  }

  Widget _buildCommentTile(
    DocumentSnapshot comment, {
    bool isReply = false,
    String? parentCommentId,
  }) {
    final data = comment.data() as Map<String, dynamic>;
    final likes = data['likes'] ?? [];
    final dislikes = data['dislikes'] ?? [];
    final isLiked = likes.contains(currentUserId);
    final isDisliked = dislikes.contains(currentUserId);
    final isOwner = data['userId'] == currentUserId;
    final timestamp = data['timestamp']?.toDate();
    final edited = data['edited'] ?? false;

    return Card(
      margin: EdgeInsets.only(
        left: isReply ? 24.0 : 8.0,
        right: 8.0,
        top: 4.0,
        bottom: 4.0,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage:
                      data['userImage'] != null
                          ? NetworkImage(data['userImage'])
                          : null,
                  child:
                      data['userImage'] == null
                          ? const Icon(Icons.person, size: 16)
                          : null,
                ),
                const SizedBox(width: 8),
                Text(
                  data['userName'] ?? 'Anonymous',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (timestamp != null)
                  Text(
                    DateFormat('MMM d, h:mm a').format(timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                if (edited)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      '(edited)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(data['text']),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.thumb_up,
                    size: 18,
                    color: isLiked ? Colors.blue : Colors.grey,
                  ),
                  onPressed:
                      () => _toggleLike(
                        comment.id,
                        likes,
                        isReply: isReply,
                        parentCommentId: parentCommentId,
                      ),
                ),
                Text('${likes.length}'),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.thumb_down,
                    size: 18,
                    color: isDisliked ? Colors.red : Colors.grey,
                  ),
                  onPressed:
                      () => _toggleDislike(
                        comment.id,
                        dislikes,
                        isReply: isReply,
                        parentCommentId: parentCommentId,
                      ),
                ),
                Text('${dislikes.length}'),
                const SizedBox(width: 8),
                if (!isReply)
                  IconButton(
                    icon: const Icon(Icons.reply, size: 18),
                    onPressed: () => _startReplyingToComment(comment.id),
                  ),
                if (isOwner && !isReply)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed:
                        () => _startEditingComment(comment.id, data['text']),
                  ),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: () => _deleteComment(comment.id),
                  ),
              ],
            ),
            if (!isReply && (data['repliesCount'] ?? 0) > 0)
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('posts')
                        .doc(widget.postId)
                        .collection('comments')
                        .doc(comment.id)
                        .collection('replies')
                        .orderBy('timestamp', descending: false)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox();
                  }

                  return Column(
                    children:
                        snapshot.data!.docs.map((reply) {
                          return _buildCommentTile(
                            reply,
                            isReply: true,
                            parentCommentId: comment.id,
                          );
                        }).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _commentController,
              focusNode: _commentFocusNode,
              decoration: InputDecoration(
                hintText: 'Write your comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_editingCommentId != null)
                  TextButton(
                    onPressed: () {
                      _commentController.clear();
                      _commentFocusNode.unfocus();
                      setState(() {
                        _editingCommentId = null;
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                ElevatedButton(
                  onPressed:
                      _editingCommentId != null
                          ? () => _updateComment(_editingCommentId!)
                          : _addComment,
                  child: Text(_editingCommentId != null ? 'Update' : 'Post'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyInput(String parentCommentId) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Text(
              'Replying to comment',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _replyController,
              focusNode: _replyFocusNode,
              decoration: InputDecoration(
                hintText: 'Write your reply...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _replyController.clear();
                    _replyFocusNode.unfocus();
                    setState(() {
                      _replyingToCommentId = null;
                    });
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => _addReply(parentCommentId),
                  child: const Text('Reply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Comments', style: GoogleFonts.poppins())),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No comments yet'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final comment = snapshot.data!.docs[index];

                    return Column(
                      children: [
                        _buildCommentTile(comment),
                        if (_replyingToCommentId == comment.id)
                          _buildReplyInput(comment.id),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }
}
