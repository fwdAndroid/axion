import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MediaPreviewWidget extends StatefulWidget {
  final String mediaUrl;
  final String mediaType;
  final String postId;
  final Map<String, VideoPlayerController> videoControllers;
  final Map<String, ChewieController> chewieControllers;
  final Map<String, Future<void>> videoInitializationFutures;
  final VoidCallback refreshParent;

  const MediaPreviewWidget({
    super.key,
    required this.mediaUrl,
    required this.mediaType,
    required this.postId,
    required this.videoControllers,
    required this.chewieControllers,
    required this.videoInitializationFutures,
    required this.refreshParent,
  });

  @override
  State<MediaPreviewWidget> createState() => _MediaPreviewWidgetState();
}

class _MediaPreviewWidgetState extends State<MediaPreviewWidget> {
  @override
  void didUpdateWidget(covariant MediaPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If media switched from video to image or url changed,
    // dispose old controllers to avoid memory leaks.
    if (widget.mediaType == "image" && oldWidget.mediaType == "video") {
      _disposeControllers();
    } else if (widget.mediaType == "video" &&
        widget.mediaUrl != oldWidget.mediaUrl) {
      _disposeControllers();
    }
  }

  void _disposeControllers() {
    final postId = widget.postId;
    if (widget.videoControllers.containsKey(postId)) {
      widget.videoControllers[postId]?.dispose();
      widget.chewieControllers[postId]?.dispose();
      widget.videoControllers.remove(postId);
      widget.chewieControllers.remove(postId);
      widget.videoInitializationFutures.remove(postId);
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaUrl.isEmpty) return const SizedBox.shrink();

    if (widget.mediaType == "image") {
      // Just show image (controllers disposed in didUpdateWidget)
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          widget.mediaUrl,
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
    }

    // For video
    if (!widget.videoControllers.containsKey(widget.postId)) {
      final controller = VideoPlayerController.network(widget.mediaUrl);

      final initFuture = controller
          .initialize()
          .then((_) {
            if (controller.value.isInitialized &&
                controller.value.size != Size.zero) {
              final chewie = ChewieController(
                videoPlayerController: controller,
                autoPlay: false,
                looping: false,
                aspectRatio: controller.value.aspectRatio,
                errorBuilder: (context, errorMessage) {
                  return Center(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                },
              );
              widget.videoControllers[widget.postId] = controller;
              widget.chewieControllers[widget.postId] = chewie;
            } else {
              controller.dispose();
              widget.videoControllers.remove(widget.postId);
              widget.chewieControllers.remove(widget.postId);
              widget.videoInitializationFutures.remove(widget.postId);
            }
            widget.refreshParent();
          })
          .catchError((e) {
            widget.videoControllers[widget.postId]?.dispose();
            widget.chewieControllers[widget.postId]?.dispose();
            widget.videoControllers.remove(widget.postId);
            widget.chewieControllers.remove(widget.postId);
            widget.videoInitializationFutures.remove(widget.postId);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Error loading video: $e")));
            widget.refreshParent();
          });

      widget.videoInitializationFutures[widget.postId] = initFuture;
    }

    return FutureBuilder(
      future: widget.videoInitializationFutures[widget.postId],
      builder: (context, snapshot) {
        final isReady =
            widget.chewieControllers.containsKey(widget.postId) &&
            widget
                .chewieControllers[widget.postId]!
                .videoPlayerController
                .value
                .isInitialized &&
            widget
                    .chewieControllers[widget.postId]!
                    .videoPlayerController
                    .value
                    .size !=
                Size.zero;

        if (snapshot.connectionState == ConnectionState.done && isReady) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Chewie(
                controller: widget.chewieControllers[widget.postId]!,
              ),
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
}
