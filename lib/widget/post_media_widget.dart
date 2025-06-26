import 'dart:io';
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
  bool _hasError = false;
  bool _isInitialized = false;

  @override
  void didUpdateWidget(covariant MediaPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.mediaType == "image" && oldWidget.mediaType == "video") {
      _disposeControllers();
    } else if (widget.mediaType == "video" &&
        (widget.mediaUrl != oldWidget.mediaUrl || _hasError)) {
      _disposeControllers();
      _hasError = false;
      _isInitialized = false;
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

  void _initializeVideoController() {
    if (widget.mediaType != "video" || _hasError) return;

    final controller = VideoPlayerController.network(
      widget.mediaUrl,
      httpHeaders: {'range': 'bytes=0-'},
    );

    final initFuture = controller
        .initialize()
        .then((_) {
          if (mounted && controller.value.isInitialized) {
            setState(() {
              _isInitialized = true;
              widget.chewieControllers[widget.postId] = ChewieController(
                videoPlayerController: controller,
                autoPlay: false,
                looping: false,
                aspectRatio: controller.value.aspectRatio,
                errorBuilder: (context, errorMessage) {
                  return Center(
                    child: Text(
                      "Playback error\n${errorMessage.split(':').last.trim()}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                },
              );
              widget.videoControllers[widget.postId] = controller;
            });
          } else {
            controller.dispose();
          }
        })
        .catchError((e) {
          if (mounted) {
            setState(() => _hasError = true);
            _disposeControllers();
            widget.refreshParent();
          }
        });

    widget.videoInitializationFutures[widget.postId] = initFuture;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaUrl.isEmpty) return const SizedBox.shrink();

    if (widget.mediaType == "image") {
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

    // Initialize video controller if needed
    if (!widget.videoControllers.containsKey(widget.postId) && !_hasError) {
      _initializeVideoController();
    }

    return FutureBuilder(
      future: widget.videoInitializationFutures[widget.postId],
      builder: (context, snapshot) {
        // Handle error state
        if (_hasError || snapshot.hasError) {
          return Container(
            height: 180,
            color: Colors.grey.shade800,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 10),
                const Text(
                  'Video playback failed',
                  style: TextStyle(color: Colors.white),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      widget.videoInitializationFutures.remove(widget.postId);
                    });
                    widget.refreshParent();
                  },
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          );
        }

        // Check if video is ready
        final isReady =
            widget.chewieControllers.containsKey(widget.postId) &&
            widget
                .chewieControllers[widget.postId]!
                .videoPlayerController
                .value
                .isInitialized;

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
        } else {
          // Show loading placeholder
          return Container(
            height: 180,
            color: Colors.black,
            child: Center(
              child:
                  snapshot.connectionState == ConnectionState.waiting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(
                        Icons.videocam_off,
                        size: 50,
                        color: Colors.grey,
                      ),
            ),
          );
        }
      },
    );
  }
}
