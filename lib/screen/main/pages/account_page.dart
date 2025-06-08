import 'package:axion/screen/main/setting_page.dart';
import 'package:axion/screen/post/edit_post.dart';
import 'package:axion/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:readmore/readmore.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: Icon(Icons.settings),
              color: mainColor,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (builder) => SettingPage()),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          StreamBuilder(
            stream:
                FirebaseFirestore.instance
                    .collection("users")
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return Center(child: Text('No data available'));
              }
              var snap = snapshot.data;

              return Column(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child:
                          snap['image'] != null && snap['image'].isNotEmpty
                              ? CircleAvatar(
                                backgroundImage: NetworkImage(snap['image']),
                                radius: 60,
                              )
                              : CircleAvatar(
                                radius: 60,
                                child: Icon(Icons.person, size: 60),
                              ),
                    ),
                  ),
                  Text(
                    snap['fullName'],
                    style: GoogleFonts.workSans(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height / 1.7,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('feeds')
                          .where(
                            "uid",
                            isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                          )
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.no_photography, size: 40),
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
                        String mediaUrl = post['mediaUrl'] ?? '';
                        String mediaType = post['mediaType'] ?? '';

                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Media display based on type
                                if (mediaUrl.isNotEmpty && mediaType.isNotEmpty)
                                  _buildMediaDisplay(
                                    context,
                                    mediaUrl,
                                    mediaType,
                                  )
                                else
                                  _buildPlaceholder(),

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
                                    post['description'] ??
                                        "No description available",
                                    trimLines: 3,
                                    trimMode: TrimMode.Line,
                                    trimCollapsedText: "Read More",
                                    trimExpandedText: " Read Less",
                                    moreStyle: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    lessStyle: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (builder) => EditPost(
                                                  uuid: post['uuid'],
                                                  description:
                                                      post['description'],
                                                  title: post['titleName'],
                                                  photo: post['mediaUrl'],
                                                  mediaType: post['mediaType'],
                                                ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        "Edit Post",
                                        style: TextStyle(color: black),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text("Confirm Deletion"),
                                              content: Text(
                                                "Are you sure you want to delete this post?",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    try {
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection('feeds')
                                                          .doc(post['uuid'])
                                                          .delete();

                                                      Navigator.pop(context);
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            "Post deleted successfully",
                                                          ),
                                                        ),
                                                      );
                                                    } catch (e) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            "Failed to delete post: $e",
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: Text(
                                                    "Delete",
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: Text(
                                        "Delete",
                                        style: TextStyle(color: red),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaDisplay(
    BuildContext context,
    String mediaUrl,
    String mediaType,
  ) {
    if (mediaType == 'image') {
      return Card(
        child: Image.network(
          mediaUrl,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.image_not_supported,
                size: 50,
                color: Colors.grey,
              ),
            );
          },
        ),
      );
    } else if (mediaType == 'video') {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoDetailScreen(videoUrl: mediaUrl),
            ),
          );
        },
        child: Container(
          height: 200,
          width: MediaQuery.of(context).size.width,
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video thumbnail with play button
              Icon(Icons.play_circle_filled, size: 60, color: Colors.white70),
              // Video type indicator
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "VIDEO",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 200,
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.media_bluetooth_off, size: 50, color: Colors.grey),
            SizedBox(height: 8),
            Text("No media available", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class VideoDetailScreen extends StatefulWidget {
  final String videoUrl;

  const VideoDetailScreen({super.key, required this.videoUrl});

  @override
  _VideoDetailScreenState createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error loading video: $errorMessage',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      );

      setState(() => _isLoading = false);
    } catch (e) {
      print("Error initializing video player: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child:
            _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Chewie(controller: _chewieController),
      ),
    );
  }
}
