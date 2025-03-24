import 'package:flutter/material.dart';

class SearchResultScreen extends StatefulWidget {
  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Search Result",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(10),
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: AssetImage("assets/profile.jpg"),
                ),
                title: Text(
                  "Samera",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("@Samera123 • 1 min ago"),
                trailing: Icon(Icons.more_horiz),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  "assets/unsplash_mBQIfKlvowM.png",
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.red),
                    SizedBox(width: 8),
                    Text("1,964 Like"),
                    Spacer(),
                    Icon(Icons.chat_bubble_outline),
                    SizedBox(width: 8),
                    Text("Chat"),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
