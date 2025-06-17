import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

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

  Future<void> toggleLikeCommunity(
    String postId,
    List<dynamic> currentLikes,
  ) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final postRef = FirebaseFirestore.instance
        .collection('communitiesPost')
        .doc(postId);

    if (currentLikes.contains(uid)) {
      await postRef.update({
        'favorite': FieldValue.arrayRemove([uid]),
      });
    } else {
      await postRef.update({
        'favorite': FieldValue.arrayUnion([uid]),
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

  // Check if the user is already part of the group
  Future<bool> isUserJoined(String communityId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final doc =
        await _firestore.collection('communities').doc(communityId).get();
    List members = doc['members'] ?? [];

    return members.contains(uid);
  }

  // Join a group by adding the user to the members list
  Future<void> joinGroup(String communityId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('communities').doc(communityId).update({
      'members': FieldValue.arrayUnion([uid]),
    });
  }

  // Leave a group by removing the user from the members list
  Future<void> leaveGroup(String communityId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('communities').doc(communityId).update({
      'members': FieldValue.arrayRemove([uid]),
    });
  }

  //Post Commemnt
  Future<void> postComment({
    required String postId,
    required String commentText,
    required String uid,
    required String userName,
    required String userImage,
  }) async {
    if (commentText.trim().isEmpty) return;

    try {
      await _firestore
          .collection('feeds')
          .doc(postId)
          .collection('comments')
          .add({
            'text': commentText.trim(),
            'timestamp': Timestamp.now(),
            'uid': uid,
            'userName': userName,
            'userImage': userImage,
          });
    } catch (e) {
      rethrow; // Let the UI layer handle the error
    }
  }

  //Commnity Comment Logic
  Future<void> addCommentCommnutiye(
    String postid,
    BuildContext context,
    TextEditingController controller,
  ) async {
    final String commentText = controller.text.trim();
    if (commentText.isEmpty) return;

    final String commentId = const Uuid().v4();
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final String username =
        FirebaseAuth.instance.currentUser!.displayName ?? 'Anonymous';
    final DateTime now = DateTime.now();

    try {
      final docRef = FirebaseFirestore.instance
          .collection('communitiesPost')
          .doc(postid);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post not found')));
        return;
      }

      if (!docSnapshot.data()!.containsKey('comment')) {
        await docRef.set({'comment': []}, SetOptions(merge: true));
      }

      await docRef.update({
        'comment': FieldValue.arrayUnion([
          {
            'id': commentId,
            'userId': userId,
            'username': username,
            'text': commentText,
            'createdAt': now,
            'likes': [],
            'replies': [],
            'isReply': false,
          },
        ]),
      });

      controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add comment: $e')));
    }
  }

  //Like Commnuoty Commnet
  void toggleCommentLike(String postId, String commentId, bool isLiked) async {
    final docRef = FirebaseFirestore.instance
        .collection('communitiesPost')
        .doc(postId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) return;
    final List<dynamic> comments = snapshot.data()!['comment'] ?? [];

    for (var comment in comments) {
      if (comment['id'] == commentId) {
        final likes = List<String>.from(comment['likes'] ?? []);
        if (isLiked) {
          likes.remove(FirebaseAuth.instance.currentUser!.uid);
        } else {
          likes.add(FirebaseAuth.instance.currentUser!.uid);
        }
        comment['likes'] = likes;
        break;
      }
    }
    await docRef.update({'comment': comments});
  }

  //Feeds Comment
  Future<void> addFeedCommnutiye(
    String postid,
    BuildContext context,
    TextEditingController controller,
  ) async {
    final String commentText = controller.text.trim();
    if (commentText.isEmpty) return;

    final String commentId = const Uuid().v4();
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final String username =
        FirebaseAuth.instance.currentUser!.displayName ?? 'Anonymous';
    final DateTime now = DateTime.now();

    try {
      final docRef = FirebaseFirestore.instance.collection('feeds').doc(postid);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post not found')));
        return;
      }

      if (!docSnapshot.data()!.containsKey('comment')) {
        await docRef.set({'comment': []}, SetOptions(merge: true));
      }

      await docRef.update({
        'comment': FieldValue.arrayUnion([
          {
            'id': commentId,
            'userId': userId,
            'username': username,
            'text': commentText,
            'createdAt': now,
            'likes': [],
            'replies': [],
            'isReply': false,
          },
        ]),
      });

      controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add comment: $e')));
    }
  }

  void deleteFeedComment(String postId, String commentId) async {
    final docRef = FirebaseFirestore.instance.collection('feeds').doc(postId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) return;
    List<dynamic> comments = snapshot.data()!['comment'] ?? [];
    comments.removeWhere((comment) => comment['id'] == commentId);
    await docRef.update({'comment': comments});
  }

  void toggleFeedLike(String postId, String commentId, bool isLiked) async {
    final docRef = FirebaseFirestore.instance.collection('feeds').doc(postId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) return;
    final List<dynamic> comments = snapshot.data()!['comment'] ?? [];

    for (var comment in comments) {
      if (comment['id'] == commentId) {
        final likes = List<String>.from(comment['likes'] ?? []);
        if (isLiked) {
          likes.remove(FirebaseAuth.instance.currentUser!.uid);
        } else {
          likes.add(FirebaseAuth.instance.currentUser!.uid);
        }
        comment['likes'] = likes;
        break;
      }
    }
    await docRef.update({'comment': comments});
  }
}
