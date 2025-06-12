import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LatestCommentWidget extends StatelessWidget {
  final String postId;

  const LatestCommentWidget({Key? key, required this.postId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('feeds')
              .doc(postId)
              .collection('comments')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .snapshots(),
      builder: (context, commentSnapshot) {
        if (commentSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink(); // Or a small loading indicator
        }
        if (commentSnapshot.hasData && commentSnapshot.data!.docs.isNotEmpty) {
          var latestComment =
              commentSnapshot.data!.docs.first.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(
                    latestComment['userImage'] ??
                        'https://via.placeholder.com/150',
                  ),
                  radius: 12,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        latestComment['userName'] ?? 'User',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        latestComment['text'] ?? '',
                        style: GoogleFonts.poppins(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink(); // No comments yet
      },
    );
  }
}
