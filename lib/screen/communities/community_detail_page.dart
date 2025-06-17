import 'package:axion/screen/communities/add_communites.dart';
import 'package:axion/screen/communities/view_community_comment.dart';
import 'package:axion/screen/post/view_post.dart';
import 'package:axion/services/database.dart';
import 'package:axion/utils/colors.dart';
import 'package:axion/widget/post_action_commuity_widget.dart';
import 'package:axion/widget/post_media_widget.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:readmore/readmore.dart';
import 'package:video_player/video_player.dart';

class CommunityDetailPage extends StatefulWidget {
  final String communityName;
  final String communityId;

  CommunityDetailPage({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  bool isJoined =
      false; // True if user has any join request (pending or approved)
  bool isApproved = false; // True only if request is approved
  bool loading = true;
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic>?
  userJoinRequest; // Stores the user's join request object

  @override
  void initState() {
    super.initState();

    _checkJoinStatus();
  }

  // Fetch the user's join request from the community document
  Future<void> _checkJoinStatus() async {
    try {
      setState(() => loading = true);

      final communityDoc =
          await FirebaseFirestore.instance
              .collection('communities')
              .doc(widget.communityId)
              .get();

      if (communityDoc.exists) {
        final userRequests =
            communityDoc['userRequests'] as List<dynamic>? ?? [];

        // Find the user's join request in the array
        for (var request in userRequests) {
          if (request is Map<String, dynamic> &&
              request['userId'] == currentUserId) {
            userJoinRequest = request;
            setState(() {
              isJoined = true;
              isApproved = request['status'] == 'approved';
            });
            break;
          }
        }

        // If no request was found
        if (userJoinRequest == null) {
          setState(() {
            isJoined = false;
            isApproved = false;
          });
        }
      }
    } catch (e) {
      print('Error checking join status: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  // Create a join request
  Future<void> joinGroup() async {
    try {
      setState(() => loading = true);

      final newRequest = {'userId': currentUserId, 'status': 'pending'};

      await FirebaseFirestore.instance
          .collection('communities')
          .doc(widget.communityId)
          .update({
            'userRequests': FieldValue.arrayUnion([newRequest]),
          });

      // Update local state
      setState(() {
        isJoined = true;
        userJoinRequest = newRequest;
      });
    } catch (e) {
      print('Error joining group: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send join request')));
    } finally {
      setState(() => loading = false);
    }
  }

  // Remove join request
  Future<void> leaveGroup() async {
    bool confirm = await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Leave Group"),
            content: const Text("Are you sure you want to leave the group?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Leave", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm && userJoinRequest != null) {
      try {
        setState(() => loading = true);

        await FirebaseFirestore.instance
            .collection('communities')
            .doc(widget.communityId)
            .update({
              'userRequests': FieldValue.arrayRemove([userJoinRequest]),
            });

        // Reset local state
        setState(() {
          isJoined = false;
          isApproved = false;
          userJoinRequest = null;
        });
      } catch (e) {
        print('Error leaving group: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to leave community')));
      } finally {
        setState(() => loading = false);
      }
    }
  }

  String? currentUserName;
  String? currentUserImage;
  final Database _database = Database();

  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, ChewieController> _chewieControllers = {};
  final Map<String, Future<void>> _videoInitializationFutures = {};

  final TextEditingController _commentController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Show FAB only when user is approved
      floatingActionButton:
          isApproved
              ? FloatingActionButton(
                backgroundColor: mainColor,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (builder) =>
                              AddCommunities(communityId: widget.communityId),
                    ),
                  );
                },
                child: Icon(Icons.add, color: colorWhite),
              )
              : null,
      appBar: AppBar(
        actions: [
          if (loading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: isJoined ? leaveGroup : joinGroup,
              child: Text(
                isJoined
                    ? (isApproved ? "Leave Group" : "Request Pending")
                    : "Join Group",
                style: TextStyle(
                  color: isJoined && !isApproved ? Colors.grey : mainColor,
                ),
              ),
            ),
        ],
        title: Text(
          widget.communityName,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ),
      body: _buildCommunityBody(),
    );
  }

  Widget _buildCommunityBody() {
    // Only approved members can see posts
    if (!isApproved) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_add, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              isJoined
                  ? "Your join request is pending approval"
                  : "Join this community to see posts",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (!isJoined)
              ElevatedButton(
                onPressed: joinGroup,
                child: const Text("Request to Join"),
              ),
          ],
        ),
      );
    }

    // Approved members see the posts
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('communitiesPost')
              .orderBy('date', descending: true)
              .where("commuityId", isEqualTo: widget.communityId)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.forum_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 20),
                const Text("No posts yet in this community"),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (builder) =>
                                AddCommunities(communityId: widget.communityId),
                      ),
                    );
                  },
                  child: const Text("Create First Post"),
                ),
              ],
            ),
          );
        }
        var posts = snapshot.data!.docs;
        // Existing post list builder
        return SizedBox(
          height: MediaQuery.of(context).size.height,
          child: ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              var post = posts[index].data() as Map<String, dynamic>;
              String postId = posts[index].id;
              List<dynamic> likes = post['favorite'] ?? [];
              bool isLiked = likes.contains(currentUserId);
              int likeCount = likes.length;

              String mediaUrl = post['mediaUrl'] ?? '';
              String mediaType = post['mediaType'] ?? 'image';

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (builder) => ViewPost(
                              description: post['description'],
                              image: mediaUrl,
                              titleName: post['titleName'],
                              uuid: post['uuid'],
                              dateTime: post['date']?.toDate().toString() ?? '',
                              mediaType: mediaType,
                            ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(width: .2),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(
                                post['userImage'] ?? '',
                              ),
                              radius: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post['userName'] ?? 'User',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    DateTime.tryParse(
                                              post['date']
                                                      ?.toDate()
                                                      .toString() ??
                                                  '',
                                            )
                                            ?.toLocal()
                                            .toString()
                                            .split('.')
                                            .first ??
                                        '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          post['titleName'] ?? "Untitled",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        ReadMoreText(
                          post['description'] ?? 'No description',
                          trimLines: 3,
                          trimMode: TrimMode.Line,
                          trimCollapsedText: 'Read More',
                          trimExpandedText: ' Show Less',
                          moreStyle: const TextStyle(color: Colors.blue),
                          lessStyle: const TextStyle(color: Colors.blue),
                        ),
                        if (mediaUrl.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: MediaPreviewWidget(
                              mediaUrl: mediaUrl,
                              mediaType: mediaType,
                              postId: postId,
                              videoControllers: _videoControllers,
                              chewieControllers: _chewieControllers,
                              videoInitializationFutures:
                                  _videoInitializationFutures,
                              refreshParent: () => setState(() {}),
                              context: context,
                            ),
                          ),
                        const Divider(),
                        PostActionsWidgetCommuity(
                          postId: postId,
                          likeCount: likeCount,
                          isLiked: isLiked,
                          likes: likes,
                          mediaUrl: mediaUrl,
                          currentUserId: currentUserId,
                          currentUserName: currentUserName,
                          currentUserImage: currentUserImage,
                          post: post,
                          database: _database,
                        ),

                        // Comments
                        if ((post['comment'] as List?)?.isNotEmpty ?? false)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List<Widget>.from(
                                (post['comment'] as List).map((comment) {
                                  final String commentId = comment['id'];
                                  final String commenterId = comment['userId'];
                                  final List<dynamic> commentLikes =
                                      comment['likes'] ?? [];
                                  final bool isCommentLiked = commentLikes
                                      .contains(currentUserId);
                                  final List<dynamic> replies =
                                      comment['replies'] ?? [];

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.account_circle,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    comment['username'] ??
                                                        'User',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    comment['text'] ?? '',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                isCommentLiked
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color:
                                                    isCommentLiked
                                                        ? Colors.red
                                                        : Colors.grey,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                Database().toggleCommentLike(
                                                  postId,
                                                  commentId,
                                                  isCommentLiked,
                                                );
                                              },
                                            ),
                                            if (commenterId == currentUserId)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  size: 20,
                                                ),
                                                onPressed: () {
                                                  deleteComment(
                                                    postId,
                                                    commentId,
                                                  );
                                                },
                                              ),
                                          ],
                                        ),
                                        if (replies.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 32.0,
                                              top: 4,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: List<Widget>.from(
                                                replies.map((reply) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 2.0,
                                                        ),
                                                    child: Text(
                                                      '${reply['username'] ?? 'User'}: ${reply['text'] ?? ''}',
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 12,
                                                          ),
                                                    ),
                                                  );
                                                }),
                                              ),
                                            ),
                                          ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 32.0,
                                          ),
                                          child: TextButton(
                                            onPressed:
                                                () => showReplyDialog(
                                                  postId,
                                                  commentId,
                                                ),
                                            child: const Text(
                                              'Reply',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),

                        // Add comment
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(
                                  currentUserImage ??
                                      'https://via.placeholder.com/150',
                                ),
                                radius: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  decoration: InputDecoration(
                                    fillColor: Colors.white,
                                    filled: true,
                                    hintText: 'Add a comment...',
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(
                                        Icons.send,
                                        color: Colors.blueAccent,
                                      ),
                                      onPressed: () {
                                        Database().addCommentCommnutiye(
                                          postId,
                                          context,
                                          _commentController,
                                        );
                                      },
                                    ),
                                  ),
                                  onSubmitted: (text) {
                                    Database().addCommentCommnutiye(
                                      postId,
                                      context,
                                      _commentController,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void deleteComment(String postId, String commentId) async {
    final docRef = FirebaseFirestore.instance
        .collection('communitiesPost')
        .doc(postId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) return;
    List<dynamic> comments = snapshot.data()!['comment'] ?? [];
    comments.removeWhere((comment) => comment['id'] == commentId);
    await docRef.update({'comment': comments});
    setState(() {});
  }

  void showReplyDialog(String postId, String commentId) {
    final replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reply to comment'),
          content: TextField(
            controller: replyController,
            decoration: const InputDecoration(hintText: 'Enter your reply'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final replyText = replyController.text.trim();
                if (replyText.isEmpty) return;

                final docRef = FirebaseFirestore.instance
                    .collection('communitiesPost')
                    .doc(postId);
                final snapshot = await docRef.get();

                if (!snapshot.exists) return;
                final List<dynamic> comments =
                    snapshot.data()!['comment'] ?? [];
                for (var comment in comments) {
                  if (comment['id'] == commentId) {
                    comment['replies'].add({
                      'text': replyText,
                      'username': currentUserName ?? 'User',
                    });
                    break;
                  }
                }
                await docRef.update({'comment': comments});
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }
}
