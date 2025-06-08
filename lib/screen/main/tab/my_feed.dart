import 'package:axion/screen/main/chat/chat_detail_page.dart';
import 'package:axion/screen/main/comment/comment.dart';
import 'package:axion/screen/post/view_post.dart';
import 'package:axion/services/database.dart';
import 'package:axion/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:readmore/readmore.dart';
import 'package:share_plus/share_plus.dart';
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
  final Map<String, TextEditingController> _commentControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserDetails();
  }

  // @override
  // void dispose() {
  //   // Dispose all video controllers when the widget is disposed
  //   _chewieControllers.forEach((key, controller) {
  //     controller.dispose();
  //   });
  //   _videoControllers.forEach((key, controller) {
  //     controller.dispose();
  //   });

  //   super.dispose();
  // }

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

  // Helper function to build media widget (Image or Video)
  Widget _buildMediaWidget(String mediaUrl, String mediaType, String postId) {
    if (mediaUrl.isEmpty) {
      return const SizedBox.shrink(); // No media to display
    }

    if (mediaType == "image") {
      // Dispose video controllers if media type changes to image for this post
      if (_videoControllers.containsKey(postId)) {
        _videoControllers[postId]?.dispose();
        _chewieControllers[postId]?.dispose();
        _videoControllers.remove(postId);
        _chewieControllers.remove(postId);
        _videoInitializationFutures.remove(postId);
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          mediaUrl,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) => const Icon(
                Icons.image_not_supported,
                size: 100,
                color: Colors.grey,
              ),
        ),
      );
    } else if (mediaType == "video") {
      if (!_videoControllers.containsKey(postId)) {
        // Initialize video player and chewie controller if not already initialized
        final videoController = VideoPlayerController.networkUrl(
          Uri.parse(mediaUrl),
        );
        final initFuture = videoController
            .initialize()
            .then((_) {
              // IMPORTANT: Only create ChewieController if video is initialized and has dimensions
              if (videoController.value.isInitialized &&
                  videoController.value.size != Size.zero) {
                final chewieController = ChewieController(
                  videoPlayerController: videoController,
                  autoPlay: false, // Don't autoplay in feed
                  looping: false,
                  aspectRatio: videoController.value.aspectRatio,
                  errorBuilder: (context, errorMessage) {
                    return Center(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                );
                _videoControllers[postId] = videoController;
                _chewieControllers[postId] = chewieController;
              } else {
                // Handle cases where initialization succeeded but dimensions are not ready
                // This can indicate a corrupt video or temporary issue.
                print(
                  "Video initialized but no size reported for post $postId. Disposing controllers.",
                );
                // Clean up resources if the video isn't fully ready
                videoController.dispose();
                _videoControllers.remove(postId);
                _chewieControllers.remove(postId);
                _videoInitializationFutures.remove(
                  postId,
                ); // Remove the future as well
              }
              setState(
                () {},
              ); // Rebuild to display video once initialized or if error/no size
            })
            .catchError((e) {
              print("Error initializing video for post $postId: $e");
              // Clean up resources on error
              _videoControllers[postId]?.dispose();
              _chewieControllers[postId]?.dispose();
              _videoControllers.remove(postId);
              _chewieControllers.remove(postId);
              _videoInitializationFutures.remove(postId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error loading video for a post: $e")),
                );
              }
              setState(() {}); // Rebuild to show error placeholder
            });
        _videoInitializationFutures[postId] = initFuture;
      }

      // Use a FutureBuilder to handle the asynchronous initialization
      return FutureBuilder(
        future: _videoInitializationFutures[postId],
        builder: (context, snapshot) {
          // Check if both ChewieController exists AND video value is initialized and has size
          final isVideoInitializedAndReady =
              _chewieControllers.containsKey(postId) &&
              _chewieControllers[postId]!
                  .videoPlayerController
                  .value
                  .isInitialized &&
              _chewieControllers[postId]!.videoPlayerController.value.size !=
                  Size.zero;

          if (snapshot.connectionState == ConnectionState.done &&
              isVideoInitializedAndReady) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              // Wrap Chewie in an AspectRatio widget.
              // While Chewie itself uses aspectRatio, explicitly providing it here
              // ensures a defined size for the RenderBox even if there's a transient
              // issue with Chewie's internal sizing or the video controller's initial value.
              child: AspectRatio(
                aspectRatio:
                    _chewieControllers[postId]!
                        .videoPlayerController
                        .value
                        .aspectRatio,
                child: Chewie(controller: _chewieControllers[postId]!),
              ),
            );
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: 180,
              width: double.infinity,
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          } else {
            // This block handles errors, uninitialized state, or videos without a size
            return Container(
              height: 180,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: const Center(
                child: Icon(Icons.videocam_off, size: 50, color: Colors.grey),
              ),
            );
          }
        },
      );
    }
    return const SizedBox.shrink(); // Fallback for unknown media type
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('feeds')
                .orderBy('date', descending: true)
                .where("uid", isNotEqualTo: currentUserId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
              // Ensure a TextEditingController exists for this postId
              if (!_commentControllers.containsKey(postId)) {
                _commentControllers[postId] = TextEditingController();
              }
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
                  child: Card(
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
                            child: _buildMediaWidget(
                              mediaUrl,
                              mediaType,
                              postId,
                            ),
                          ),

                        const SizedBox(height: 12),
                        const Divider(),
                        Padding(
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
                                      color:
                                          isLiked ? Colors.green : Colors.grey,
                                    ),
                                    Text(
                                      'Like ($likeCount)',
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              ViewComment(postId: postId),
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.chat_bubble,
                                      color: Colors.grey,
                                    ),
                                    const Text(
                                      'Comment',
                                      style: TextStyle(color: Colors.black),
                                    ),
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
                                          (context) => const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                    );

                                    final friendDoc =
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(post['uid'])
                                            .get();

                                    if (!friendDoc.exists) {
                                      throw Exception(
                                        'Friend profile not found',
                                      );
                                    }
                                    if (currentUserName == null) {
                                      throw Exception(
                                        'Your profile not loaded',
                                      );
                                    }

                                    final chatId = await _database
                                        .createChatDocument(
                                          currentUserId: currentUserId,
                                          currentUserName: currentUserName!,
                                          currentUserPhoto: currentUserImage,
                                          friendId: post['uid'],
                                          friendName:
                                              friendDoc['fullName'] ??
                                              'Unknown',
                                          friendPhoto: friendDoc['image'],
                                        );

                                    if (!mounted) return;
                                    Navigator.of(context).pop();

                                    if (chatId == null) {
                                      throw Exception('Failed to create chat');
                                    }

                                    if (!mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => ChatDetailPage(
                                              chatId: chatId,
                                              currentUserId: currentUserId,
                                              friendId: post['uid'],
                                              friendName:
                                                  friendDoc['fullName'] ??
                                                  'Unknown',
                                              friendImage: friendDoc['image'],
                                            ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (mounted) Navigator.of(context).pop();
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to start chat: ${e.toString()}',
                                          ),
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                    debugPrint('Chat start error: $e');
                                  }
                                },
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.chat_rounded,
                                      color: Colors.grey,
                                    ),
                                    const Text(
                                      'Chat',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  String shareText =
                                      "${post['titleName'] ?? 'Untitled Post'}\n\n"
                                      "${post['description'] ?? 'No description'}\n";

                                  if (mediaUrl.isNotEmpty) {
                                    shareText +=
                                        "\nCheck out this media: $mediaUrl";
                                  }

                                  await Share.share(
                                    shareText,
                                    subject: post['titleName'] ?? "Social Post",
                                  );
                                },
                                child: Column(
                                  children: [
                                    const Icon(Icons.share, color: Colors.grey),
                                    const Text(
                                      'Share',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Display latest comment here
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('feeds')
                                  .doc(postId)
                                  .collection('comments')
                                  .orderBy('timestamp', descending: true)
                                  .limit(1)
                                  .snapshots(),
                          builder: (context, commentSnapshot) {
                            if (commentSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox.shrink(); // Or a small loading indicator
                            }
                            if (commentSnapshot.hasData &&
                                commentSnapshot.data!.docs.isNotEmpty) {
                              var latestComment =
                                  commentSnapshot.data!.docs.first.data()
                                      as Map<String, dynamic>;
                              return Padding(
                                padding: const EdgeInsets.only(
                                  left: 8.0,
                                  right: 8.0,
                                  bottom: 8.0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        latestComment['userImage'] ??
                                            'https://via.placeholder.com/150', // Fallback
                                      ),
                                      radius: 12, // Smaller avatar for comment
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            latestComment['userName'] ?? 'User',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            latestComment['text'] ?? '',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                            ),
                                            maxLines: 2, // Limit comment lines
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink(); // No comments yet
                          },
                        ),
                        // Comment input TextFormField
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 8.0,
                            right: 8.0,
                            bottom: 8.0,
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    currentUserImage ??
                                        'https://via.placeholder.com/150', // Fallback
                                  ),
                                  radius: 20,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _commentControllers[postId],
                                  decoration: InputDecoration(
                                    hintText: 'Add a comment...',
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 0,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(
                                        Icons.send,
                                        color: Colors.blueAccent,
                                      ),
                                      onPressed: () {
                                        _postComment(
                                          postId,
                                          _commentControllers[postId]!.text,
                                        ); // Send comment
                                      },
                                    ),
                                  ),
                                  onSubmitted: (text) {
                                    _postComment(postId, text); // Send on enter
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

  Future<void> _postComment(String postId, String commentText) async {
    if (commentText.trim().isEmpty) return; // Don't post empty comments

    if (currentUserName == null || currentUserImage == null) {
      // Potentially show a message that user details are not loaded
      print("User details not loaded, cannot post comment.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please wait, user details are loading."),
          ),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('feeds')
          .doc(postId)
          .collection('comments')
          .add({
            'text': commentText.trim(),
            'timestamp': Timestamp.now(),
            'uid': currentUserId,
            'userName': currentUserName,
            'userImage': currentUserImage,
          });
      _commentControllers[postId]
          ?.clear(); // Clear the text field after sending
    } catch (e) {
      print("Error posting comment: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to post comment: $e")));
      }
    }
  }
}
