import 'package:axion/screen/post/view_post.dart';
import 'package:axion/services/database.dart';
import 'package:axion/utils/colors.dart';
import 'package:axion/widget/post_action_widget.dart';
import 'package:axion/widget/post_media_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:readmore/readmore.dart';
import 'package:video_player/video_player.dart'; // Import video_player
import 'package:chewie/chewie.dart'; // Import chewie

class MyFeed extends StatefulWidget {
  const MyFeed({Key? key}) : super(key: key);

  @override
  State<MyFeed> createState() => _MyFeedState();
}

class _MyFeedState extends State<MyFeed> {
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String? currentUserName;
  String? currentUserImage;
  final Database _database = Database();

  // Store video controllers to manage their lifecycle
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, ChewieController> _chewieControllers = {};
  final Map<String, Future<void>> _videoInitializationFutures = {};
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserDetails();
  }

  @override
  void dispose() {
    // Dispose all video controllers when the widget is disposed
    _chewieControllers.forEach((key, controller) {
      controller.dispose();
    });
    _videoControllers.forEach((key, controller) {
      controller.dispose();
    });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('feeds')
                .orderBy('date', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Text(""));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.podcasts_outlined, size: 40),
                  Text("No posts available"),
                ],
              ),
            );
          }

          var posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              var post = posts[index].data() as Map<String, dynamic>;
              String postId = posts[index].id;
              List<dynamic> likes = post['favorite'] ?? [];
              bool isLiked = likes.contains(currentUserId);
              int likeCount = likes.length;

              String mediaUrl = post['mediaUrl'] ?? '';
              String mediaType = post['mediaType'] ?? 'image';

              return Container(
                padding: EdgeInsets.all(8),
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
                              mediaType: post['mediaType'],
                            ),
                      ),
                    );
                  },
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
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
                                        fontSize: 14,
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
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 8.0,
                            right: 8,
                            top: 8,
                          ),
                          child: Text(
                            post['titleName'] ?? "Untitled",
                            style: GoogleFonts.poppins(
                              color: black,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, right: 8),
                          child: ReadMoreText(
                            post['description'] ?? 'No description',
                            trimLines: 3,
                            trimMode: TrimMode.Line,
                            trimCollapsedText: 'Read More',
                            trimExpandedText: ' Show Less',
                            moreStyle: const TextStyle(color: Colors.blue),
                            lessStyle: const TextStyle(color: Colors.blue),
                          ),
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
                            ),
                          ),

                        const SizedBox(height: 12),
                        const Divider(),
                        PostActionsWidget(
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

                        const SizedBox(height: 10),
                        // Display latest comment here
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
                                                Database().toggleFeedLike(
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
                                                  Database().deleteFeedComment(
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
                        // Comment input TextFormField
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 8,
                          ),
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
                                        Database().addFeedCommnutiye(
                                          postId,
                                          context,
                                          _commentController,
                                        );
                                      },
                                    ),
                                  ),
                                  onSubmitted: (text) {
                                    Database().addFeedCommnutiye(
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
          );
        },
      ),
    );
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
                    .collection('feeds')
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
