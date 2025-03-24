import 'package:axion/screen/main/chat/chat_detail_page.dart';
import 'package:axion/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Image.asset("assets/log.png", height: 100),
        backgroundColor: mainColor,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.search, color: colorWhite),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.add, color: colorWhite),
          ),
        ],
      ),
      body: ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (builder) => ChatDetailPage()),
              );
            },
            leading: CircleAvatar(
              backgroundImage: AssetImage("assets/logo.png"),
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("10:25", style: TextStyle(color: textColor, fontSize: 12)),
              ],
            ),
            title: Text(
              "David Wayne",
              style: GoogleFonts.roboto(
                color: titleColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              "Thanks a bunch! Have a great day! 😊",
              style: GoogleFonts.roboto(
                color: subTitleColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }
}
