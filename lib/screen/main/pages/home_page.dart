import 'package:axion/screen/main/tab/my_communities.dart';
import 'package:axion/screen/main/tab/my_feed.dart';
import 'package:axion/screen/post/add_post.dart';
import 'package:axion/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        floatingActionButtonLocation:
            FloatingActionButtonLocation.miniCenterDocked,
        floatingActionButton: FloatingActionButton(
          backgroundColor: mainColor,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (builder) => AddPost()),
            );
          },
          child: Icon(Icons.add, color: colorWhite),
        ),
        appBar: AppBar(
          title: Image.asset("assets/Frame 626756.png", width: 100),
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 80,
              child: StreamBuilder(
                stream:
                    FirebaseFirestore.instance
                        .collection("communities")
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.commute, size: 40),
                          Text("No Communitiy available"),
                        ],
                      ),
                    );
                  }
                  var posts = snapshot.data!.docs;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      var post = posts[index].data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(post['photoURL']),
                            ),
                            Text(post['categoryName']),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const TabBar(
              tabs: [Tab(text: "My feed"), Tab(text: "My communities")],
            ),
            Expanded(child: TabBarView(children: [MyFeed(), MyCommunities()])),
          ],
        ),
      ),
    );
  }
}
