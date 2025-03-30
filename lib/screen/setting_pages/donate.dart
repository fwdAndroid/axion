import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class DonateClass extends StatefulWidget {
  String url;
  DonateClass({super.key, required this.url});

  @override
  State<DonateClass> createState() => _DonateClassState();
}

class _DonateClassState extends State<DonateClass> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;

  double progress = 0;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      InAppWebViewController.setWebContentsDebuggingEnabled(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Donate Now")),
      body: Column(
        children: [
          progress < 1.0
              ? LinearProgressIndicator(value: progress)
              : const SizedBox.shrink(),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialOptions: InAppWebViewGroupOptions(
                crossPlatform: InAppWebViewOptions(
                  javaScriptEnabled: true,
                  clearCache: true,
                  useShouldOverrideUrlLoading: true,
                  mediaPlaybackRequiresUserGesture: false,
                  allowUniversalAccessFromFileURLs: true,
                  allowFileAccessFromFileURLs: true,
                ),
                android: AndroidInAppWebViewOptions(
                  mixedContentMode:
                      AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                  allowContentAccess: true,
                  allowFileAccess: true,
                ),
                ios: IOSInAppWebViewOptions(allowsInlineMediaPlayback: true),
              ),
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  this.progress = progress / 100;
                });
              },
              onLoadError: (controller, url, code, message) {
                debugPrint("Error loading $url: $message");
              },
              onConsoleMessage: (controller, consoleMessage) {
                debugPrint("Console: ${consoleMessage.message}");
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                var uri = navigationAction.request.url;
                if (uri != null && !["http", "https"].contains(uri.scheme)) {
                  return NavigationActionPolicy.CANCEL;
                }
                return NavigationActionPolicy.ALLOW;
              },
              onReceivedServerTrustAuthRequest: (controller, challenge) async {
                // Allow SSL errors for development (use cautiously in production)
                return ServerTrustAuthResponse(
                  action: ServerTrustAuthResponseAction.PROCEED,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
