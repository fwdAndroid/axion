import 'package:axion/screen/main/comment/comment.dart';
import 'package:axion/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchResultScreen extends StatefulWidget {
  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  bool _isSearching = false;
  final Database _database = Database();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search posts...',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                )
                : Text(
                  "Search Result",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _searchQuery.isEmpty
                ? _firestore
                    .collection('feeds')
                    .orderBy('date', descending: true)
                    .limit(20)
                    .snapshots()
                : _firestore
                    .collection('feeds')
                    .where('titleName', isGreaterThanOrEqualTo: _searchQuery)
                    .where('titleName', isLessThan: _searchQuery + 'z')
                    .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.no_photography, size: 150),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No Search Result Available'
                        : 'No Search Result Found',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final post = snapshot.data!.docs[index];
              final postData = post.data() as Map<String, dynamic>;
              final date = postData['date']?.toDate() ?? DateTime.now();
              final timeAgo = _timeAgo(date);
              List<dynamic> likes = post['favorite'] ?? [];
              bool isLiked = likes.contains(
                FirebaseAuth.instance.currentUser!.uid,
              );
              int likeCount = likes.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (postData['image'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        postData['image'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
                        errorBuilder:
                            (_, __, ___) => Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: Icon(Icons.broken_image),
                            ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (postData['titleName'] != null)
                          Text(
                            postData['titleName'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        SizedBox(height: 8),
                        Text(postData['content'] ?? ''),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                _database.toggleLike(post['uuid'], likes);
                              },
                              icon: Icon(
                                isLiked
                                    ? Icons.thumb_up
                                    : Icons.thumbs_up_down_outlined,
                                color: isLiked ? Colors.green : Colors.grey,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text("${postData['favorite']?.length ?? 0} Likes"),
                            Text(
                              "$likeCount",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Spacer(),
                            Icon(Icons.chat_bubble_outline),
                            SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            ViewComment(postId: post['uuid']),
                                  ),
                                );
                              },
                              child: Text(
                                "${postData['comment']?.length ?? 0} Comments",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
