import 'dart:typed_data';

import 'package:axion/services/auth_methods.dart';
import 'package:axion/utils/colors.dart';
import 'package:axion/utils/image.dart';
import 'package:axion/utils/messagebar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController reController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  Uint8List? _image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: () => selectImage(),
                child: Stack(
                  children: [
                    _image != null
                        ? CircleAvatar(
                          radius: 59,
                          backgroundImage: MemoryImage(_image!),
                        )
                        : CircleAvatar(
                          radius: 59,
                          backgroundImage: AssetImage(
                            'assets/profilephoto.png',
                          ),
                        ),
                    Positioned(
                      bottom: -10,
                      left: 70,
                      child: IconButton(
                        onPressed: () => selectImage(),
                        icon: Icon(Icons.add_a_photo, color: black),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "User Name",
                      style: GoogleFonts.poppins(
                        color: labelColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    TextFormField(
                      controller: userNameController,
                      decoration: InputDecoration(
                        hintText: 'Fawad Kaleem',
                        hintStyle: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        contentPadding: const EdgeInsets.only(left: 8, top: 15),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(4),
                          ),
                          borderSide: BorderSide(color: mainColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: mainColor),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: mainColor),
                        ),
                        fillColor: textColor,
                        prefixIcon: IconButton(
                          icon: const Icon(
                            Icons.person,
                            color: Color(0xff64748B),
                          ),
                          onPressed: () {},
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your username';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Email",
                      style: GoogleFonts.poppins(
                        color: labelColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: 'fwdkaleem@gmail.com',
                        hintStyle: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        contentPadding: const EdgeInsets.only(left: 8, top: 15),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(4),
                          ),
                          borderSide: BorderSide(color: mainColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: mainColor),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: mainColor),
                        ),
                        fillColor: textColor,
                        prefixIcon: IconButton(
                          icon: const Icon(
                            Icons.email,
                            color: Color(0xff64748B),
                          ),
                          onPressed: () {},
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Password",
                      style: GoogleFonts.poppins(
                        color: labelColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    TextFormField(
                      controller: passController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        hintStyle: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        contentPadding: const EdgeInsets.only(left: 8, top: 15),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(4),
                          ),
                          borderSide: BorderSide(color: mainColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: mainColor),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: mainColor),
                        ),
                        fillColor: textColor,
                        prefixIcon: Icon(Icons.lock, color: Color(0xff64748B)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Color(0xff64748B),
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Re-Enter Password",
                      style: GoogleFonts.poppins(
                        color: labelColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    TextFormField(
                      controller: reController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        hintStyle: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        contentPadding: const EdgeInsets.only(left: 8, top: 15),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(4),
                          ),
                          borderSide: BorderSide(color: mainColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: mainColor),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: mainColor),
                        ),
                        fillColor: textColor,
                        prefixIcon: Icon(Icons.lock, color: Color(0xff64748B)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Color(0xff64748B),
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Phone Number",
                      style: GoogleFonts.poppins(
                        color: labelColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    TextFormField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        hintText: 'Enter Phone Number',
                        hintStyle: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        contentPadding: const EdgeInsets.only(left: 8, top: 15),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(4),
                          ),
                          borderSide: BorderSide(color: mainColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: mainColor),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: mainColor),
                        ),
                        fillColor: textColor,
                        prefixIcon: Icon(Icons.phone, color: Color(0xff64748B)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed: () async {
                      if (_image == null) {
                        showMessageBar("Profile Image is Required", context);
                        return;
                      }
                      Uint8List imageToUpload = _image!;
                      if (userNameController.text.isEmpty) {
                        showMessageBar("User Name is Required", context);
                      } else if (emailController.text.isEmpty) {
                        showMessageBar("Email is Required", context);
                      } else if (passController.text.isEmpty) {
                        showMessageBar("Password is Required", context);
                      } else if (reController.text.isEmpty) {
                        showMessageBar("Confirm Password is Required", context);
                      } else {
                        setState(() {
                          isLoading = true;
                        });

                        if (_formKey.currentState?.validate() ?? false) {
                          await AuthMethods().signUpUser(
                            context: context,
                            confirmPassword: reController.text.trim(),
                            fullName: userNameController.text.trim(),

                            email: emailController.text.trim(),

                            password: passController.text.trim(),

                            phoneNumber: phoneController.text.trim(),
                            file: imageToUpload,
                          );
                        }
                        setState(() {
                          isLoading = false;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // <-- Radius
                      ),
                      backgroundColor: mainColor,
                      fixedSize: const Size(320, 60),
                    ),
                    child: Text(
                      "Register",
                      style: TextStyle(color: colorWhite),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  selectImage() async {
    Uint8List ui = await pickImage(ImageSource.gallery);
    setState(() {
      _image = ui;
    });
  }
}
