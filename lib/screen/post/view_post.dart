import 'package:axion/widget/no_image_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ViewPost extends StatefulWidget {
  final String? description, image, titleName, uuid, mediaType;
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
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  @override
  void didUpdateWidget(covariant ViewPost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image ||
        widget.mediaType != oldWidget.mediaType) {
      _disposeVideoPlayer();
      _initializeVideoPlayer();
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
              setState(() {});
            })
            .catchError((error) {
              print("Error initializing video player: $error");
            });

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
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
          if (widget.mediaType == 'video' &&
              _chewieController != null &&
              _chewieController!.videoPlayerController.value.isInitialized)
            SizedBox(
              height: 200,
              width: double.infinity,
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
            noImageWidget(),
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
              widget.description ?? "No description available",
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

  DateTime parsedDate;
  if (dateTime is Timestamp) {
    parsedDate = dateTime.toDate();
  } else if (dateTime is String) {
    parsedDate = DateTime.tryParse(dateTime) ?? DateTime.now();
  } else if (dateTime is DateTime) {
    parsedDate = dateTime;
  } else {
    return "Invalid Date";
  }

  return DateFormat('dd MMM, hh:mm a').format(parsedDate);
}
