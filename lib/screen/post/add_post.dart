import 'dart:io';
import 'dart:typed_data';
import 'package:axion/screen/main/main_dashboard.dart';
import 'package:axion/utils/colors.dart';
import 'package:axion/utils/image.dart';
import 'package:axion/utils/messagebar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class AddPost extends StatefulWidget {
  const AddPost({super.key});

  @override
  State<AddPost> createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  TextEditingController serviceNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  TextEditingController nameController = TextEditingController();
  String? imageUrl;
  Uint8List? _image;
  File? _videoFile;
  String _mediaType = '';
  bool isLoading = false;
  bool _isVideoInitializing = false;
  bool _showPlayButtonOverlay = true; // Track play button visibility
  var uuid = Uuid().v4();
  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    setState(() {
      nameController.text = data['fullName'] ?? '';
      imageUrl = data['image'];
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPlayer(File videoFile) async {
    setState(() => _isVideoInitializing = true);

    try {
      // Dispose existing controllers
      _videoController?.dispose();
      _chewieController?.dispose();

      // Create new controller
      _videoController = VideoPlayerController.file(videoFile);
      await _videoController!.initialize();

      // Setup listeners to update play button visibility
      _videoController!.addListener(() {
        if (_videoController!.value.isPlaying) {
          setState(() => _showPlayButtonOverlay = false);
        } else {
          setState(() => _showPlayButtonOverlay = true);
        }
      });

      // Create Chewie controller
      _chewieController = ChewieController(
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Unsupported video format',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
        deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        showControls: true,
        aspectRatio: _videoController!.value.aspectRatio,
      );
    } catch (e) {
      showMessageBar("Error loading video: ${e.toString()}", context);
      setState(() {
        _mediaType = '';
        _videoFile = null;
      });
    } finally {
      setState(() => _isVideoInitializing = false);
    }
  }

  // Play/pause video with play button
  void _toggleVideoPlayback() {
    if (_videoController == null) return;

    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
      setState(() => _showPlayButtonOverlay = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text("Add Feed")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 200,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(8),
              child: _mediaType.isEmpty
                  ? DottedBorder(
                      color: Colors.grey,
                      strokeWidth: 1,
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(9),
                      dashPattern: const [6, 3],
                      child: Center(
                        child: TextButton(
                          onPressed: selectMedia,
                          child: const Text("Add Image/Video"),
                        ),
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        // Image preview
                        if (_mediaType == 'image')
                          Image.memory(_image!, fit: BoxFit.cover),

                        // Video preview
                        if (_mediaType == 'video')
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Video player or placeholder
                              if (_chewieController != null &&
                                  _chewieController!
                                      .videoPlayerController
                                      .value
                                      .isInitialized)
                                Chewie(controller: _chewieController!)
                              else
                                Container(
                                  color: Colors.black,
                                  child: Center(
                                    child: _isVideoInitializing
                                        ? const CircularProgressIndicator()
                                        : const Icon(
                                            Icons.videocam,
                                            size: 50,
                                            color: Colors.white54,
                                          ),
                                  ),
                                ),

                              // Play button overlay
                              if (_showPlayButtonOverlay &&
                                  _chewieController != null &&
                                  _chewieController!
                                      .videoPlayerController
                                      .value
                                      .isInitialized)
                                GestureDetector(
                                  onTap: _toggleVideoPlayback,
                                  child: Container(
                                    color: Colors.transparent,
                                    child: const Center(
                                      child: Icon(
                                        Icons.play_circle_filled,
                                        size: 50,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                        // Edit button
                        Positioned(
                          right: 10,
                          top: 10,
                          child: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: selectMedia,
                          ),
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
              child: TextFormField(
                controller: serviceNameController,
                decoration: InputDecoration(
                  hintText: 'Enter Post Title',
                  hintStyle: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  contentPadding: const EdgeInsets.only(left: 8, top: 15),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(color: mainColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: mainColor),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: mainColor),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter Post Description',
                  hintStyle: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  contentPadding: const EdgeInsets.only(left: 8, top: 15),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(color: mainColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: mainColor),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: mainColor),
                  ),
                ),
              ),
            ),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (serviceNameController.text.isEmpty ||
                            descriptionController.text.isEmpty) {
                          showMessageBar("Please fill all fields", context);
                          return;
                        }
                        if (_mediaType.isEmpty) {
                          showMessageBar("Please select media", context);
                          return;
                        }

                        setState(() => isLoading = true);

                        String? mediaUrl;
                        try {
                          if (_mediaType == 'image') {
                            mediaUrl = await uploadImageToFirebase(_image!);
                          } else {
                            mediaUrl = await uploadVideoToFirebase(_videoFile!);
                          }

                          await FirebaseFirestore.instance
                              .collection('feeds')
                              .doc(uuid)
                              .set({
                                'titleName': serviceNameController.text,
                                'description': descriptionController.text,
                                'mediaUrl': mediaUrl,
                                'mediaType': _mediaType,
                                'date': DateTime.now(),
                                'uuid': uuid,
                                'uid': FirebaseAuth.instance.currentUser!.uid,
                                'favorite': [],
                                'comment': [],
                                'userImage': imageUrl,
                                'userName': nameController.text,
                              });

                          showMessageBar("Feed Posted", context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (builder) => const MainDashboard(),
                            ),
                          );
                        } catch (e) {
                          showMessageBar("Error: $e", context);
                        } finally {
                          setState(() => isLoading = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: mainColor,
                        fixedSize: const Size(320, 60),
                      ),
                      child: const Text(
                        "Add Feed",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> selectMedia() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Image'),
                onTap: () async {
                  Navigator.pop(context);
                  Uint8List? image = await pickImage(ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      _image = image;
                      _mediaType = 'image';
                      _videoFile = null;
                      _chewieController?.dispose();
                      _videoController?.dispose();
                      _chewieController = null;
                      _videoController = null;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Video'),
                onTap: () async {
                  Navigator.pop(context);
                  final videoXFile = await ImagePicker().pickVideo(
                    source: ImageSource.gallery,
                    maxDuration: const Duration(minutes: 5),
                  );
                  if (videoXFile != null) {
                    final videoFile = File(videoXFile.path);

                    setState(() {
                      _mediaType = 'video';
                      _videoFile = videoFile;
                      _image = null;
                      _showPlayButtonOverlay = true;
                      _chewieController?.dispose();
                      _videoController?.dispose();
                      _chewieController = null;
                      _videoController = null;
                    });

                    await _initializeVideoPlayer(videoFile);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String> uploadImageToFirebase(Uint8List file) async {
    Reference ref = FirebaseStorage.instance.ref().child(
      'feed_images/${Uuid().v4()}',
    );
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snap = await uploadTask;
    return await snap.ref.getDownloadURL();
  }

  Future<String> uploadVideoToFirebase(File videoFile) async {
    Reference ref = FirebaseStorage.instance.ref().child(
      'feed_videos/${Uuid().v4()}',
    );
    UploadTask uploadTask = ref.putFile(videoFile);
    TaskSnapshot snap = await uploadTask;
    return await snap.ref.getDownloadURL();
  }
}
