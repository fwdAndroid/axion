import 'package:axion/widget/no_image_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart'; // Import video_player
import 'package:chewie/chewie.dart'; // Import chewie (optional)

class ViewPost extends StatefulWidget {
  final String? description, image, titleName, uuid, mediaType; // Make nullable
  final dateTime;

  ViewPost({
    super.key,
    required this.description,
    required this.image,
    required this.titleName,
    required this.uuid,
    required this.dateTime,
    required this.mediaType,
  });

  @override
  State<ViewPost> createState() => _ViewPostState();
}

class _ViewPostState extends State<ViewPost> {
  TextEditingController customerPassController = TextEditingController();
  var chatId = Uuid().v4();

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController; // Optional: For Chewie

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  @override
  void didUpdateWidget(covariant ViewPost oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-initialize video player if the mediaType or image URL changes
    if (widget.image != oldWidget.image ||
        widget.mediaType != oldWidget.mediaType) {
      _disposeVideoPlayer(); // Dispose old controller first
      _initializeVideoPlayer(); // Initialize new one
    }
  }

  void _initializeVideoPlayer() {
    if (widget.mediaType == 'video' &&
        widget.image != null &&
        widget.image!.isNotEmpty) {
      _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(widget.image!),
        )
        ..initialize()
            .then((_) {
              setState(() {
                // Ensure the first frame is shown and then play the video.
              });
            })
            .catchError((error) {
              print("Error initializing video player: $error");
            });

      // Optional: Initialize Chewie Controller
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false, // You can set this to true if you want auto-play
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );
    }
  }

  void _disposeVideoPlayer() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _chewieController = null;
    _videoPlayerController = null;
  }

  @override
  void dispose() {
    _disposeVideoPlayer();
    customerPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.titleName ?? "No Title",
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Conditional rendering for image or video
          if (widget.mediaType == 'video' &&
              _chewieController != null &&
              _chewieController!.videoPlayerController.value.isInitialized)
            AspectRatio(
              aspectRatio:
                  _chewieController!.videoPlayerController.value.aspectRatio,
              child: Chewie(controller: _chewieController!),
            )
          else if (widget.mediaType == 'mediaUrl' &&
              widget.image != null &&
              widget.image!.isNotEmpty)
            Image.network(
              widget.image!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => noImageWidget(),
            )
          else
            noImageWidget(), // Fallback for no media or unknown type
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              widget.titleName ?? "No Title",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ReadMoreText(
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
              widget.description ?? "No description available",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Published Date: ${getFormattedDateTime(widget.dateTime)}",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String getFormattedDateTime(dynamic dateTime) {
  if (dateTime == null) return "Unknown Date";

  // Ensure it's a DateTime object
  DateTime parsedDate;
  if (dateTime is Timestamp) {
    parsedDate = dateTime.toDate(); // If it's a Firestore Timestamp
  } else if (dateTime is String) {
    parsedDate = DateTime.tryParse(dateTime) ?? DateTime.now();
  } else if (dateTime is DateTime) {
    parsedDate = dateTime;
  } else {
    return "Invalid Date";
  }

  return DateFormat('dd MMM, hh:mm a').format(parsedDate);
}
