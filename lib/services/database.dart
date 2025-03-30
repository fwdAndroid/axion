import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Database {
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
}
