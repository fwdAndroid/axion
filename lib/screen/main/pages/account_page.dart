import 'package:axion/screen/main/setting_page.dart';
import 'package:axion/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:readmore/readmore.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: Icon(Icons.settings),
              color: mainColor,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (builder) => SettingPage()),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          StreamBuilder(
            stream:
                FirebaseFirestore.instance
                    .collection("users")
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return Center(child: Text('No data available'));
              }
              var snap = snapshot.data;

              return Column(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child:
                          snap['image'] != null && snap['image'].isNotEmpty
                              ? CircleAvatar(
                                backgroundImage: NetworkImage(snap['image']),
                                radius: 60,
                              )
                              : CircleAvatar(
                                radius: 60,
                                child: Icon(Icons.person, size: 60),
                              ),
                    ),
                  ),
                  Text(
                    snap['fullName'],
                    style: GoogleFonts.workSans(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height / 1.7,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('feeds')
                          .where(
                            "uid",
                            isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                          )
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No posts available"));
                    }

                    var posts = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        var post = posts[index].data() as Map<String, dynamic>;

                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                post['image'] != null &&
                                        post['image'].toString().isNotEmpty
                                    ? Card(
                                      child: Image.network(
                                        post['image'],
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Center(
                                            child: const Icon(
                                              Icons.image_not_supported,
                                              size: 200,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                    : Center(
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 100,
                                        color: Colors.grey,
                                      ),
                                    ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Text(
                                        "Title: ",
                                        style: GoogleFonts.poppins(
                                          color: black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        post['titleName'] ?? "Untitled",
                                        style: GoogleFonts.poppins(
                                          color: black,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ReadMoreText(
                                    post['description'] ??
                                        "No description available",
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
                                  ),
                                ),

                                Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {},
                                      child: Text(
                                        "Edit Post",
                                        style: TextStyle(color: black),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {},
                                      child: Text(
                                        "Delete",
                                        style: TextStyle(color: red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
