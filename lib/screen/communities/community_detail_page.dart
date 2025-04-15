import 'package:axion/screen/communities/add_communites.dart';
import 'package:axion/services/database.dart';
import 'package:axion/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommunityDetailPage extends StatefulWidget {
  String communityName;
  String communityId;
  CommunityDetailPage({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  bool isJoined = false;
  bool loading = true;
  final Database _database =
      Database(); // Create an instance of the Database class
  @override
  void initState() {
    super.initState();
    checkUserJoined();
  }

  // Check if the user is part of the group
  Future<void> checkUserJoined() async {
    bool joined = await _database.isUserJoined(widget.communityId);
    setState(() {
      isJoined = joined;
      loading = false;
    });
  }

  // Join the group
  Future<void> joinGroup() async {
    await _database.joinGroup(widget.communityId);
    setState(() {
      isJoined = true;
    });
  }

  // Leave the group with confirmation
  Future<void> leaveGroup() async {
    bool confirm = await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Leave Group"),
            content: Text("Are you sure you want to leave the group?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Leave", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm) {
      await _database.leaveGroup(widget.communityId);
      setState(() {
        isJoined = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: mainColor,
        onPressed: () {
          // Navigate to chat screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (builder) => AddCommunities(communityId: widget.communityId),
            ),
          );
        },
        child: Icon(Icons.add, color: colorWhite),
      ),
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: isJoined ? leaveGroup : joinGroup,
            child: Text(isJoined ? "Leave Group" : "Join Group"),
          ),
        ],
        title: Text(
          widget.communityName,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ),
    );
  }
}
