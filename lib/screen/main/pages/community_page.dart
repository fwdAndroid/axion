import 'package:axion/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CommunityPage extends StatefulWidget {
  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  // Function to check if user has already sent a join request
  Future<bool> hasSentRequest(String communityId) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    var doc =
        await FirebaseFirestore.instance
            .collection('community')
            .doc(communityId)
            .collection('joinRequests')
            .doc(userId)
            .get();

    return doc.exists;
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
        stream:
            FirebaseFirestore.instance.collection('communities').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No communities available"));
          }

          var communities = snapshot.data!.docs;

          return SizedBox(
            height: MediaQuery.of(context).size.height,
            child: GridView.builder(
              padding: EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two items per row
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.2,
              ),

              itemCount: communities.length,
              itemBuilder: (context, index) {
                var community =
                    communities[index].data() as Map<String, dynamic>;
                String communityId = communities[index].id;

                return FutureBuilder<bool>(
                  future: hasSentRequest(communityId),
                  builder: (context, requestSnapshot) {
                    bool hasRequested = requestSnapshot.data ?? false;

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
                            onPressed:
                                hasRequested
                                    ? null
                                    : () async {
                                      await Database().sendJoinRequest(
                                        communityId,
                                      );
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  hasRequested ? Colors.grey : Colors.blue,
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                            child: Text(
                              hasRequested ? "Request Sent" : "Join Group",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
