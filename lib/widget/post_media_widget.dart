import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MediaPreviewWidget extends StatelessWidget {
  final String mediaUrl;
  final String mediaType;
  final String postId;
  final Map<String, VideoPlayerController> videoControllers;
  final Map<String, ChewieController> chewieControllers;
  final Map<String, Future<void>> videoInitializationFutures;
  final void Function() refreshParent;
  final BuildContext context;

  const MediaPreviewWidget({
    super.key,
    required this.mediaUrl,
    required this.mediaType,
    required this.postId,
    required this.videoControllers,
    required this.chewieControllers,
    required this.videoInitializationFutures,
    required this.refreshParent,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaUrl.isEmpty) return const SizedBox.shrink();

    if (mediaType == "image") {
      // Dispose video if switching to image
      if (videoControllers.containsKey(postId)) {
        videoControllers[postId]?.dispose();
        chewieControllers[postId]?.dispose();
        videoControllers.remove(postId);
        chewieControllers.remove(postId);
        videoInitializationFutures.remove(postId);
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          mediaUrl,
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

    if (mediaType == "video") {
      if (!videoControllers.containsKey(postId)) {
        final controller = VideoPlayerController.networkUrl(
          Uri.parse(mediaUrl),
        );

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
                videoControllers[postId] = controller;
                chewieControllers[postId] = chewie;
              } else {
                controller.dispose();
                videoControllers.remove(postId);
                chewieControllers.remove(postId);
                videoInitializationFutures.remove(postId);
              }

              refreshParent(); // Call setState from parent
            })
            .catchError((e) {
              videoControllers[postId]?.dispose();
              chewieControllers[postId]?.dispose();
              videoControllers.remove(postId);
              chewieControllers.remove(postId);
              videoInitializationFutures.remove(postId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error loading video: $e")),
              );
              refreshParent();
            });

        videoInitializationFutures[postId] = initFuture;
      }

      return FutureBuilder(
        future: videoInitializationFutures[postId],
        builder: (context, snapshot) {
          final isReady =
              chewieControllers.containsKey(postId) &&
              chewieControllers[postId]!
                  .videoPlayerController
                  .value
                  .isInitialized &&
              chewieControllers[postId]!.videoPlayerController.value.size !=
                  Size.zero;

          if (snapshot.connectionState == ConnectionState.done && isReady) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: Chewie(controller: chewieControllers[postId]!),
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

    return const SizedBox.shrink();
  }
}
