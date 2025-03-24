import 'package:flutter/material.dart';

showMessageBar(String contexts, BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(contexts), duration: Duration(seconds: 3)),
  );
}
