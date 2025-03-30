import 'dart:typed_data';
import 'package:axion/screen/main/main_dashboard.dart';
import 'package:axion/utils/colors.dart';
import 'package:axion/utils/image.dart';
import 'package:axion/utils/messagebar.dart';
import 'package:axion/widget/save_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  TextEditingController phoneController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  bool _isLoading = false;
  Uint8List? _image;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    DocumentSnapshot doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();

    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    setState(() {
      phoneController.text = (data['phoneNumber'] ?? '');
      nameController.text = data['fullName'] ?? '';
      imageUrl = data['image'];
    });
  }

  Future<void> selectImage() async {
    Uint8List ui = await pickImage(ImageSource.gallery);
    setState(() {
      _image = ui;
    });
  }

  Future<String> uploadImageToStorage(Uint8List image) async {
    Reference ref = FirebaseStorage.instance
        .ref()
        .child('users')
        .child('${FirebaseAuth.instance.currentUser!.uid}.jpg');
    UploadTask uploadTask = ref.putData(image);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(centerTitle: true, title: Text("Editar perfil")),
        body: Column(
          children: [
            // Profile Image Section
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => selectImage(),
                child:
                    _image != null
                        ? CircleAvatar(
                          radius: 59,
                          backgroundImage: MemoryImage(_image!),
                        )
                        : imageUrl != null
                        ? CircleAvatar(
                          radius: 59,
                          backgroundImage: NetworkImage(imageUrl!),
                        )
                        : Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset("assets/logo.png"),
                        ),
              ),
            ),

            // Full Name Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: TextFormField(
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(8),
                  fillColor: textColor,
                  filled: true,
                  hintStyle: GoogleFonts.nunitoSans(fontSize: 16),
                  hintText: "Full Name",
                ),
                controller: nameController,
              ),
            ),

            // Phone Number Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(8),
                  fillColor: textColor,
                  filled: true,
                  hintStyle: GoogleFonts.nunitoSans(fontSize: 16),
                  hintText: "Phone Number",
                ),
                controller: phoneController,
              ),
            ),

            Spacer(),

            // Save Button
            Padding(
              padding: const EdgeInsets.all(8.0),
              child:
                  _isLoading
                      ? Center(
                        child: CircularProgressIndicator(color: mainColor),
                      )
                      : SaveButton(
                        title: "Guardar Perfil",
                        onTap: () async {
                          setState(() {
                            _isLoading = true;
                          });

                          String? downloadUrl;
                          if (_image != null) {
                            downloadUrl = await uploadImageToStorage(_image!);
                          } else {
                            downloadUrl = imageUrl;
                          }

                          try {
                            await FirebaseFirestore.instance
                                .collection("users")
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .update({
                                  "fullName": nameController.text,
                                  "phoneNumber": phoneController.text,
                                  "image": downloadUrl,
                                });
                            showMessageBar(
                              "Successfully Updated Profile",
                              context,
                            );
                          } catch (e) {
                            print("Error updating profile: $e");
                            showMessageBar(
                              "Profile could not be updated",
                              context,
                            );
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (builder) => MainDashboard(),
                              ),
                            );
                          }
                        },
                      ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
