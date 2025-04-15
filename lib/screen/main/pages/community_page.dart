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

  Future<void> joinGroup(String communityId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('communities').doc(communityId).update({
      'members': FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> leaveGroup(String communityId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('communities').doc(communityId).update({
      'members': FieldValue.arrayRemove([uid]),
    });
  }

  Future<void> removeUserFromGroup(String communityId, String userId) async {
    await _firestore.collection('communities').doc(communityId).update({
      'members': FieldValue.arrayRemove([userId]),
    });
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

                  return Stack(
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
                              await leaveGroup(communityId);
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
