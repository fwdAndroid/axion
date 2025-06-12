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
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Map<String, Map<String, dynamic>> _userRequestsStatus = {};

  Future<void> fetchUserRequests() async {
    final snapshot = await _firestore.collection('communities').get();

    Map<String, Map<String, dynamic>> statusMap = {};
    for (var doc in snapshot.docs) {
      final requests = doc['userRequests'] ?? [];
      for (var req in requests) {
        if (req['userId'] == currentUserId) {
          statusMap[doc.id] = Map<String, dynamic>.from(req);
        }
      }
    }

    setState(() {
      _userRequestsStatus = statusMap;
    });
  }

  Future<void> joinGroup(String communityId) async {
    final newRequest = {
      'userId': currentUserId,
      'status': 'approved',
    }; // Change to 'pending' if needed
    try {
      await _firestore.collection('communities').doc(communityId).update({
        'userRequests': FieldValue.arrayUnion([newRequest]),
      });

      setState(() {
        _userRequestsStatus[communityId] = newRequest;
      });

      showMessageBar("You have joined the group!", context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Join failed: $e")));
    }
  }

  Future<void> leaveGroup(String communityId) async {
    final doc =
        await _firestore.collection('communities').doc(communityId).get();
    List<dynamic> requests = doc['userRequests'] ?? [];

    Map<String, dynamic>? toRemove;
    for (var req in requests) {
      if (req['userId'] == currentUserId) {
        toRemove = req;
        break;
      }
    }

    if (toRemove != null) {
      try {
        await _firestore.collection('communities').doc(communityId).update({
          'userRequests': FieldValue.arrayRemove([toRemove]),
        });

        setState(() {
          _userRequestsStatus.remove(communityId);
        });

        showMessageBar("You left the group!", context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Leave failed: $e")));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Communities")),
      body: StreamBuilder(
        stream: _firestore.collection('communities').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No communities found."));
          }

          final communities = snapshot.data!.docs;

          return GridView.builder(
            padding: EdgeInsets.all(10),
            itemCount: communities.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final community = communities[index];
              final communityData = community.data() as Map<String, dynamic>;
              final communityId = community.id;

              final request = _userRequestsStatus[communityId];
              final status = request?['status'];

              String buttonLabel = "Join Group";
              Color buttonColor = Colors.blue;
              bool isButtonEnabled = true;

              if (status == 'approved') {
                buttonLabel = "Leave Group";
                buttonColor = Colors.red;
              } else if (status == 'pending') {
                buttonLabel = "Pending";
                buttonColor = Colors.grey;
                isButtonEnabled = false;
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => CommunityDetailPage(
                            communityId: communityId,
                            communityName:
                                communityData['categoryName'] ?? "Community",
                          ),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          communityData['photoURL'] != null
                              ? Image.network(
                                communityData['photoURL'],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                              : Container(
                                color: Colors.grey.shade300,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                ),
                              ),
                    ),
                    Container(
                      alignment: Alignment.bottomCenter,
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            communityData['categoryName'] ?? 'Community',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ElevatedButton(
                            onPressed:
                                !isButtonEnabled
                                    ? null
                                    : () async {
                                      if (status == 'approved') {
                                        await leaveGroup(communityId);
                                      } else {
                                        await joinGroup(communityId);
                                      }
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                            ),
                            child: Text(buttonLabel),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
