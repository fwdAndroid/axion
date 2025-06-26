import 'dart:io';
import 'dart:typed_data';
import 'package:axion/screen/main/main_dashboard.dart';
import 'package:axion/utils/colors.dart';
import 'package:axion/utils/image.dart'; // Assuming this has your pickImage function
import 'package:axion/utils/messagebar.dart'; // Assuming this has your showMessageBar function
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
import 'package:video_compress/video_compress.dart';
import 'package:shimmer_animation/shimmer_animation.dart'; // Import for shimmer effect
import 'package:percent_indicator/percent_indicator.dart'; // Import for linear progress bar

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
  String _mediaType = ''; // 'image', 'video', or '' for no media
  bool isLoading = false; // For overall post submission
  bool _isVideoInitializing = false; // For Chewie initialization
  bool _showPlayButtonOverlay = true; // Track play button visibility
  double _compressionProgress = 0.0; // 0.0 to 1.0
  bool _isCompressing = false;
  String _compressionMessage = ''; // Message for compression status/errors

  var uuid = Uuid().v4(); // Unique ID for the post

  @override
  void initState() {
    super.initState();
    fetchData();
    VideoCompress.setLogLevel(0); // Disable logs for video_compress
  }

  void fetchData() async {
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get();

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      setState(() {
        nameController.text = data['fullName'] ?? '';
        imageUrl = data['image'];
      });
    } catch (e) {
      print("Error fetching user data: $e");
      // Handle error, e.g., show a message to the user
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<File?> _compressVideo(File originalFile) async {
    setState(() {
      _isCompressing = true;
      _compressionProgress = 0.0;
      _compressionMessage = 'Compressing video...';
    });

    try {
      // Subscribe to compression progress
      final subscription = VideoCompress.compressProgress$.subscribe((
        progress,
      ) {
        if (mounted) {
          setState(() {
            _compressionProgress =
                progress / 100; // Progress is 0-100, we need 0-1
            _compressionMessage =
                'Compressing video: ${progress.toStringAsFixed(1)}%';
          });
        }
      });

      final MediaInfo? compressedInfo = await VideoCompress.compressVideo(
        originalFile.path,
        quality: VideoQuality.LowQuality, // Adjusted for low-end devices
        deleteOrigin:
            false, // Keep original for now, delete if successful later if needed
        includeAudio: true,
        frameRate: 24, // Reduced frame rate for better compatibility
      );

      subscription.unsubscribe(); // Unsubscribe after compression is done

      if (compressedInfo?.file != null) {
        if (mounted) {
          setState(() {
            _compressionMessage = 'Compression complete!';
          });
        }
        return compressedInfo!.file;
      } else {
        throw Exception("Video compression failed: No output file generated.");
      }
    } catch (e) {
      print("Compression error: $e");
      if (mounted) {
        setState(() {
          _compressionMessage =
              "Video processing failed. Your device might struggle with this video, or the format is unsupported. Please try a different video or a shorter one.";
          _isCompressing = false; // Stop compression indication
          _videoFile = null; // Clear the selected video file on failure
          _mediaType = ''; // Clear media type
          _chewieController?.dispose();
          _videoController?.dispose();
          _chewieController = null;
          _videoController = null;
        });
      }
      showMessageBar(_compressionMessage, context);
      return null; // Indicate compression failed
    } finally {
      // Only set _isCompressing to false if compression was successful
      // or if the error message is already set (meaning it failed)
      if (mounted &&
          (_compressionMessage.contains("complete") ||
              _compressionMessage.contains("failed") ||
              _compressionMessage.contains("struggle"))) {
        setState(() {
          _isCompressing = false;
          // Only clear message if it was a success. Keep error message if failed.
          if (_compressionMessage.contains("complete")) {
            _compressionMessage = '';
          }
        });
      }
    }
  }

  Future<void> _initializeVideoPlayer(File videoFile) async {
    if (mounted) {
      setState(() => _isVideoInitializing = true);
    }

    try {
      _videoController?.dispose();
      _chewieController?.dispose();

      final File? compressedFile = await _compressVideo(videoFile);
      // If compressedFile is null, it means compression failed.
      if (compressedFile == null) {
        if (mounted) {
          setState(() {
            _mediaType = ''; // Reset media type
            _videoFile = null; // Clear video file
            _isVideoInitializing = false; // Stop initialization state
            _compressionMessage =
                "Failed to load video."; // Set specific message
          });
        }
        return; // Exit early as video can't be played
      }

      final File finalFile = compressedFile; // Use the compressed file

      _videoController = VideoPlayerController.file(
        finalFile,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await _videoController!.initialize();

      _videoController!.addListener(() {
        if (mounted) {
          if (_videoController!.value.isPlaying) {
            setState(() => _showPlayButtonOverlay = false);
          } else {
            setState(
              () => _showPlayButtonOverlay = true,
            ); // Show when paused/ended
          }
        }
      });

      _chewieController = ChewieController(
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Unsupported video format or playback error: $errorMessage',
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
      showMessageBar("Your Device is Not Supported For Video", context);
      if (mounted) {
        setState(() {
          _mediaType = '';
          _videoFile = null;
          _chewieController?.dispose();
          _videoController?.dispose();
          _chewieController = null;
          _videoController = null;
          _isVideoInitializing = false; // Stop initialization state
          _compressionMessage = "Failed to load video."; // Clear/reset message
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isVideoInitializing = false);
      }
    }
  }

  // Play/pause video with play button
  void _toggleVideoPlayback() {
    if (_videoController == null) return;

    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
      if (mounted) {
        setState(() => _showPlayButtonOverlay = false);
      }
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
              child:
                  _mediaType.isEmpty
                      ? DottedBorder(
                        color: Colors.grey,
                        strokeWidth: 1,
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(9),
                        dashPattern: const [6, 3],
                        child: Center(
                          child: TextButton(
                            onPressed: selectMedia,
                            child: const Text("Add Image/Video (Optional)"),
                          ),
                        ),
                      )
                      : Stack(
                        alignment: Alignment.center,
                        children: [
                          // Image preview
                          if (_mediaType == 'image' && _image != null)
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
                                else // This else block shows loading/error states
                                  Container(
                                    color: Colors.black,
                                    child: Center(
                                      child:
                                          _isVideoInitializing || _isCompressing
                                              ? Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  if (_isCompressing)
                                                    // Shimmer and Progress Bar for compression
                                                    Shimmer(
                                                      color: Colors.white,
                                                      colorOpacity: 0.3,
                                                      child: LinearPercentIndicator(
                                                        width:
                                                            MediaQuery.of(
                                                              context,
                                                            ).size.width *
                                                            0.7,
                                                        animation: true,
                                                        lineHeight: 20.0,
                                                        percent:
                                                            _compressionProgress,
                                                        center: Text(
                                                          _compressionMessage,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12.0,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                        ),
                                                        linearStrokeCap:
                                                            LinearStrokeCap
                                                                .roundAll,
                                                        progressColor:
                                                            mainColor,
                                                        backgroundColor:
                                                            Colors
                                                                .grey
                                                                .shade700,
                                                      ),
                                                    )
                                                  else if (_isVideoInitializing)
                                                    // Circular progress for video player initialization
                                                    const CircularProgressIndicator(),
                                                  // Display compression/initialization messages
                                                  if (_compressionMessage
                                                      .isNotEmpty)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8.0,
                                                          ),
                                                      child: Text(
                                                        _compressionMessage,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              )
                                              : const Icon(
                                                // Placeholder if no process active and not initialized
                                                Icons.videocam,
                                                size: 50,
                                                color: Colors.white54,
                                              ),
                                    ),
                                  ),

                                // >>> PLAY BUTTON OVERLAY <<<
                                if (_showPlayButtonOverlay &&
                                    _chewieController != null &&
                                    _chewieController!
                                        .videoPlayerController
                                        .value
                                        .isInitialized)
                                  GestureDetector(
                                    onTap: _toggleVideoPlayback,
                                    child: Container(
                                      color:
                                          Colors
                                              .transparent, // Makes the tap area fill the container
                                      child: const Center(
                                        child: Icon(
                                          Icons.play_circle_filled,
                                          size: 50,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ),
                                // >>> END PLAY BUTTON OVERLAY <<<
                              ],
                            ),

                          // Edit button (to select different media)
                          Positioned(
                            right: 10,
                            top: 10,
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: selectMedia,
                            ),
                          ),
                          // Clear Media Button
                          if (_mediaType.isNotEmpty)
                            Positioned(
                              left: 10,
                              top: 10,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  if (mounted) {
                                    setState(() {
                                      _mediaType = '';
                                      _image = null;
                                      _videoFile = null;
                                      _chewieController?.dispose();
                                      _videoController?.dispose();
                                      _chewieController = null;
                                      _videoController = null;
                                      _compressionMessage = '';
                                      _isCompressing = false;
                                      _isVideoInitializing = false;
                                    });
                                  }
                                },
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
            isLoading ||
                    _isCompressing ||
                    _isVideoInitializing // Disable button if any process is active
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

                      // Basic validation: if media type is set, ensure file is not null
                      if (_mediaType == 'image' && _image == null) {
                        showMessageBar(
                          "Please select an image or clear media",
                          context,
                        );
                        return;
                      }
                      if (_mediaType == 'video' && _videoFile == null) {
                        showMessageBar(
                          "Please select a video or clear media",
                          context,
                        );
                        return;
                      }

                      if (mounted) {
                        setState(() => isLoading = true);
                      }

                      String? mediaUrl;
                      try {
                        if (_mediaType == 'image' && _image != null) {
                          mediaUrl = await uploadImageToFirebase(_image!);
                        } else if (_mediaType == 'video' &&
                            _videoFile != null) {
                          mediaUrl = await uploadVideoToFirebase(_videoFile!);
                        }
                        // If _mediaType is empty, mediaUrl remains null, which is fine for optional media

                        await FirebaseFirestore.instance
                            .collection('feeds')
                            .doc(uuid)
                            .set({
                              'titleName': serviceNameController.text,
                              'description': descriptionController.text,
                              'mediaUrl': mediaUrl, // Will be null if no media
                              'mediaType': _mediaType, // Will be '' if no media
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
                        showMessageBar("Error posting feed: $e", context);
                      } finally {
                        if (mounted) {
                          setState(() => isLoading = false);
                        }
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
                    if (mounted) {
                      setState(() {
                        _image = image;
                        _mediaType = 'image';
                        _videoFile = null; // Clear video
                        _chewieController?.dispose();
                        _videoController?.dispose();
                        _chewieController = null;
                        _videoController = null;
                        _compressionMessage =
                            ''; // Clear any previous compression message
                        _isCompressing =
                            false; // Ensure compression state is off
                      });
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Video (max 1 minute)'),
                onTap: () async {
                  Navigator.pop(context);
                  final videoXFile = await ImagePicker().pickVideo(
                    source: ImageSource.gallery,
                    maxDuration: const Duration(
                      minutes: 1,
                    ), // Limit duration to 1 minute
                  );

                  if (videoXFile != null) {
                    if (mounted) {
                      setState(() {
                        _mediaType = 'video';
                        _videoFile = File(videoXFile.path);
                        _image = null; // Clear image
                        _showPlayButtonOverlay =
                            true; // Ensure play button is visible initially
                        _chewieController?.dispose();
                        _videoController?.dispose();
                        _chewieController = null;
                        _videoController = null;
                        _compressionMessage =
                            ''; // Clear any previous compression message
                        _isCompressing = true; // Indicate compression starts
                      });
                    }
                    // This will trigger compression and player initialization
                    await _initializeVideoPlayer(_videoFile!);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('Remove Media'),
                onTap: () {
                  Navigator.pop(context);
                  if (mounted) {
                    setState(() {
                      _mediaType = '';
                      _image = null;
                      _videoFile = null;
                      _chewieController?.dispose();
                      _videoController?.dispose();
                      _chewieController = null;
                      _videoController = null;
                      _compressionMessage = '';
                      _isCompressing = false;
                      _isVideoInitializing = false;
                    });
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
    // Note: Video compression already happens in _initializeVideoPlayer,
    // which updates _videoFile in state to the compressed version.
    // So, we upload the already compressed _videoFile from the state.
    final File uploadFile = _videoFile!;

    Reference ref = FirebaseStorage.instance.ref().child(
      'feed_videos/${Uuid().v4()}.mp4', // Force .mp4 extension for consistent playback
    );

    final UploadTask uploadTask = ref.putFile(uploadFile);

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes;
      print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      // You could update a separate upload progress indicator here if desired
    });

    final TaskSnapshot snap = await uploadTask;
    return await snap.ref.getDownloadURL();
  }
}
