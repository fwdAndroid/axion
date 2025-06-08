import 'dart:io';
import 'package:axion/widget/save_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart'; // Import video_player

class EditPost extends StatefulWidget {
  final String description;
  final String uuid;
  final String photo; // This will now represent mediaUrl (image or video)
  final String title;
  final String mediaType; // "image" or "video"

  EditPost({
    super.key,
    required this.description,
    required this.photo,
    required this.title,
    required this.uuid,
    required this.mediaType,
  });

  @override
  State<EditPost> createState() => _EditPostState();
}

class _EditPostState extends State<EditPost> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  File? _newMedia; // Can be an image or video file
  String? _currentMediaType; // To track if new media is image or video
  bool _isUpdating = false; // Tracks update state

  VideoPlayerController? _videoPlayerController;
  Future<void>? _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _descriptionController = TextEditingController(text: widget.description);
    _currentMediaType = widget.mediaType; // Initialize with existing media type

    if (widget.photo.isNotEmpty && widget.mediaType == "video") {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.photo),
      );
      _initializeVideoPlayerFuture = _videoPlayerController!.initialize().then((
        _,
      ) {
        setState(() {}); // Ensure the UI rebuilds once the video is initialized
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoPlayerController?.dispose(); // Dispose video controller
    super.dispose();
  }

  // Function to pick an image or video
  Future<void> _pickMedia() async {
    final ImagePicker picker = ImagePicker();
    // Show a dialog to choose between image and video
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Media Type"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text("Pick Image"),
                onTap: () async {
                  Navigator.pop(context); // Close the dialog
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      _newMedia = File(pickedFile.path);
                      _currentMediaType = "image";
                      _videoPlayerController
                          ?.dispose(); // Dispose old video controller if any
                      _videoPlayerController = null;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text("Pick Video"),
                onTap: () async {
                  Navigator.pop(context); // Close the dialog
                  final pickedFile = await picker.pickVideo(
                    source: ImageSource.gallery,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      _newMedia = File(pickedFile.path);
                      _currentMediaType = "video";
                      _videoPlayerController
                          ?.dispose(); // Dispose old video controller if any
                      _videoPlayerController = VideoPlayerController.file(
                        _newMedia!,
                      );
                      _initializeVideoPlayerFuture = _videoPlayerController!
                          .initialize()
                          .then((_) {
                            setState(
                              () {},
                            ); // Rebuild UI after video initialization
                          });
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

  // Function to upload media (image or video) to Firebase Storage
  Future<String?> _uploadMedia(File mediaFile, String type) async {
    try {
      String fileExtension = type == "image" ? "jpg" : "mp4";
      String fileName =
          "posts/${widget.uuid}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension";
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(mediaFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading media: $e");
      return null;
    }
  }

  // Function to update post details in Firestore
  Future<void> _updatePost() async {
    setState(() {
      _isUpdating = true; // Show loading
    });

    try {
      String? mediaUrl = widget.photo.isNotEmpty ? widget.photo : null;
      String updatedMediaType = widget.mediaType;

      if (_newMedia != null) {
        String? uploadedMediaUrl = await _uploadMedia(
          _newMedia!,
          _currentMediaType!,
        );
        if (uploadedMediaUrl != null) {
          mediaUrl = uploadedMediaUrl;
          updatedMediaType = _currentMediaType!;
        }
      }

      await FirebaseFirestore.instance
          .collection('feeds')
          .doc(widget.uuid)
          .update({
            'titleName': _titleController.text,
            'description': _descriptionController.text,
            'mediaUrl': mediaUrl ?? "", // 'image' field now stores media URL
            'mediaType': updatedMediaType, // Update mediaType
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post updated successfully")),
      );
      Navigator.pop(context); // Go back after updating
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error updating post: $e")));
    } finally {
      setState(() {
        _isUpdating = false; // Hide loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Post")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickMedia, // Call the new _pickMedia function
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(75),
                  border: Border.all(color: Colors.grey, width: 1),
                ),
                child: ClipOval(
                  child:
                      _newMedia != null
                          ? _currentMediaType == "image"
                              ? Image.file(_newMedia!, fit: BoxFit.cover)
                              : FutureBuilder(
                                future: _initializeVideoPlayerFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                          ConnectionState.done &&
                                      _videoPlayerController != null) {
                                    return AspectRatio(
                                      aspectRatio:
                                          _videoPlayerController!
                                              .value
                                              .aspectRatio,
                                      child: VideoPlayer(
                                        _videoPlayerController!,
                                      ),
                                    );
                                  } else {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                },
                              )
                          : widget.photo.isNotEmpty
                          ? widget.mediaType == "image"
                              ? Image.network(widget.photo, fit: BoxFit.cover)
                              : FutureBuilder(
                                future: _initializeVideoPlayerFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                          ConnectionState.done &&
                                      _videoPlayerController != null) {
                                    return AspectRatio(
                                      aspectRatio:
                                          _videoPlayerController!
                                              .value
                                              .aspectRatio,
                                      child: VideoPlayer(
                                        _videoPlayerController!,
                                      ),
                                    );
                                  } else {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                },
                              )
                          : Icon(
                            Icons
                                .add_a_photo, // Changed to a more general media icon
                            size: 50,
                            color: Colors.grey,
                          ),
                ),
              ),
            ),
            if (_currentMediaType == "video" &&
                _videoPlayerController != null &&
                _videoPlayerController!.value.isInitialized)
              IconButton(
                icon: Icon(
                  _videoPlayerController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
                onPressed: () {
                  setState(() {
                    _videoPlayerController!.value.isPlaying
                        ? _videoPlayerController!.pause()
                        : _videoPlayerController!.play();
                  });
                },
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _isUpdating
                ? const CircularProgressIndicator() // Show loading indicator
                : SaveButton(onTap: _updatePost, title: "Update"),
          ],
        ),
      ),
    );
  }
}
