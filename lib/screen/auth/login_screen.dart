import 'dart:io';

import 'package:axion/screen/auth/forgot_password.dart';
import 'package:axion/screen/auth/signup_screen.dart';
import 'package:axion/screen/main/main_dashboard.dart';
import 'package:axion/services/auth_methods.dart';
import 'package:axion/services/shared_pref.dart';
import 'package:axion/utils/colors.dart';
import 'package:axion/utils/messagebar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:social_login_buttons/social_login_buttons.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  bool isGoogle = false;
  bool _isPasswordVisible = false;
  bool isLoading = false;
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await _showExitDialog(context);
        return shouldPop ?? false;
      },
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/logo.png', // Replace with your icon asset
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "UserName",
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
                      hintText: 'example@gmail.com',
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        checkColor: Colors.white,
                        value: isChecked,
                        onChanged: (bool? value) {
                          setState(() {
                            isChecked = value!;
                          });
                        },
                      ),
                      Text(
                        'Remember Me',
                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (builder) => const ForgotPassword(),
                        ),
                      );
                    },
                    child: Text(
                      "Forgot Password",
                      style: GoogleFonts.poppins(
                        color: Color(0xff94A3B8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.isEmpty ||
                    passController.text.isEmpty) {
                  showMessageBar("Email & Password is Required", context);
                } else {
                  setState(() {
                    isLoading = true;
                  });
                  String result = await AuthMethods().loginUpUser(
                    email: emailController.text.trim(),
                    pass: passController.text.trim(),
                  );
                  if (result == 'success') {
                    SharedPref().saveRememberMe();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (builder) => MainDashboard()),
                    );
                  } else {
                    showMessageBar(result, context);
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
              child: Text("Login", style: TextStyle(color: colorWhite)),
            ),
            SizedBox(height: 20),
            isGoogle
                ? Center(child: CircularProgressIndicator())
                : _buildGoogleSignInButton(),

            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (builder) => const SignupScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text.rich(
                  TextSpan(
                    text: 'Don’t have an account? ',
                    children: <InlineSpan>[
                      TextSpan(
                        text: 'Sign Up',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: mainColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Do you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  if (Platform.isAndroid) {
                    SystemNavigator.pop(); // For Android
                  } else if (Platform.isIOS) {
                    exit(0); // For iOS
                  }
                },
                child: const Text('Yes'),
              ),
            ],
          ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SocialLoginButton(
        height: 55,
        width: 327,
        buttonType: SocialLoginButtonType.google,
        borderRadius: 15,
        onPressed: () {
          _loginWithGoogle();
        },
      ),
    );
  }

  Future<void> _loginWithGoogle() async {
    AuthMethods().signInWithGoogle().then((value) async {
      setState(() {
        isGoogle = true;
      });

      User? user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection("users").doc(user?.uid).set({
        "email": user?.email,
        "fullName": user?.displayName,
        "phoneNumber": user?.phoneNumber ?? "Not Available",
        "password": "No Password Available",

        "confrimPassword": "No Password Available",

        "uid": user!.uid,
      });

      setState(() {
        isGoogle = false;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (builder) => MainDashboard()),
        );
      });
    });
  }
}
