import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Database {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<void> toggleLike(String postId, List<dynamic> likes) async {
    final docRef = FirebaseFirestore.instance.collection("feeds").doc(postId);

    if (likes.contains(FirebaseAuth.instance.currentUser!.uid)) {
      // Unlike: Remove user ID from the list
      await docRef.update({
        "favorite": FieldValue.arrayRemove([
          FirebaseAuth.instance.currentUser!.uid,
        ]),
      });
    } else {
      // Like: Add user ID to the list
      await docRef.update({
        "favorite": FieldValue.arrayUnion([
          FirebaseAuth.instance.currentUser!.uid,
        ]),
      });
    }
  }

  // Create or get chat document
  Future<String?> createChatDocument({
    required String currentUserId,
    required String currentUserName,
    required String? currentUserPhoto,
    required String friendId,
    required String friendName,
    required String? friendPhoto,
  }) async {
    try {
      // Validate inputs
      if (currentUserId.isEmpty ||
          friendId.isEmpty ||
          currentUserName.isEmpty ||
          friendName.isEmpty) {
        throw Exception('Invalid user data');
      }

      // Generate consistent chat ID
      List<String> participants = [currentUserId, friendId];
      participants.sort();
      final chatId = participants.join('_');

      // Check if users exist
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      final friendDoc =
          await _firestore.collection('users').doc(friendId).get();

      if (!currentUserDoc.exists || !friendDoc.exists) {
        throw Exception('User not found');
      }

      // Create or update chat document
      await _firestore.collection('chats').doc(chatId).set({
        'participants': participants,
        'participantNames': {
          currentUserId: currentUserName,
          friendId: friendName,
        },
        'participantPhotos': {
          currentUserId: currentUserPhoto ?? '',
          friendId: friendPhoto ?? '',
        },
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return chatId;
    } catch (e) {
      print('Error creating chat: $e');
      return null;
    }
  }

  // Send message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String message,
  }) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'senderId': senderId,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
        });

    // Update last message in chat document
    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendJoinRequest(String communityId) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance
          .collection('communities')
          .doc(communityId)
          .collection('joinRequests')
          .doc(userId)
          .set({
            'userId': userId,
            'status': 'pending',
            'requestedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print("Error sending request: $e");
    }
  }

  // Function to check if user has already sent a join request
  Future<bool> hasSentRequest(String communityId) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    var doc =
        await FirebaseFirestore.instance
            .collection('communities')
            .doc(communityId)
            .collection('joinRequests')
            .doc(userId)
            .get();

    return doc.exists;
  }
}
