import 'package:axion/screen/main/chat/chat_detail_page.dart';
import 'package:axion/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Image.asset("assets/log.png", height: 100),
        backgroundColor: mainColor,
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(color: colorWhite),
                  decoration: InputDecoration(
                    hintText: 'Search chats...',
                    hintStyle: TextStyle(color: colorWhite.withOpacity(0.7)),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                )
                : null,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: colorWhite,
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('chats')
                .where('participants', arrayContains: currentUserId)
                .orderBy('lastMessageTime', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No chats yet",
                    style: GoogleFonts.roboto(color: Colors.grey, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          final chats = snapshot.data!.docs;

          // Filter chats based on search query
          final filteredChats =
              _searchQuery.isEmpty
                  ? chats
                  : chats.where((chatDoc) {
                    final chat = chatDoc.data() as Map<String, dynamic>;
                    final participants = chat['participants'] as List<dynamic>;
                    final participantNames =
                        chat['participantNames'] as Map<String, dynamic>;

                    // Get the other participant's info
                    final friendId =
                        participants.firstWhere(
                              (id) => id != currentUserId,
                              orElse: () => currentUserId,
                            )
                            as String;

                    final friendName = participantNames[friendId] ?? 'Unknown';
                    return friendName.toLowerCase().contains(_searchQuery);
                  }).toList();

          if (filteredChats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No matching chats found",
                    style: GoogleFonts.roboto(color: Colors.grey, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredChats.length,
            itemBuilder: (context, index) {
              final chat = filteredChats[index].data() as Map<String, dynamic>;
              final participants = chat['participants'] as List<dynamic>;
              final participantNames =
                  chat['participantNames'] as Map<String, dynamic>;
              final participantPhotos =
                  chat['participantPhotos'] as Map<String, dynamic>;
              final lastMessage = chat['lastMessage'] ?? 'No messages yet';
              final lastMessageSender = chat['lastMessageSenderId'];
              final isCurrentUserSender = lastMessageSender == currentUserId;

              // Get the other participant's info
              final friendId =
                  participants.firstWhere(
                        (id) => id != currentUserId,
                        orElse: () => currentUserId,
                      )
                      as String;

              final friendName = participantNames[friendId] ?? 'Unknown';
              final friendImage = participantPhotos[friendId];

              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ChatDetailPage(
                            currentUserId:
                                FirebaseAuth.instance.currentUser!.uid,
                            chatId: filteredChats[index].id,
                            friendId: friendId,
                            friendName: friendName,
                            friendImage: friendImage,
                          ),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundImage:
                      friendImage != null && friendImage.isNotEmpty
                          ? NetworkImage(friendImage)
                          : const AssetImage("assets/logo.png")
                              as ImageProvider,
                  radius: 25,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(chat['lastMessageTime']?.toDate()),
                      style: TextStyle(color: textColor, fontSize: 12),
                    ),
                    if (chat['unreadCount'] != null && chat['unreadCount'] > 0)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          chat['unreadCount'].toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  friendName,
                  style: GoogleFonts.roboto(
                    color: titleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Row(
                  children: [
                    if (isCurrentUserSender)
                      Text(
                        'You: ',
                        style: GoogleFonts.roboto(
                          color: subTitleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        lastMessage.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          color: subTitleColor,
                          fontWeight: FontWeight.normal,
                          fontSize: 12,
                        ),
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

  String _formatTime(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
