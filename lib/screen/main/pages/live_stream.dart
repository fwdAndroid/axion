import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

class LiveStreamPage extends StatelessWidget {
  final String userID;
  final String userName;
  final String liveID;
  final bool isHost;

  const LiveStreamPage({
    Key? key,
    required this.userID,
    required this.userName,
    required this.liveID,
    required this.isHost,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ZegoUIKitPrebuiltLiveStreaming(
      appID: 1683553241, // replace with your App ID
      appSign:
          '5e573c38d90cc7fa7c6ce0123bc59211e09c53c3b24616b501d4f44b8790a117', // replace with your App Sign
      userID: userID,
      userName: userName,
      liveID: liveID,
      config:
          isHost
              ? ZegoUIKitPrebuiltLiveStreamingConfig.host()
              : ZegoUIKitPrebuiltLiveStreamingConfig.audience(),
    );
  }
}
