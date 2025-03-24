import 'package:axion/screen/main/tab/my_communities.dart';
import 'package:axion/screen/main/tab/my_feed.dart';
import 'package:axion/utils/colors.dart';
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
        floatingActionButton: FloatingActionButton(
          backgroundColor: mainColor,
          onPressed: () {},
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
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundImage: AssetImage("assets/Ellipse 5.png"),
                        ),
                        Text("Programming"),
                      ],
                    ),
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
