import 'package:axion/screen/communities/add_communites.dart';
import 'package:axion/screen/communities/view_community_comment.dart';
import 'package:axion/services/database.dart';
import 'package:axion/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:readmore/readmore.dart';

class CommunityDetailPage extends StatefulWidget {
  final String communityName;
  final String communityId;

  CommunityDetailPage({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  bool isJoined =
      false; // True if user has any join request (pending or approved)
  bool isApproved = false; // True only if request is approved
  bool loading = true;
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic>?
  userJoinRequest; // Stores the user's join request object

  @override
  void initState() {
    super.initState();

    _checkJoinStatus();
  }

  // Fetch the user's join request from the community document
  Future<void> _checkJoinStatus() async {
    try {
      setState(() => loading = true);

      final communityDoc =
          await FirebaseFirestore.instance
              .collection('communities')
              .doc(widget.communityId)
              .get();

      if (communityDoc.exists) {
        final userRequests =
            communityDoc['userRequests'] as List<dynamic>? ?? [];

        // Find the user's join request in the array
        for (var request in userRequests) {
          if (request is Map<String, dynamic> &&
              request['userId'] == currentUserId) {
            userJoinRequest = request;
            setState(() {
              isJoined = true;
              isApproved = request['status'] == 'approved';
            });
            break;
          }
        }

        // If no request was found
        if (userJoinRequest == null) {
          setState(() {
            isJoined = false;
            isApproved = false;
          });
        }
      }
    } catch (e) {
      print('Error checking join status: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  // Create a join request
  Future<void> joinGroup() async {
    try {
      setState(() => loading = true);

      final newRequest = {'userId': currentUserId, 'status': 'pending'};

      await FirebaseFirestore.instance
          .collection('communities')
          .doc(widget.communityId)
          .update({
            'userRequests': FieldValue.arrayUnion([newRequest]),
          });

      // Update local state
      setState(() {
        isJoined = true;
        userJoinRequest = newRequest;
      });
    } catch (e) {
      print('Error joining group: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send join request')));
    } finally {
      setState(() => loading = false);
    }
  }

  // Remove join request
  Future<void> leaveGroup() async {
    bool confirm = await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Leave Group"),
            content: const Text("Are you sure you want to leave the group?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Leave", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm && userJoinRequest != null) {
      try {
        setState(() => loading = true);

        await FirebaseFirestore.instance
            .collection('communities')
            .doc(widget.communityId)
            .update({
              'userRequests': FieldValue.arrayRemove([userJoinRequest]),
            });

        // Reset local state
        setState(() {
          isJoined = false;
          isApproved = false;
          userJoinRequest = null;
        });
      } catch (e) {
        print('Error leaving group: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to leave community')));
      } finally {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Show FAB only when user is approved
      floatingActionButton:
          isApproved
              ? FloatingActionButton(
                backgroundColor: mainColor,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (builder) =>
                              AddCommunities(communityId: widget.communityId),
                    ),
                  );
                },
                child: Icon(Icons.add, color: colorWhite),
              )
              : null,
      appBar: AppBar(
        actions: [
          if (loading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: isJoined ? leaveGroup : joinGroup,
              child: Text(
                isJoined
                    ? (isApproved ? "Leave Group" : "Request Pending")
                    : "Join Group",
                style: TextStyle(
                  color: isJoined && !isApproved ? Colors.grey : mainColor,
                ),
              ),
            ),
        ],
        title: Text(
          widget.communityName,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ),
      body: _buildCommunityBody(),
    );
  }

  Widget _buildCommunityBody() {
    // Only approved members can see posts
    if (!isApproved) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_add, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              isJoined
                  ? "Your join request is pending approval"
                  : "Join this community to see posts",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (!isJoined)
              ElevatedButton(
                onPressed: joinGroup,
                child: const Text("Request to Join"),
              ),
          ],
        ),
      );
    }

    // Approved members see the posts
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('communitiesPost')
              .orderBy('date', descending: true)
              .where("commuityId", isEqualTo: widget.communityId)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.forum_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 20),
                const Text("No posts yet in this community"),
                const SizedBox(height: 20),
              ],
            ),
          );
        }

        // Existing post list builder
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            // Your existing post item builder
          },
        );
      },
    );
  }
}
