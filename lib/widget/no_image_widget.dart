import 'package:flutter/material.dart';

Widget noImageWidget() {
  return Container(
    width: double.infinity,
    height: 200,
    color: Colors.grey[300],
    child: const Center(
      child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
    ),
  );
}
