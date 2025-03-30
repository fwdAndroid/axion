import 'package:axion/widget/no_image_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';
import 'package:uuid/uuid.dart';

class ViewPost extends StatefulWidget {
  final String? description, image, titleName, uuid; // Make nullable
  final dateTime;

  ViewPost({
    super.key,
    required this.description,
    required this.image,
    required this.titleName,
    required this.uuid,
    required this.dateTime,
  });

  @override
  State<ViewPost> createState() => _ViewPostState();
}

class _ViewPostState extends State<ViewPost> {
  TextEditingController customerPassController = TextEditingController();
  var chatId = Uuid().v4();

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
          if (widget.image != null && widget.image!.isNotEmpty)
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

  return DateFormat('dd MMM yyyy, hh:mm a').format(parsedDate);
}
