import 'dart:typed_data';
import 'package:axion/screen/main/pages/home_page.dart';
import 'package:axion/utils/colors.dart';
import 'package:axion/utils/image.dart';
import 'package:axion/utils/messagebar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class AddPost extends StatefulWidget {
  const AddPost({super.key});

  @override
  State<AddPost> createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  TextEditingController serviceNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  Uint8List? _image;
  bool isLoading = false;
  var uuid = Uuid().v4();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text("Add Feed")),
      body: Column(
        children: [
          GestureDetector(
            onTap: () => selectImage(),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 59,
                  backgroundImage:
                      _image != null
                          ? MemoryImage(_image!)
                          : const AssetImage('assets/logo.png')
                              as ImageProvider,
                ),
                Positioned(
                  bottom: -10,
                  left: 70,
                  child: IconButton(
                    onPressed: () => selectImage(),
                    icon: const Icon(Icons.add_a_photo, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
            child: TextFormField(
              controller: serviceNameController,
              decoration: InputDecoration(
                hintText: 'Enter Post Title',
                hintStyle: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                contentPadding: const EdgeInsets.only(left: 8, top: 15),
                enabledBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  borderSide: BorderSide(color: mainColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: mainColor),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: mainColor),
                ),
                fillColor: textColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter Post Description',
                hintStyle: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                contentPadding: const EdgeInsets.only(left: 8, top: 15),
                enabledBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  borderSide: BorderSide(color: mainColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: mainColor),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: mainColor),
                ),
                fillColor: textColor,
              ),
            ),
          ),
          const Spacer(),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      isLoading = true;
                    });

                    String? imageUrl;
                    if (_image != null) {
                      imageUrl = await uploadImageToFirebase(_image!);
                    }

                    await FirebaseFirestore.instance
                        .collection('feeds')
                        .doc(uuid)
                        .set({
                          'titleName': serviceNameController.text,
                          'description': descriptionController.text,
                          'image': imageUrl, // Save only if available
                          'date': DateTime.now(),
                          'uuid': uuid,
                          'uid': FirebaseAuth.instance.currentUser!.uid,
                          'favorite': [],
                        });

                    setState(() {
                      isLoading = false;
                    });

                    showMessageBar("Feed Posted", context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (builder) => HomePage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: mainColor,
                    fixedSize: const Size(320, 60),
                  ),
                  child: const Text(
                    "Add Feed",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> selectImage() async {
    Uint8List ui = await pickImage(ImageSource.gallery);
    setState(() {
      _image = ui;
    });
  }

  Future<String> uploadImageToFirebase(Uint8List file) async {
    Reference ref = FirebaseStorage.instance.ref().child(
      'feed_images/${Uuid().v4()}',
    );
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snap = await uploadTask;
    return await snap.ref.getDownloadURL();
  }
}
