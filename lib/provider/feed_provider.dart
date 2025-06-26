import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class FeedProvider with ChangeNotifier {
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, ChewieController> _chewieControllers = {};
  final Map<String, Future<void>> _videoInitializationFutures = {};

  VideoPlayerController? getVideoController(String postId) =>
      _videoControllers[postId];

  ChewieController? getChewieController(String postId) =>
      _chewieControllers[postId];

  Future<void>? getInitializationFuture(String postId) =>
      _videoInitializationFutures[postId];

  void initializeVideo(String postId, String mediaUrl) {
    if (_videoControllers.containsKey(postId)) return;

    final controller = VideoPlayerController.network(
      mediaUrl,
      httpHeaders: {'range': 'bytes=0-'},
    );

    final initFuture = controller
        .initialize()
        .then((_) {
          if (controller.value.isInitialized) {
            _chewieControllers[postId] = ChewieController(
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
            _videoControllers[postId] = controller;
            notifyListeners();
          }
        })
        .catchError((e) {
          _videoInitializationFutures.remove(postId);
          controller.dispose();
          notifyListeners();
        });

    _videoInitializationFutures[postId] = initFuture;
    notifyListeners();
  }

  void disposeVideo(String postId) {
    _videoControllers[postId]?.dispose();
    _chewieControllers[postId]?.dispose();
    _videoControllers.remove(postId);
    _chewieControllers.remove(postId);
    _videoInitializationFutures.remove(postId);
    notifyListeners();
  }

  void disposeAll() {
    _videoControllers.forEach((_, c) => c.dispose());
    _chewieControllers.forEach((_, c) => c.dispose());
    _videoControllers.clear();
    _chewieControllers.clear();
    _videoInitializationFutures.clear();
  }
}
