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

class MyFeed extends StatefulWidget {
  const MyFeed({super.key});

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
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      post['image'] != null &&
                              post['image'].toString().isNotEmpty
                          ? Card(
                            child: Image.network(
                              post['image'],
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 200,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          )
                          : Center(
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 100,
                              color: Colors.grey,
                            ),
                          ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Text(
                              "Title: ",
                              style: GoogleFonts.poppins(
                                color: black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              post['titleName'] ?? "Untitled",
                              style: GoogleFonts.poppins(
                                color: black,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ReadMoreText(
                          post['description'] ?? "No description available",
                          trimLines: 3,
                          trimMode: TrimMode.Line,
                          trimCollapsedText: "Read More",
                          trimExpandedText: " Read Less",
                          moreStyle: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                          lessStyle: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () {
                              _database.toggleLike(post['uuid'], likes);
                            },
                            icon: Icon(
                              isLiked
                                  ? Icons.thumb_up
                                  : Icons.thumbs_up_down_outlined,
                              color: isLiked ? Colors.green : Colors.grey,
                            ),
                          ),
                          Text(
                            "$likeCount",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: () {
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
                            child: Text(
                              "View Post",
                              style: TextStyle(color: black),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
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
                                  throw Exception('Friend profile not found');
                                }
                                if (currentUserName == null) {
                                  throw Exception('Your profile not loaded');
                                }

                                // Create chat
                                final chatId = await _database
                                    .createChatDocument(
                                      currentUserId: currentUserId,
                                      currentUserName: currentUserName!,
                                      currentUserPhoto: currentUserImage,
                                      friendId: post['uid'],
                                      friendName:
                                          friendDoc['fullName'] ?? 'Unknown',
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
                                  ScaffoldMessenger.of(context).showSnackBar(
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
                            child: Text("Chat", style: TextStyle(color: black)),
                          ),

                          TextButton(
                            onPressed: () async {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          ViewComment(postId: post['uuid']),
                                ),
                              );
                            },
                            child: Text(
                              "Comments",
                              style: TextStyle(color: black),
                            ),
                          ),
                        ],
                      ),
                    ],
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
