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

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserDetails();
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
              List<dynamic> likes = post['favorite'] ?? [];
              bool isLiked = likes.contains(currentUserId);
              int likeCount = likes.length;

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
                              image: post['image'],
                              titleName: post['titleName'],
                              uuid: post['uuid'],
                              dateTime: post['date'].toString(),
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

                        if (post['image'] != null &&
                            post['image'].toString().isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              post['image'],
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
                                  _database.toggleLike(post['uuid'], likes);
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
                                              ViewComment(postId: post['uuid']),
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Icon(Icons.chat_bubble, color: Colors.grey),
                                    Text(
                                      'Comment',
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  try {
                                    // Show loading indicator
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder:
                                          (context) => const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                    );

                                    // Get friend data
                                    final friendDoc =
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(post['uid'])
                                            .get();

                                    // Validate data
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

                                    // Create chat
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

                                    // Close loading dialog
                                    if (!mounted) return;
                                    Navigator.of(context).pop();

                                    if (chatId == null) {
                                      throw Exception('Failed to create chat');
                                    }

                                    // Open chat screen
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
                                    // Close loading dialog if still open
                                    if (mounted) Navigator.of(context).pop();

                                    // Show error message
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
                                    Icon(
                                      Icons.chat_rounded,
                                      color: Colors.grey,
                                    ),
                                    Text(
                                      'Chat',
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {},
                                child: Column(
                                  children: [
                                    Icon(Icons.share, color: Colors.grey),
                                    Text(
                                      'Share',
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircleAvatar(
                                backgroundImage: NetworkImage(
                                  post['userImage'] ?? '',
                                ),
                                radius: 20,
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  hintText: 'Add a comment...',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.only(
                                    left: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
}
