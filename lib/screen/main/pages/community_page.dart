import 'package:axion/screen/communities/community_detail_page.dart';
import 'package:axion/utils/messagebar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CommunityPage extends StatefulWidget {
  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isJoined =
      false; // True if user has any join request (pending or approved)
  bool isApproved = false; // True only if request is approved
  bool loading = true;
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic>?
  userJoinRequest; // Stores the user's join request object

  Future<void> joinGroup(String communityId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      setState(() => loading = true);

      final newRequest = {'userId': currentUserId, 'status': 'pending'};

      await FirebaseFirestore.instance
          .collection('communities')
          .doc(communityId)
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

  Future<void> leaveGroup(String communityId, String userId) async {
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
            .doc(communityId)
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

  Future<List<Map<String, dynamic>>> getGroupMembers(String communityId) async {
    final doc =
        await _firestore.collection('communities').doc(communityId).get();
    List members = doc['members'] ?? [];
    List<Map<String, dynamic>> users = [];

    for (String uid in members) {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        users.add({
          'uid': uid,
          'name': userDoc['name'] ?? 'Unnamed',
          'email': userDoc['email'] ?? '',
          'image': userDoc['image'], // optional profile image
        });
      }
    }
    return users;
  }

  Future<bool> isUserJoined(String communityId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final doc =
        await _firestore.collection('communities').doc(communityId).get();
    List members = doc['members'] ?? [];
    return members.contains(uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Communities"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder(
        stream: _firestore.collection('communities').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No communities available"));
          }

          var communities = snapshot.data!.docs;

          return GridView.builder(
            padding: EdgeInsets.all(10),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.2,
            ),
            itemCount: communities.length,
            itemBuilder: (context, index) {
              var community = communities[index].data() as Map<String, dynamic>;
              String communityId = communities[index].id;

              return FutureBuilder<bool>(
                future: isUserJoined(communityId),
                builder: (context, joinSnapshot) {
                  bool isJoined = joinSnapshot.data ?? false;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return CommunityDetailPage(
                              communityId: communityId,
                              communityName:
                                  community['categoryName'] ?? "Community",
                            );
                          },
                        ),
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:
                              community['photoURL'] != null &&
                                      community['photoURL'].isNotEmpty
                                  ? Image.network(
                                    community['photoURL'],
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                  : Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: Colors.grey.shade300,
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          color: Colors.black.withOpacity(0.5),
                          child: Text(
                            community['categoryName'] ?? "Community",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (isJoined) {
                                await leaveGroup(
                                  communityId,
                                  FirebaseAuth.instance.currentUser!.uid,
                                );
                                showMessageBar("You Leave the Group", context);
                              } else {
                                await joinGroup(communityId);
                                showMessageBar("You Joined the Group", context);
                              }
                              setState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isJoined ? Colors.red : Colors.blue,
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                            child: Text(
                              isJoined ? "Leave Group" : "Join Group",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
