import 'dart:io';
import 'package:axion/widget/save_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditPost extends StatefulWidget {
  final String description;
  final String uuid;
  final String photo;
  final String title;

  EditPost({
    super.key,
    required this.description,
    required this.photo,
    required this.title,
    required this.uuid,
  });

  @override
  State<EditPost> createState() => _EditPostState();
}

class _EditPostState extends State<EditPost> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  File? _newImage;
  bool _isUpdating = false; // Tracks update state

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _descriptionController = TextEditingController(text: widget.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Function to pick an image
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _newImage = File(pickedFile.path);
      });
    }
  }

  // Function to upload image to Firebase Storage
  Future<String?> _uploadImage(File image) async {
    try {
      String fileName =
          "posts/${widget.uuid}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  // Function to update post details in Firestore
  Future<void> _updatePost() async {
    setState(() {
      _isUpdating = true; // Show loading
    });

    try {
      String? imageUrl =
          widget.photo.isNotEmpty
              ? widget.photo
              : null; // Keep old image if exists
      if (_newImage != null) {
        String? uploadedImageUrl = await _uploadImage(_newImage!);
        if (uploadedImageUrl != null) {
          imageUrl =
              uploadedImageUrl; // Use new image URL if uploaded successfully
        }
      }

      await FirebaseFirestore.instance
          .collection('feeds')
          .doc(widget.uuid)
          .update({
            'titleName': _titleController.text,
            'description': _descriptionController.text,
            'image':
                imageUrl ??
                "", // If no image is available, store an empty string
          });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Post updated successfully")));
      Navigator.pop(context); // Go back after updating
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error updating post: $e")));
    } finally {
      setState(() {
        _isUpdating = false; // Hide loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Post")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade300,
                backgroundImage:
                    _newImage != null
                        ? FileImage(_newImage!) as ImageProvider
                        : (widget.photo.isNotEmpty
                            ? NetworkImage(widget.photo)
                            : null),
                child:
                    _newImage == null && widget.photo.isEmpty
                        ? Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        )
                        : null,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            _isUpdating
                ? CircularProgressIndicator() // Show loading indicator
                : SaveButton(onTap: _updatePost, title: "Update"),
          ],
        ),
      ),
    );
  }
}
